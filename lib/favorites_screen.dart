import 'package:flutter/material.dart';
import 'services/database_helper.dart';
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
  final DatabaseHelper _databaseHelper = DatabaseHelper();

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

      final allFlowers = await _databaseHelper.getAllFlowers();
      print('Total flowers in database: ${allFlowers.length}');

      for (var flower in allFlowers) {
        print(
          'Flower: ${flower.nameThai} (${flower.nameEnglish}) - Favorite: ${flower.isFavorite}',
        );
      }

      final favorites = await _databaseHelper.getFavoriteFlowers();
      print('Favorite flowers found: ${favorites.length}');

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
      final favorites = await _databaseHelper.getFavoriteFlowers();
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          if (isLandscape) {
            return _buildLandscapeLayout();
          }

          return _buildPortraitLayout();
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Header section
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(color: Color(0xFFEDA6C8)),
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

        // Body section
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Color(0xFFFFE8F0)),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : favoriteFlowers.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshFavorites,
                    child: _buildFavoritesList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left side - Header
        Container(
          width: 200,
          decoration: const BoxDecoration(color: Color(0xFFEDA6C8)),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Back button
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.black54,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Title (vertical)
                const RotatedBox(
                  quarterTurns: 0,
                  child: Text(
                    'Favorites',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                // Heart icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.pink.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),

        // Right side - Content
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Color(0xFFFFE8F0)),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : favoriteFlowers.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshFavorites,
                    child: _buildFavoritesList(isLandscape: true),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.pink.shade200),
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList({bool isLandscape = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Favorites Flowers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color.fromRGBO(218, 117, 147, 1),
            ),
          ),

          // Grid of cards
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLandscape ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isLandscape ? 0.85 : 0.9,
              ),
              itemCount: favoriteFlowers.length,
              itemBuilder: (context, index) {
                print(
                  'UI: Building card for index $index: ${favoriteFlowers[index].nameEnglish ?? favoriteFlowers[index].nameThai}',
                );
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
    final flowerName = flower.nameThai.isNotEmpty
        ? flower.nameThai
        : flower.nameEnglish;

    // Decode base64 image
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
                                  child: Icon(
                                    Icons.local_florist,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.local_florist,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // Flower name
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDA6CB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  flower.nameThai.isNotEmpty
                      ? flower.nameThai
                      : flower.nameEnglish ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
