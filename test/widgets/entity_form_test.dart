import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/validation/validators.dart';
import 'package:mebel_web/widgets/entity_form.dart';

void main() {
  testWidgets('форма не отправляется с пустым названием', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    var submitted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: EntityForm(
                  formKey: formKey,
                  maxWidth: 400,
                  fields: [
                    FieldSpec(
                      key: 'name',
                      label: 'Название',
                      validate: (value) =>
                          Validators.required(value, 'название'),
                    ),
                  ],
                  controllers: {'name': controller},
                  dropdownValues: const {},
                  multiValues: const {},
                  groupControllers: const {},
                  onDropdownChanged: (_, __) {},
                  onMultiChanged: (_, __) {},
                ),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) submitted = true;
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Сохранить'));
    await tester.pump();

    expect(submitted, isFalse);
    expect(find.text('Укажите название'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Диван');
    await tester.tap(find.text('Сохранить'));
    await tester.pump();

    expect(submitted, isTrue);

    controller.dispose();
  });

  testWidgets('проверка почты отклоняет адрес без собаки', (tester) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: 'ivanov.example.com');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EntityForm(
            formKey: formKey,
            maxWidth: 400,
            fields: [
              FieldSpec(
                key: 'email',
                label: 'Почта',
                validate: Validators.email,
              ),
            ],
            controllers: {'email': controller},
            dropdownValues: const {},
            multiValues: const {},
            groupControllers: const {},
            onDropdownChanged: (_, __) {},
            onMultiChanged: (_, __) {},
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('Некорректный адрес почты'), findsOneWidget);

    controller.dispose();
  });
}
