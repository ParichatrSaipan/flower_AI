import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/flower.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _databaseName = 'florasign.db';
  static const int _databaseVersion = 1;
  static const String _jsonAssetPath = 'asset/data/flowers.json';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Use application documents directory for reliable cross-platform support
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    print('Using database path: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Create flowers table
    await db.execute('''
      CREATE TABLE flowers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT,
        nameThai TEXT NOT NULL,
        nameEnglish TEXT NOT NULL,
        imageUrl TEXT,
        colorMeanings TEXT,
        otherMeanings TEXT,
        useFor TEXT,
        isFavorite INTEGER DEFAULT 0,
        imageBase64 TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        UNIQUE(nameThai, nameEnglish)
      )
    ''');

    // Create favorites cache table for quick access
    await db.execute('''
      CREATE TABLE favorites_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        flowerName TEXT NOT NULL UNIQUE,
        lastSynced TEXT,
        isDeleted INTEGER DEFAULT 0
      )
    ''');

    // Create sync log table
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action TEXT NOT NULL,
        flowerName TEXT,
        timestamp TEXT,
        success INTEGER DEFAULT 0,
        errorMessage TEXT
      )
    ''');

    // Create data version table to track JSON version
    await db.execute('''
      CREATE TABLE data_version (
        id INTEGER PRIMARY KEY,
        json_version INTEGER NOT NULL,
        last_updated TEXT NOT NULL
      )
    ''');

    // Automatically import data from JSON file on first run
    await _importFlowersFromJson(db);
  }

  Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add any new columns or tables for version 2
    }
  }

  // FLOWER OPERATIONS

  /// Insert or update a flower in the database
  Future<int> insertOrUpdateFlower(Flower flower) async {
    final db = await database;

    final existingFlower = await getFlowerByName(flower.nameThai);

    if (existingFlower != null) {
      // Update existing flower
      final updatedFlower = flower.copyWith(
        id: existingFlower.id,
        updatedAt: DateTime.now(),
      );

      await db.update(
        'flowers',
        updatedFlower.toMap(),
        where: 'id = ?',
        whereArgs: [existingFlower.id],
      );

      return existingFlower.id!;
    } else {
      // Insert new flower
      final newFlower = flower.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await db.insert('flowers', newFlower.toMap());
    }
  }

  /// Get a flower by Thai or English name
  Future<Flower?> getFlowerByName(String name) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'flowers',
      where: 'nameThai = ? OR nameEnglish = ?',
      whereArgs: [name, name],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return Flower.fromMap(results.first);
    }
    return null;
  }

  /// Get all flowers from the database
  Future<List<Flower>> getAllFlowers() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('flowers');
    return results.map((map) => Flower.fromMap(map)).toList();
  }

  /// Get all favorite flowers
  Future<List<Flower>> getFavoriteFlowers() async {
    final db = await database;

    // Debug: First check all flowers and their favorite status
    final allFlowers = await db.query('flowers');
    print('DatabaseHelper: Total flowers in database: ${allFlowers.length}');
    for (var row in allFlowers) {
      print(
        'DatabaseHelper: ${row['nameEnglish']} - isFavorite: ${row['isFavorite']} (type: ${row['isFavorite'].runtimeType})',
      );
    }

    // Now get just favorites
    final List<Map<String, dynamic>> results = await db.query(
      'flowers',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'updatedAt DESC',
    );

    print(
      'DatabaseHelper: SQL query returned ${results.length} favorite flowers',
    );
    for (var row in results) {
      print(
        'DatabaseHelper: Favorite query result: ${row['nameEnglish']} - isFavorite: ${row['isFavorite']}',
      );
    }

    return results.map((map) => Flower.fromMap(map)).toList();
  }

  /// Update flower favorite status
  Future<void> updateFavoriteStatus(String flowerName, bool isFavorite) async {
    final db = await database;

    await db.update(
      'flowers',
      {
        'isFavorite': isFavorite ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'nameThai = ? OR nameEnglish = ?',
      whereArgs: [flowerName, flowerName],
    );

    // Update favorites cache
    await _updateFavoritesCache(flowerName, isFavorite);
  }

  /// Update flower image base64 data
  Future<void> updateFlowerImage(String flowerName, String imageBase64) async {
    final db = await database;

    await db.update(
      'flowers',
      {
        'imageBase64': imageBase64,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'nameThai = ? OR nameEnglish = ?',
      whereArgs: [flowerName, flowerName],
    );
  }

  /// Delete a flower from the database
  Future<void> deleteFlower(String flowerName) async {
    final db = await database;

    await db.delete(
      'flowers',
      where: 'nameThai = ? OR nameEnglish = ?',
      whereArgs: [flowerName, flowerName],
    );

    // Remove from favorites cache
    await db.delete(
      'favorites_cache',
      where: 'flowerName = ?',
      whereArgs: [flowerName],
    );
  }

  // FAVORITES CACHE OPERATIONS

  /// Update favorites cache
  Future<void> _updateFavoritesCache(String flowerName, bool isFavorite) async {
    final db = await database;

    if (isFavorite) {
      await db.insert('favorites_cache', {
        'flowerName': flowerName,
        'lastSynced': DateTime.now().toIso8601String(),
        'isDeleted': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete(
        'favorites_cache',
        where: 'flowerName = ?',
        whereArgs: [flowerName],
      );
    }
  }

  /// Get favorites that need to be synced with API
  Future<List<String>> getFavoritesToSync() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'favorites_cache',
      where: 'isDeleted = ?',
      whereArgs: [0],
    );
    return results.map((map) => map['flowerName'] as String).toList();
  }

  // SYNC LOG OPERATIONS

  /// Log sync operation
  Future<void> logSyncOperation(
    String action,
    String? flowerName,
    bool success, [
    String? errorMessage,
  ]) async {
    final db = await database;

    await db.insert('sync_log', {
      'action': action,
      'flowerName': flowerName,
      'timestamp': DateTime.now().toIso8601String(),
      'success': success ? 1 : 0,
      'errorMessage': errorMessage,
    });
  }

  /// Get recent sync logs
  Future<List<Map<String, dynamic>>> getSyncLogs({int limit = 50}) async {
    final db = await database;
    return await db.query('sync_log', orderBy: 'timestamp DESC', limit: limit);
  }

  // UTILITY OPERATIONS

  /// Get the full path to the database file
  Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _databaseName);
  }

  /// Check if database file exists
  Future<bool> databaseExists() async {
    final path = await getDatabasePath();
    return File(path).exists();
  }

  /// Get database file size in bytes
  Future<int> getDatabaseSize() async {
    final path = await getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Get database file info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final path = await getDatabasePath();
    final file = File(path);
    final exists = await file.exists();

    if (exists) {
      final size = await file.length();
      final lastModified = await file.lastModified();
      final stats = await getDatabaseStats();

      return {
        'path': path,
        'exists': exists,
        'sizeBytes': size,
        'sizeKB': (size / 1024).toStringAsFixed(2),
        'sizeMB': (size / (1024 * 1024)).toStringAsFixed(2),
        'lastModified': lastModified.toIso8601String(),
        'totalFlowers': stats['totalFlowers'],
        'favoriteFlowers': stats['favoriteFlowers'],
        'syncLogs': stats['syncLogs'],
      };
    } else {
      return {
        'path': path,
        'exists': false,
        'message': 'Database file does not exist yet',
      };
    }
  }

  /// Clear all data from the database
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('flowers');
    await db.delete('favorites_cache');
    await db.delete('sync_log');
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final flowerCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM flowers'),
        ) ??
        0;

    final favoriteCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM flowers WHERE isFavorite = 1',
          ),
        ) ??
        0;

    final syncLogCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sync_log'),
        ) ??
        0;

    return {
      'totalFlowers': flowerCount,
      'favoriteFlowers': favoriteCount,
      'syncLogs': syncLogCount,
    };
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Get the current JSON version from the asset file - COMMENTED OUT
  /*
  Future<int> getJsonVersion() async {
    try {
      String jsonContent = await rootBundle.loadString(_jsonAssetPath);
      Map<String, dynamic> jsonRoot = json.decode(jsonContent);
      return jsonRoot['version'] ?? 1;
    } catch (e) {
      print('Error reading JSON version: $e');
      return 1; // Default version
    }
  }
  */

  /// Get the current database version - COMMENTED OUT
  /*
  Future<int> getDatabaseVersion() async {
    try {
      final db = await database;
      final results = await db.query('data_version', limit: 1);
      if (results.isNotEmpty) {
        return results.first['json_version'] as int;
      }
      return 0; // No version stored yet
    } catch (e) {
      print('Error reading database version: $e');
      return 0;
    }
  }
  */

  /// Check if data needs to be refreshed - COMMENTED OUT
  /*
  Future<bool> needsDataRefresh() async {
    final jsonVersion = await getJsonVersion();
    final dbVersion = await getDatabaseVersion();
    print('Version check: JSON=$jsonVersion, Database=$dbVersion');
    return jsonVersion > dbVersion;
  }
  */

  /// Auto-refresh data if JSON version is newer - COMMENTED OUT
  /*
  Future<bool> autoRefreshIfNeeded() async {
    try {
      if (await needsDataRefresh()) {
        print('Auto-refreshing data due to version mismatch...');
        await clearAndReimportData();
        return true; // Data was refreshed
      }
      return false; // No refresh needed
    } catch (e) {
      print('Error during auto-refresh: $e');
      return false;
    }
  }
  */

  /// Clear all data and re-import from JSON (useful for data sync issues)
  Future<void> clearAndReimportData() async {
    try {
      final db = await database;

      print('Clearing all flower data...');
      await db.delete('flowers');
      await db.delete('favorites_cache');
      await db.delete('sync_log');

      print('Re-importing data from JSON...');
      await _importFlowersFromJson(db);

      print('Data clear and re-import completed successfully');
    } catch (e) {
      print('Error during clear and re-import: $e');
      rethrow;
    }
  }

  /// Import flowers from JSON asset automatically on first run
  Future<void> _importFlowersFromJson(Database db) async {
    try {
      // Load JSON from Flutter assets
      print('Loading JSON from assets: $_jsonAssetPath');
      String jsonContent = await rootBundle.loadString(_jsonAssetPath);

      // Parse the JSON as a simple array
      List<dynamic> jsonData = json.decode(jsonContent);

      print('Found ${jsonData.length} flowers in JSON');

      int importedCount = 0;
      for (var item in jsonData) {
        try {
          // Parse colorMeanings
          List<FlowerTypeMeanning>? colorMeaningsList;
          if (item['meanings']?['colorMeanings'] != null &&
              item['meanings']['colorMeanings'] is List) {
            try {
              colorMeaningsList = (item['meanings']['colorMeanings'] as List)
                  .map((colorItem) => FlowerTypeMeanning.fromJson(colorItem))
                  .toList();
            } catch (e) {
              print(
                'Error parsing colorMeanings for ${item['nameEnglish']}: $e',
              );
            }
          }

          // Parse meanings
          Meanings meanings = Meanings(
            colorMeanings: colorMeaningsList,
            other: item['meanings']?['other']?.toString(),
          );

          // Parse useFor list
          List<String>? useForList;
          if (item['useFor'] != null && item['useFor'] is List) {
            useForList = (item['useFor'] as List)
                .map((e) => e.toString())
                .toList();
          }

          // Load image from path if provided, otherwise use base64 if available
          String? imageBase64Data;

          // Support multiple field names for backward compatibility
          String? imageValue =
              item['imageBase64']?.toString() ??
              item['imageUrl']?.toString() ??
              item['image']?.toString() ??
              item['imageBinary']?.toString();
          if (imageValue != null && imageValue.isNotEmpty) {
            // If it starts with common image path prefixes, treat as path
            if (imageValue.startsWith('assets/') ||
                imageValue.startsWith('lib/') ||
                imageValue.startsWith('/') ||
                imageValue.endsWith('.png') ||
                imageValue.endsWith('.jpg') ||
                imageValue.endsWith('.jpeg')) {
              try {
                // Load image from assets and convert to base64
                final ByteData imageData = await rootBundle.load(imageValue);
                final bytes = imageData.buffer.asUint8List();
                imageBase64Data = base64Encode(bytes);
                print('Loaded image from path: $imageValue');
              } catch (e) {
                print('Error loading image from path $imageValue: $e');
                // If path loading fails, set to null instead of using invalid data
                imageBase64Data = null;
              }
            } else {
              // Assume it's already base64
              imageBase64Data = imageValue;
            }
          }

          // Create flower object from JSON data
          Flower flower = Flower(
            day: item['day']?.toString() ?? '',
            nameThai: item['nameThai']?.toString() ?? '',
            nameEnglish: item['nameEnglish']?.toString() ?? '',
            imageUrl: item['imageUrl']?.toString(),
            meanings: meanings,
            useFor: useForList,
            isFavorite: item['isFavorite'] == true,
            imageBase64: imageBase64Data,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Insert flower into database with replace strategy
          await db.insert(
            'flowers',
            flower.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          importedCount++;
        } catch (e) {
          print('Error importing flower: ${item['nameThai']} - $e');
        }
      }

      print('Successfully imported $importedCount flowers from JSON assets');

      // Log the import in sync log
      await db.insert('sync_log', {
        'action': 'JSON_IMPORT',
        'flowerName': null,
        'timestamp': DateTime.now().toIso8601String(),
        'success': 1,
        'errorMessage': 'Imported $importedCount flowers on first run',
      });
    } catch (e) {
      print('Error during JSON import: $e');

      // Log the error
      await db.insert('sync_log', {
        'action': 'JSON_IMPORT',
        'flowerName': null,
        'timestamp': DateTime.now().toIso8601String(),
        'success': 0,
        'errorMessage': 'Import failed: $e',
      });
    }
  }
}
