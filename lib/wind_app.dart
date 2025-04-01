import 'package:flutter/material.dart';
import 'pages/wind_page.dart';

class WindApp extends StatelessWidget {
  const WindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wind API',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const WindPage(),
    );
  }
}
