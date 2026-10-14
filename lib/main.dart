import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'logic/settings.dart';
import 'router.dart';

void main() {
  usePathUrlStrategy();
  runApp(const CalcApp());
}

class CalcApp extends StatelessWidget {
  const CalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsStore()..load(),
      child: Consumer<SettingsStore>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'Калькулятор и конвертер',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: settings.theme,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
