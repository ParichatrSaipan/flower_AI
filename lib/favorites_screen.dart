import 'package:flutter/material.dart';
import 'services/favorites_service.dart';
import 'flower_detail_screen.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'models/flower.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Flower> favoriteFlowers = [];
  bool isLoading = true;
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('=== FAVORITES SCREEN DEBUG ===');
      
      // Debug: Check if database has any flowers at all
      final allFlowers = await _favoritesService.getAllFlowersDebug();
      print('Total flowers in database: ${allFlowers.length}');
      
      // Print all flowers and their favorite status
      for (var flower in allFlowers) {
        print('Flower: ${flower.nameThai} (${flower.nameEnglish}) - Favorite: ${flower.isFavorite}');
      }
      
      final favorites = await _favoritesService.getFavoriteFlowers();
      print('Favorite flowers found: ${favorites.length}');
      
      // Print favorite flowers specifically
      for (var flower in favorites) {
        print('Favorite: ${flower.nameThai} (${flower.nameEnglish})');
      }
      
      print('=== END DEBUG ===');
      
      if (mounted) {
        setState(() {
          favoriteFlowers = favorites;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshFavorites() async {
    try {
      final favorites = await _favoritesService.getFavoriteFlowers();
      if (mounted) {
        setState(() {
          favoriteFlowers = favorites;
        });
      }
    } catch (e) {
      print('Error refreshing favorites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header section with different color
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFEDA6C8), // Header color
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Back button
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.black54,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title
                    const Text(
                      'Favorites',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // Heart icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body section with solid color
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8F0), // Solid pink background
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : favoriteFlowers.isEmpty
                      ? () {
                          print('UI: Showing empty state because favoriteFlowers.isEmpty = ${favoriteFlowers.isEmpty}');
                          return _buildEmptyState();
                        }()
                      : () {
                          print('UI: Showing favorites list with ${favoriteFlowers.length} flowers');
                          return RefreshIndicator(
                            onRefresh: _refreshFavorites,
                            child: _buildFavoritesList(),
                          );
                        }(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.pink.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding flowers to your favorites!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title - no spacing
          Text(
            'Favorites Flowers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color.fromRGBO(218, 117, 147, 1),
            ),
          ),
          
          // Grid of cards - immediate spacing
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: favoriteFlowers.length,
              itemBuilder: (context, index) {
                print('UI: Building card for index $index: ${favoriteFlowers[index].nameEnglish}');
                final flower = favoriteFlowers[index];
                return _buildFlowerCard(flower);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowerCard(Flower flower) {
    final flowerName = flower.nameThai.isNotEmpty ? flower.nameThai : flower.nameEnglish;

    // Decode base64 image directly from flower object
    Uint8List? imageBytes;
    if (flower.imageBase64 != null && flower.imageBase64!.isNotEmpty) {
      try {
        imageBytes = base64Decode(flower.imageBase64!);
      } catch (e) {
        print('Error decoding image for $flowerName: $e');
      }
    }

    return InkWell(
      onTap: () {
        // Navigate to flower detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlowerDetailScreen(flower: flower),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Flower image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: imageBytes != null
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.local_florist, size: 40, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.local_florist, size: 40, color: Colors.grey),
                          ),
                        ),
                ),
              ),
            ),

            // Flower name in pink rounded container
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDA6CB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  flower.nameThai.isNotEmpty ? flower.nameThai : flower.nameEnglish,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}