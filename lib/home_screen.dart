import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'birth_flowers_screen.dart';
import 'popular_flowers_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  final bool showInstructions;

  const HomeScreen({super.key, this.showInstructions = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Show instructions modal after build if requested
    if (widget.showInstructions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInfoModal(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('asset/start_screen.png'),
            fit: BoxFit.cover,
            opacity: 0.7,
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
        // Top row with logo and icons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo on the left
              Image.asset('asset/logo.png', width: 150, height: 105),
              // Icons on the right
              Row(
                children: [
                  // Info button (tap to show guidance modal)
                  InkWell(
                    onTap: () => _showInfoModal(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.pink.shade300,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // History/Clock button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.access_time,
                        color: Colors.pink.shade300,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                  ),
                ],
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
                  'Popular Flowers',
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

        // Camera button at bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.pink.shade100.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pink.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 45,
                ),
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
                  // Icons column
                  Column(
                    children: [
                      // Info button
                      InkWell(
                        onTap: () => _showInfoModal(context),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.pink.shade300,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // History button
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: Colors.pink.shade300,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      ),
                    ],
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
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
                      'Popular Flowers',
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

  Widget _buildModalListItem(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Color(0xFF6D4C5E)),
        ),
      ),
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

  void _showInfoModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 48,
          ),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 36),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'คำแนะนำ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.pink.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ดอกไม้ที่สามารถสแกน',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 241, 68, 125),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildModalListItem(context, 'ดอกกุหลาบ (Rose)'),
                      _buildModalListItem(context, 'ดอกเยอบีร่า (Gerbera)'),
                      _buildModalListItem(context, 'ดอกคาร์เนชั่น (Carnation)'),
                      _buildModalListItem(context, 'ดอกบัว (Lotus)'),
                      _buildModalListItem(context, 'ดอกพุดซ้อน (Cape Jasmine)'),
                      _buildModalListItem(context, 'ดอกเข็ม (Ixora)'),
                      _buildModalListItem(
                        context,
                        'ดอกบานไม่รู้โรย (Globe Amaranth)',
                      ),
                      _buildModalListItem(context, 'ดอกกล้วยไม้ (Orchid)'),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
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
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
                    colors: [Colors.transparent, Colors.black.withOpacity(0.2)],
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6D4C5E),
                      letterSpacing: 0.5,
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
