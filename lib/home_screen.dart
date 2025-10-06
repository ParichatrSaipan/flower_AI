import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'birth_flowers_screen.dart';
import 'popular_flowers_screen.dart';
import 'favorites_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('asset/start_screen.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              if (isLandscape) {
                return _buildLandscapeLayout();
              }

              return _buildPortraitLayout();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Top row with logo and favorite
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo on the left
              Image.asset('asset/logo.png', width: 150, height: 105),
              // Favorite button on the right
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.pink.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Content cards
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildFlowerCard('Birth Flowers', 'asset/birthflowers.png', () {
                  print('Birth Flowers card pressed');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BirthFlowersScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                _buildFlowerCard(
                  'Popular Flowers ',
                  'asset/popularflowers.png',
                  () {
                    print('Popular Flowers card pressed');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SeasonalFlowersScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Camera button
        Padding(
          padding: const EdgeInsets.all(20),
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
              if (result != null) {
                print('Photo saved at: $result');
                _sendImageToAPI(result);
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.pink.shade300,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Left side - Logo and buttons
        Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  // Logo
                  Image.asset('asset/logo.png', width: 120, height: 84),
                  const SizedBox(height: 20),
                  // Favorite button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoritesScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
              // Camera button
              InkWell(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraScreen(),
                    ),
                  );
                  if (result != null) {
                    print('Photo saved at: $result');
                    _sendImageToAPI(result);
                  }
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.pink.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right side - Content cards
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _buildFlowerCard(
                      'Birth Flowers',
                      'asset/birthflowers.png',
                      () {
                        print('Birth Flowers card pressed');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BirthFlowersScreen(),
                          ),
                        );
                      },
                      isLandscape: true,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: _buildFlowerCard(
                      'Popular Flowers ',
                      'asset/popularflowers.png',
                      () {
                        print('Popular Flowers card pressed');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SeasonalFlowersScreen(),
                          ),
                        );
                      },
                      isLandscape: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendImageToAPI(String imagePath) async {
    try {
      File imageFile = File(imagePath);

      print('Image ready to send to API: $imagePath');
      print('File exists: ${imageFile.existsSync()}');
      print('File size: ${imageFile.lengthSync()} bytes');
    } catch (e) {
      print('Error preparing image for API: $e');
    }
  }

  Widget _buildFlowerCard(
    String title,
    String imagePath,
    VoidCallback onTap, {
    bool isLandscape = false,
  }) {
    final width = isLandscape ? 280.0 : 335.0;
    final height = isLandscape ? 200.0 : 224.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        constraints: BoxConstraints(
          maxWidth: isLandscape ? 320 : 335,
          maxHeight: isLandscape ? 220 : 224,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Center(child: Icon(Icons.image, size: 50)),
                  );
                },
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
