import 'package:flutter/material.dart';

import 'home_page.dart';

class FlowForgeApp extends StatelessWidget {
  const FlowForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FlowForge',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F7A6A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F3E8),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF1F1D19),
          displayColor: const Color(0xFF1F1D19),
        ),
      ),
      home: const FlowForgeHome(),
    );
  }
}
