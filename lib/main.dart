import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:argumate/generated/l10n.dart';

import './pages/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blueGrey[200],
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blueGrey[100],
      ),
      textTheme: TextTheme(
        bodyLarge: const TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.grey[700]),
        displayLarge: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold,fontSize: 36),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.black45),
      )
    );
  }

    // 深色模式主题
  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.blueGrey[600],
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blueGrey[800],
      ),
      textTheme: TextTheme(
        bodyLarge: const TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.grey[100]),
        displayLarge: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 37),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.white),
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
      home: HomePage(),
      routes: {
        '/home': (context) => HomePage(),
        // '/login': (context) => const LoginPage(),
      }
    );
  }
}