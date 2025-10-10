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
  static const int _databaseVersion = 2;
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
      detectedAt TEXT,
      confidence REAL,
      detectedImageBase64 TEXT,
      detectionBoxes TEXT,
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

  // 2. อัพเดท _upgradeTables
  Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    print('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // เพิ่ม columns สำหรับ detection
      await db.execute('''
      ALTER TABLE flowers ADD COLUMN detectedAt TEXT
    ''');

      await db.execute('''
      ALTER TABLE flowers ADD COLUMN confidence REAL
    ''');

      await db.execute('''
      ALTER TABLE flowers ADD COLUMN detectedImageBase64 TEXT
    ''');

      await db.execute('''
      ALTER TABLE flowers ADD COLUMN detectionBoxes TEXT
    ''');

      print('✅ Added detection columns to flowers table');
    }
  }

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
          // ✅ Parse colorMeanings - เก็บเป็น JSON string
          String? colorMeaningsJson;
          if (item['meanings']?['colorMeanings'] != null &&
              item['meanings']['colorMeanings'] is List) {
            try {
              final colorList = item['meanings']['colorMeanings'] as List;
              colorMeaningsJson = json.encode(colorList);
              print('✅ Parsed colorMeanings for ${item['nameThai']}');
            } catch (e) {
              print('Error parsing colorMeanings for ${item['nameThai']}: $e');
            }
          }

          // ✅ Parse useFor - เก็บเป็น JSON string
          String? useForJson;
          if (item['useFor'] != null && item['useFor'] is List) {
            try {
              final useList = item['useFor'] as List;
              useForJson = json.encode(useList);
              print('✅ Parsed useFor for ${item['nameThai']}');
            } catch (e) {
              print('Error parsing useFor for ${item['nameThai']}: $e');
            }
          }

          // Load image from path if provided
          String? imageBase64Data;
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
                imageBase64Data = null;
              }
            } else {
              // Assume it's already base64
              imageBase64Data = imageValue;
            }
          }

          // ✅ Insert flower into database พร้อมข้อมูล colorMeanings และ useFor
          await db.insert('flowers', {
            'day': item['day']?.toString() ?? '',
            'nameThai': item['nameThai']?.toString() ?? '',
            'nameEnglish': item['nameEnglish']?.toString() ?? '',
            'imageUrl': item['imageUrl']?.toString(),
            'colorMeanings': colorMeaningsJson,
            'otherMeanings': item['meanings']?['other']?.toString(),
            'useFor': useForJson,
            'isFavorite': item['isFavorite'] == true ? 1 : 0,
            'imageBase64': imageBase64Data,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          importedCount++;
        } catch (e) {
          print('Error importing flower: ${item['nameThai']} - $e');
        }
      }

      print('✅ Successfully imported $importedCount flowers from JSON assets');

      // Log the import in sync log
      await db.insert('sync_log', {
        'action': 'JSON_IMPORT',
        'flowerName': null,
        'timestamp': DateTime.now().toIso8601String(),
        'success': 1,
        'errorMessage': 'Imported $importedCount flowers on first run',
      });
    } catch (e) {
      print('❌ Error during JSON import: $e');

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

  /// บันทึกผลการ detect พร้อมข้อมูลดอกไม้
  Future<int> saveDetectionResult({
    required String flowerName,
    required DateTime detectedAt,
    required double confidence,
    required String detectedImageBase64,
    List<Map<String, dynamic>>? detectionBoxes,
  }) async {
    final db = await database;

    // แปลง detectionBoxes เป็น JSON string
    String? boxesJson;
    if (detectionBoxes != null && detectionBoxes.isNotEmpty) {
      boxesJson = json.encode(detectionBoxes);
    }

    // อัพเดทข้อมูล detection ในดอกไม้ที่มีอยู่
    final result = await db.update(
      'flowers',
      {
        'detectedAt': detectedAt.toIso8601String(),
        'confidence': confidence,
        'detectedImageBase64': detectedImageBase64,
        'detectionBoxes': boxesJson,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'nameThai = ? OR nameEnglish = ?',
      whereArgs: [flowerName, flowerName],
    );

    // ถ้าอัพเดทสำเร็จ log ไว้
    if (result > 0) {
      await logSyncOperation(
        'DETECTION_SAVED',
        flowerName,
        true,
        'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
      );
    }

    return result;
  }

  /// ดึงประวัติการ detect ล่าสุด
  Future<List<Flower>> getRecentDetections({int limit = 10}) async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      'flowers',
      where: 'detectedAt IS NOT NULL',
      orderBy: 'detectedAt DESC',
      limit: limit,
    );

    return results.map((map) => Flower.fromMap(map)).toList();
  }

  /// ลบข้อมูล detection (แต่เก็บข้อมูลดอกไม้ไว้)
  Future<void> clearDetectionData(String flowerName) async {
    final db = await database;

    await db.update(
      'flowers',
      {
        'detectedAt': null,
        'confidence': null,
        'detectedImageBase64': null,
        'detectionBoxes': null,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'nameThai = ? OR nameEnglish = ?',
      whereArgs: [flowerName, flowerName],
    );
  }

  /// ค้นหาดอกไม้โดยชื่ออังกฤษ (สำหรับ AI detection)
  Future<Flower?> getFlowerByEnglishName(String nameEnglish) async {
    final db = await database;

    // Normalize ชื่อ (lowercase, trim)
    final normalized = nameEnglish.toLowerCase().trim();

    final List<Map<String, dynamic>> results = await db.rawQuery(
      '''
    SELECT * FROM flowers 
    WHERE LOWER(TRIM(nameEnglish)) = ? 
    OR LOWER(TRIM(nameEnglish)) LIKE ?
    LIMIT 1
  ''',
      [normalized, '%$normalized%'],
    );

    if (results.isNotEmpty) {
      return Flower.fromMap(results.first);
    }

    return null;
  }

  /// Map ชื่อจาก AI → ชื่อใน database
  static const Map<String, String> nameMapping = {
    'rose': 'Rose',
    'carnation': 'Carnation',
    'ixora': 'Ixora',
    'gerbera': 'Gerbera',
    'lotus': 'Lotus',
    'globe amaranth': 'Globe amaranth',
    'orchid': 'Orchid',
    'gardenia augusta': 'Gardenia augusta',
    'jasmine': 'Jasmine',
    'Violet': 'Violet',
    'sunflower': 'Sunflower',
    'lily': 'Lily',
    'chrysanthemum': 'Chrysanthemum',
  };

  /// ค้นหาดอกไม้จากชื่อที่ detect ได้ (พร้อม mapping)
  Future<Flower?> findByDetectedName(String detectedName) async {
    final normalized = detectedName.toLowerCase().trim();

    // ลองใช้ mapping ก่อน
    final mappedName = nameMapping[normalized];
    if (mappedName != null) {
      final flower = await getFlowerByEnglishName(mappedName);
      if (flower != null) return flower;
    }

    // ถ้าไม่เจอ ค้นหาตรงๆ
    return await getFlowerByEnglishName(detectedName);
  }
}
