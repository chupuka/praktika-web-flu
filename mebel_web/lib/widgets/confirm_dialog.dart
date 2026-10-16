import 'package:flutter/material.dart';

Future<bool> confirmDialog(
  BuildContext context,
  String title, [
  String text = 'Действие нельзя отменить.',
]) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  return result ?? false;
}
