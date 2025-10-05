import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'models/flower.dart';
import 'services/favorites_service.dart';
import 'dart:math' as math;

class FlowerDetailScreen extends StatefulWidget {
  final Flower flower;

  const FlowerDetailScreen({super.key, required this.flower});

  @override
  State<FlowerDetailScreen> createState() => _FlowerDetailScreenState();
}

class _FlowerDetailScreenState extends State<FlowerDetailScreen> {
  late Flower flower;
  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();
    flower = widget.flower;
    _loadFlowerImage();
  }

  void _loadFlowerImage() {
    if (flower.imageBase64 != null && flower.imageBase64!.isNotEmpty) {
      try {
        imageBytes = base64Decode(flower.imageBase64!);
        setState(() {});
      } catch (e) {
        print('Error decoding base64 image: $e');
      }
    }
  }

  void _toggleFavorite() async {
    final newFavoriteStatus = !flower.isFavorite;

    setState(() {
      flower = flower.copyWith(isFavorite: newFavoriteStatus);
    });

    try {
      final favoritesService = FavoritesService();
      if (newFavoriteStatus) {
        await favoritesService.addToFavorites(flower.nameThai);
      } else {
        await favoritesService.removeFromFavorites(flower.nameThai);
      }
      print('Favorite status updated successfully');
    } catch (e) {
      print('Error updating favorite: $e');
      if (!mounted) return;
      setState(() {
        flower = flower.copyWith(isFavorite: !newFavoriteStatus);
      });
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(content: Text('ไม่สามารถอัปเดตรายการโปรดได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: true,
        bottom: false,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final flowerData = flower;
    final hasUses = flowerData.useFor != null && flowerData.useFor!.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseGap = constraints.maxHeight > 720 ? 16.0 : 10.0;
        final imageFlex = hasUses ? 4 : 5;
        final meaningsFlex = hasUses ? 3 : 4;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildTopBar(flowerData.isFavorite),
            ),
            SizedBox(height: baseGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    flex: imageFlex,
                    fit: FlexFit.tight,
                    child: _buildImageSection(imageBytes),
                  ),
                  SizedBox(height: baseGap),
                  Flexible(
                    flex: meaningsFlex,
                    fit: FlexFit.tight,
                    child: _buildMeaningsSection(flowerData),
                  ),
                  if (hasUses) ...[
                    SizedBox(height: baseGap),
                    Flexible(
                      flex: 3,
                      fit: FlexFit.tight,
                      child: _buildUseForSection(flowerData.useFor!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(bool isFavorite) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleIconButton(
          icon: Icons.arrow_back_ios_new,
          backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
          iconColor: const Color.fromRGBO(238, 82, 162, 1),
          onPressed: () => Navigator.pop(context),
        ),
        _CircleIconButton(
          icon: isFavorite ? Icons.favorite : Icons.favorite_border,
          backgroundColor: const Color.fromRGBO(217, 217, 217, 1),
          iconColor: const Color.fromRGBO(238, 82, 162, 1),
          onPressed: _toggleFavorite,
        ),
      ],
    );
  }

  Widget _buildImageSection(Uint8List? imageBytes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const indicatorSpace = 40.0;
        final maxHeight = (constraints.maxHeight - indicatorSpace).clamp(
          140.0,
          constraints.maxHeight,
        );
        final maxWidth = constraints.maxWidth * 0.8;
        final imageSize = math.min(maxHeight, maxWidth);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: imageSize,
              width: imageSize,
              child: imageBytes != null
                  ? Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_florist,
                          size: 120,
                          color: Color(0xFFA4798D),
                        );
                      },
                    )
                  : const Icon(
                      Icons.local_florist,
                      size: 120,
                      color: Color(0xFFA4798D),
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.asset(
                    'asset/streamline-flex_flower-solid.png',
                    width: 20,
                    height: 20,
                    color: Color.fromRGBO(217, 217, 217, 1),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeaningsSection(Flower flowerData) {
    final meanings = flowerData.meanings;
    final hasColorMeanings =
        meanings.colorMeanings != null && meanings.colorMeanings!.isNotEmpty;
    final hasOtherMeaning =
        meanings.other != null && meanings.other!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF1F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(44),
          topRight: Radius.circular(44),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Container(
              width: 177,
              height: 53,
              decoration: BoxDecoration(
                color: const Color(0xFFFF94B7),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                flowerData.nameThai,
                style: const TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasColorMeanings)
                    ...meanings.colorMeanings!.map(
                      (meaning) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildColorMeaningRow(meaning),
                      ),
                    ),
                  if (!hasColorMeanings && hasOtherMeaning)
                    Text(
                      meanings.other!,
                      style: const TextStyle(
                        fontFamily: 'Kanit',
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  // Add extra space to ensure scroll is always possible
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUseForSection(List<String> useFor) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF1F7),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(237, 166, 200, 1),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'ใช้ในโอกาส',
                style: TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...useFor.map((use) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 16,
                            color: Color(0xFFFF94B7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              use,
                              style: const TextStyle(
                                fontFamily: 'Kanit',
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Add extra space to ensure scroll is always possible
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorMeaningRow(FlowerTypeMeanning meaning) {
    final color = _getColorFromName(meaning.color);
    final textColor = color.computeLuminance() > 0.6
        ? const Color(0xFF5A4A52)
        : Colors.white;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 65,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            meaning.color,
            style: TextStyle(
              fontFamily: 'Kanit',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            meaning.meaning,
            style: const TextStyle(
              fontFamily: 'Kanit',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorFromName(String colorName) {
    final Map<String, Color> colorMap = {
      'สีแดง': const Color(0xFFE53935),
      'สีขาว': Colors.white,
      'สีเหลือง': const Color(0xFFFBC02D),
      'สีส้ม': const Color(0xFFFFA726),
      'สีม่วง': const Color(0xFF8E24AA),
      'สีชมพู': const Color(0xFFF06292),
      'สีฟ้า': const Color(0xFF42A5F5),
      'สีน้ำเงิน': const Color(0xFF1E3A8A),
      'สีเขียว': const Color(0xFF43A047),
    };

    return colorMap[colorName] ?? const Color(0xFFB0BEC5);
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
      ),
    );
  }
}
