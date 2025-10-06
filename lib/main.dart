import 'package:flutter/material.dart';
import 'start_screen.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database early to catch any issues
  try {
    print('=== MAIN.DART DATABASE DEBUG ===');
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
    print('Database initialized successfully');
    // Check if data was imported
    final flowers = await dbHelper.getAllFlowers();
    print('Found ${flowers.length} flowers in database');

    // Show all flowers with their details
    print('--- ALL FLOWERS IN DATABASE ---');
    for (int i = 0; i < flowers.length; i++) {
      final flower = flowers[i];
      print('${i + 1}. ${flower.nameThai} (${flower.nameEnglish})');
      print('   Day: ${flower.day}');
      print('   Favorite: ${flower.isFavorite}');
      print('   Image URL: ${flower.imageUrl}');
      print('   Has Base64: ${flower.imageBase64 != null ? "Yes" : "No"}');

      // Show color meanings if available
      if (flower.meanings.colorMeanings != null &&
          flower.meanings.colorMeanings!.isNotEmpty) {
        print('   Color Meanings:');
        for (var colorMeaning in flower.meanings.colorMeanings!) {
          print('     - ${colorMeaning.color}: ${colorMeaning.meaning}');
        }
      } else {
        print('   Color Meanings: None');
      }

      print('   Other Meanings: ${flower.meanings.other ?? "None"}');
      print('   Use For: ${flower.useFor?.join(", ") ?? "None"}');
      print('');
    }

    final favorites = await dbHelper.getFavoriteFlowers();
    print('--- FAVORITE FLOWERS (${favorites.length} total) ---');
    for (int i = 0; i < favorites.length; i++) {
      final flower = favorites[i];
      print(
        '${i + 1}. ${flower.nameThai} (${flower.nameEnglish}) - Day: ${flower.day}',
      );
    }

    print('=== END MAIN.DART DEBUG ===');
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
