import 'package:flutter/material.dart';

import '../validation/validators.dart';

enum FieldKind { text, number, integer, dropdown, multiSelect, date, group }

class FieldSpec {
  final String key;
  final String label;
  final FieldKind kind;
  final bool required;
  final String? hint;
  final int? maxLength;
  final String? Function(String? value)? validate;
  final List<DropdownOption> options;
  final bool enabled;

  const FieldSpec({
    required this.key,
    required this.label,
    this.kind = FieldKind.text,
    this.required = true,
    this.hint,
    this.maxLength,
    this.validate,
    this.options = const [],
    this.enabled = true,
  });

  FieldSpec copyWith({
    List<DropdownOption>? options,
    bool? enabled,
  }) {
    return FieldSpec(
      key: key,
      label: label,
      kind: kind,
      required: required,
      hint: hint,
      maxLength: maxLength,
      validate: validate,
      options: options ?? this.options,
      enabled: enabled ?? this.enabled,
    );
  }
}

class DropdownOption {
  final int value;
  final String label;
  final int? parentId;

  const DropdownOption({
    required this.value,
    required this.label,
    this.parentId,
  });
}

class EntityForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<FieldSpec> fields;
  final Map<String, TextEditingController> controllers;
  final Map<String, int?> dropdownValues;
  final Map<String, List<int>> multiValues;
  final Map<String, Map<String, TextEditingController>> groupControllers;
  final Map<String, String> fieldErrors;
  final void Function(String key, int? value) onDropdownChanged;
  final void Function(String key, List<int> value) onMultiChanged;
  final VoidCallback? onDirty;
  final double maxWidth;

  const EntityForm({
    super.key,
    required this.formKey,
    required this.fields,
    required this.controllers,
    required this.dropdownValues,
    required this.multiValues,
    required this.groupControllers,
    required this.onDropdownChanged,
    required this.onMultiChanged,
    this.fieldErrors = const {},
    this.onDirty,
    this.maxWidth = 720,
  });

  @override
  State<EntityForm> createState() => _EntityFormState();
}

class _EntityFormState extends State<EntityForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      onChanged: widget.onDirty,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final field in widget.fields) ...[
                  _buildField(field),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(FieldSpec field) {
    switch (field.kind) {
      case FieldKind.dropdown:
        return DropdownButtonFormField<int>(
          value: widget.dropdownValues[field.key],
          isExpanded: true,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            hintText: field.hint,
          ),
          items: [
            for (final option in field.options)
              DropdownMenuItem<int>(
                value: option.value,
                child: Text(option.label, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: field.enabled
              ? (value) {
                  widget.onDropdownChanged(field.key, value);
                  widget.onDirty?.call();
                }
              : null,
          validator: (value) => _withServerError(
            field.key,
            () {
              if (field.required && value == null) {
                return 'Выберите ${field.label.toLowerCase()}';
              }
              return null;
            },
          ),
        );
      case FieldKind.multiSelect:
        return FormField<List<int>>(
          initialValue: widget.multiValues[field.key] ?? const [],
          validator: (value) => _withServerError(
            field.key,
            () {
              if (field.required && (value == null || value.isEmpty)) {
                return 'Выберите ${field.label.toLowerCase()}';
              }
              return null;
            },
          ),
          builder: (state) {
            final selected =
                widget.multiValues[field.key] ?? state.value ?? const <int>[];
            return InputDecorator(
              decoration: InputDecoration(
                labelText: field.label,
                border: const OutlineInputBorder(),
                errorText: state.errorText,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in field.options)
                    FilterChip(
                      label: Text(option.label),
                      selected: selected.contains(option.value),
                      onSelected: (_) {
                        final next = [...selected];
                        if (next.contains(option.value)) {
                          next.remove(option.value);
                        } else {
                          next.add(option.value);
                        }
                        widget.onMultiChanged(field.key, next);
                        state.didChange(next);
                        widget.onDirty?.call();
                      },
                    ),
                ],
              ),
            );
          },
        );
      case FieldKind.group:
        return _buildGroup(field);
      case FieldKind.number:
      case FieldKind.integer:
        return TextFormField(
          controller: widget.controllers[field.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            hintText: field.hint,
          ),
          validator: (value) =>
              _withServerError(field.key, () => field.validate?.call(value)),
        );
      case FieldKind.date:
        return TextFormField(
          controller: widget.controllers[field.key],
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            hintText: field.hint ?? 'ГГГГ-ММ-ДД',
          ),
          validator: (value) => _withServerError(
            field.key,
            () => field.validate != null
                ? field.validate!(value)
                : Validators.isoDate(value, field.label),
          ),
        );
      case FieldKind.text:
        return TextFormField(
          controller: widget.controllers[field.key],
          maxLength: field.maxLength,
          decoration: InputDecoration(
            labelText: field.label,
            border: const OutlineInputBorder(),
            hintText: field.hint,
            counterText: field.maxLength == null ? null : '',
          ),
          validator: (value) =>
              _withServerError(field.key, () => field.validate?.call(value)),
        );
    }
  }

  String? _withServerError(String key, String? Function() local) {
    final server = widget.fieldErrors[key];
    if (server != null) return server;
    return local();
  }

  Widget _buildGroup(FieldSpec field) {
    final controllers = widget.groupControllers[field.key] ?? const {};
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(field.label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          for (final entry in controllers.entries) ...[
            TextFormField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: _groupLabel(entry.key),
                border: const OutlineInputBorder(),
              ),
              validator: (v) => _validateGroup(field.key, entry.key, v),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  String _groupLabel(String key) {
    return switch (key) {
      'number' => 'Номер карты',
      'issuedAt' => 'Дата выдачи',
      'points' => 'Бонусные баллы',
      _ => key,
    };
  }

  String? _validateGroup(String groupKey, String key, String? value) {
    if (groupKey != 'card') return null;
    final all = widget.groupControllers[groupKey] ?? const {};
    final anyFilled = all.values.any((c) => c.text.trim().isNotEmpty);
    if (!anyFilled) return null;
    if (key == 'number') {
      if (value == null || value.trim().isEmpty) {
        return 'Укажите номер карты';
      }
      if (value.trim().length < 4) {
        return 'Номер карты: минимум 4 символа';
      }
    }
    if (key == 'issuedAt') {
      return Validators.isoDate(value, 'Дата выдачи');
    }
    if (key == 'points') {
      return Validators.nonNegativeInt(value, 'Бонусные баллы');
    }
    return null;
  }
}
