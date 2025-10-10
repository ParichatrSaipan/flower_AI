import 'package:flutter/material.dart';
import 'start_screen.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database early to catch any issues
  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
  } catch (e) {
    print('Database initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flora Sign',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        useMaterial3: true,
      ),
      home: const StartScreen(),
    );
  }
}
