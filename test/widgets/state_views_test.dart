import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mebel_web/widgets/state_views.dart';

void main() {
  testWidgets('во время загрузки показывается индикатор', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoadingView())),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('пустой результат показывает текст и сбрасывает фильтры',
      (tester) async {
    var resetCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyView(
            text: 'Товаров не найдено',
            onReset: () => resetCalls++,
          ),
        ),
      ),
    );

    expect(find.text('Товаров не найдено'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.tap(find.text('Сбросить фильтры'));
    await tester.pump();

    expect(resetCalls, 1);
  });

  testWidgets('ошибка показывает сообщение и кнопку повтора', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            message: 'Сервер недоступен',
            onRetry: () => retries++,
          ),
        ),
      ),
    );

    expect(find.text('Сервер недоступен'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);

    await tester.tap(find.text('Повторить'));
    await tester.pump();

    expect(retries, 1);
  });
}
