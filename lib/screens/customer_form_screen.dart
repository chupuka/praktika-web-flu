import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../repositories/repositories.dart';
import '../validation/validators.dart';
import '../widgets/entity_form.dart';
import 'entity_form_screen.dart';

class CustomerFormScreen extends EntityFormScreen<Customer> {
  const CustomerFormScreen({super.key, super.id});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState
    extends EntityFormScreenState<Customer, CustomerFormScreen> {
  @override
  String get entityTitle => 'покупатель';

  @override
  String get returnLocation => '/customers';

  @override
  Future<void> loadData() async {
    controllerFor('fullName');
    controllerFor('email');
    controllerFor('phone');
    controllerFor('address');
    groupFor('card', {
      'number': '',
      'issuedAt': '',
      'points': '0',
    });
  }

  @override
  Future<Customer?> fetchEntity(int id) async {
    final repo = context.read<CustomerRepository>();
    final item = await repo.findById(id);
    if (item == null) return null;
    await loadData();
    return item;
  }

  @override
  void fillFrom(Customer entity) {
    controllerFor('fullName', entity.fullName);
    controllerFor('email', entity.email);
    controllerFor('phone', entity.phone);
    controllerFor('address', entity.address);
    final card = entity.card;
    groupFor('card', {
      'number': card?.number ?? '',
      'issuedAt': card?.issuedAt ?? '',
      'points': '${card?.points ?? 0}',
    });
    dropdownValues['tier'] = _tierValue(card?.tier);
  }

  int? _tierValue(String? tier) {
    return switch (tier) {
      'basic' => 1,
      'silver' => 2,
      'gold' => 3,
      _ => null,
    };
  }

  String _tierName(int? value) {
    return switch (value) {
      1 => 'basic',
      2 => 'silver',
      3 => 'gold',
      _ => 'basic',
    };
  }

  @override
  List<FieldSpec> buildFields() {
    return [
      FieldSpec(
        key: 'fullName',
        label: 'ФИО',
        maxLength: 120,
        validate: (v) => Validators.minLength(v, 'ФИО', 5),
      ),
      FieldSpec(
        key: 'email',
        label: 'Почта',
        hint: 'client@example.com',
        maxLength: 60,
        validate: Validators.email,
      ),
      FieldSpec(
        key: 'phone',
        label: 'Телефон',
        required: false,
        hint: '+7 900 000-00-00',
        maxLength: 20,
        validate: Validators.phone,
      ),
      FieldSpec(
        key: 'address',
        label: 'Адрес доставки',
        required: false,
        maxLength: 200,
        validate: (v) => Validators.maxLength(v, 'адрес', 200),
      ),
      FieldSpec(
        key: 'card',
        label: 'Клубная карта',
        kind: FieldKind.group,
        required: false,
      ),
      FieldSpec(
        key: 'tier',
        label: 'Уровень карты',
        kind: FieldKind.dropdown,
        required: false,
        options: const [
          DropdownOption(value: 1, label: 'basic'),
          DropdownOption(value: 2, label: 'silver'),
          DropdownOption(value: 3, label: 'gold'),
        ],
      ),
    ];
  }

  @override
  Future<bool> saveEntity() async {
    final repo = context.read<CustomerRepository>();
    final email = controllers['email']!.text.trim();

    final cardControllers = groupControllers['card'] ?? const {};
    final number = cardControllers['number']?.text.trim() ?? '';
    final hasCard = number.isNotEmpty;

    final item = Customer(
      id: widget.id ?? 0,
      fullName: controllers['fullName']!.text.trim(),
      email: email,
      phone: controllers['phone']!.text.trim(),
      address: controllers['address']!.text.trim(),
      card: hasCard
          ? CustomerCard(
              number: number,
              issuedAt: cardControllers['issuedAt']?.text.trim() ?? '',
              tier: _tierName(dropdownValues['tier']),
              points:
                  int.tryParse(cardControllers['points']?.text.trim() ?? '') ??
                      0,
            )
          : null,
    );

    if (widget.isEditing) {
      await repo.update(item);
    } else {
      await repo.create(item);
    }
    return true;
  }
}
