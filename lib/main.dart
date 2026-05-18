import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/mood_home_screen.dart';

void main() {
  runApp(const ProviderScope(child: MoodiaryApp()));
}

class MoodiaryApp extends StatelessWidget {
  const MoodiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moodiary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFC857)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDF8F2),
      ),
      home: const MoodHomeScreen(),
    );
  }
}
