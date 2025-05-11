import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:argumate/generated/l10n.dart';

import './pages/home.dart';
import './pages/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _lightTheme() {
    return ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color.fromARGB(255, 37, 51, 84),
        scaffoldBackgroundColor: const Color(0xFFE1E0DB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 209, 207, 201),
          foregroundColor: Color(0xFF0A1631),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF0A1631)),
          bodyMedium: TextStyle(color: Color(0xFF2A3655)),
          displayLarge: TextStyle(
            color: Color(0xFF0A1631),
            fontWeight: FontWeight.bold,
            fontSize: 36,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0A1631)),
          ),
          hintStyle: const TextStyle(color: Color(0xFF2A3655)),
        ));
  }

  // 深色模式主题
  ThemeData _darkTheme() {
    return ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE1E0DB),
        scaffoldBackgroundColor: const Color.fromARGB(255, 22, 28, 40),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 22, 34, 68),
          foregroundColor: Color(0xFFE1E0DB),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFE1E0DB)),
          bodyMedium: TextStyle(color: Color(0xFFB8B7B2)),
          displayLarge: TextStyle(
            color: Color(0xFFE1E0DB),
            fontWeight: FontWeight.bold,
            fontSize: 37,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A2647),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE1E0DB)),
          ),
          hintStyle: const TextStyle(color: Color(0xFFB8B7B2)),
        ));
  }
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Argumate',
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          S.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('zh'),
        ],
        debugShowCheckedModeBanner: false,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        themeMode: ThemeMode.system,
        home: const LoginPage(),
        routes: {
          '/home': (context) => HomePage(),
          '/login': (context) => const LoginPage(),
        });
  }
}
