import 'dart:convert';
import 'dart:typed_data';
import '../models/flower.dart';
import '../services/database_helper.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  /// Get favorite flowers from local database only
  /// No API sync needed - all data is local
  Future<List<Flower>> getFavoriteFlowers() async {
    try {
      final favorites = await _databaseHelper.getFavoriteFlowers();
      print('FavoritesService: Found ${favorites.length} favorite flowers');
      for (var flower in favorites) {
        print('FavoritesService: Favorite flower: ${flower.nameEnglish} (isFavorite: ${flower.isFavorite})');
      }
      return favorites;
    } catch (e) {
      print('Error getting favorite flowers: $e');
      return [];
    }
  }

  /// Auto-refresh data if JSON version is newer - COMMENTED OUT
  /*
  Future<bool> autoRefreshIfNeeded() async {
    try {
      return await _databaseHelper.autoRefreshIfNeeded();
    } catch (e) {
      print('Error checking for auto-refresh: $e');
      return false;
    }
  }
  */

  /// Clear and re-import all data from JSON (for debugging data issues)
  Future<bool> clearAndReimportData() async {
    try {
      await _databaseHelper.clearAndReimportData();
      return true;
    } catch (e) {
      print('Error clearing and re-importing data: $e');
      return false;
    }
  }

  /// Get all flowers from database (for debugging)
  Future<List<Flower>> getAllFlowersDebug() async {
    try {
      return await _databaseHelper.getAllFlowers();
    } catch (e) {
      print('Error getting all flowers: $e');
      return [];
    }
  }

  /// Add flower to favorites (local only)
  Future<bool> addToFavorites(String flowerName) async {
    try {
      await _databaseHelper.updateFavoriteStatus(flowerName, true);
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove flower from favorites (local only)
  Future<bool> removeFromFavorites(String flowerName) async {
    try {
      await _databaseHelper.updateFavoriteStatus(flowerName, false);
      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  /// Get flower image from local cache
  Future<Uint8List?> getFlowerImage(String flowerName) async {
    try {
      final cachedFlower = await _databaseHelper.getFlowerByName(flowerName);
      if (cachedFlower?.imageBase64 != null) {
        return base64Decode(cachedFlower!.imageBase64!);
      }
      return null;
    } catch (e) {
      print('Error getting flower image: $e');
      return null;
    }
  }

  /// Check if a flower is in favorites
  Future<bool> isFavorite(String flowerName) async {
    try {
      final flower = await _databaseHelper.getFlowerByName(flowerName);
      return flower?.isFavorite ?? false;
    } catch (e) {
      print('Error checking if flower is favorite: $e');
      return false;
    }
  }

  /// Get flower by name from local database
  Future<Flower?> getFlowerByName(String flowerName) async {
    try {
      return await _databaseHelper.getFlowerByName(flowerName);
    } catch (e) {
      print('Error getting flower by name: $e');
      return null;
    }
  }

  /// Get all flowers from local database
  Future<List<Flower>> getAllFlowers() async {
    try {
      return await _databaseHelper.getAllFlowers();
    } catch (e) {
      print('Error getting all flowers: $e');
      return [];
    }
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    return await _databaseHelper.getDatabaseStats();
  }

  /// Get database file information
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    return await _databaseHelper.getDatabaseInfo();
  }

  /// Get database path
  Future<String> getDatabasePath() async {
    return await _databaseHelper.getDatabasePath();
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _databaseHelper.clearAllData();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
