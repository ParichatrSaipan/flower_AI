import 'package:flutter/material.dart';
import 'flower_detail_screen.dart';
import 'services/database_helper.dart';

class SeasonalFlowersScreen extends StatefulWidget {
  const SeasonalFlowersScreen({super.key});

  @override
  State<SeasonalFlowersScreen> createState() => _SeasonalFlowersScreenState();
}

class _SeasonalFlowersScreenState extends State<SeasonalFlowersScreen> {
  final List<Map<String, dynamic>> _flowers = [
    {
      'nameThai': 'กุหลาบ',
      'nameEnglish': 'rose',
      'useFor': ['บ่งบอกความรัก', 'ความงาม', 'ความสมบูรณ์', 'ความอ่อนโยน'],
      'imagePath': 'asset/rose.png',
    },
    {
      'nameThai': 'เบญจมาศ',
      'nameEnglish': 'chrysanthemum',
      'useFor': [
        'ความยาวนาน',
        'ความซื่อสัตย์',
        'ความสุขความเบิกบาน',
        'ความจริงใจ',
      ],
      'imagePath': 'asset/chrysanthemum.png',
    },
    {
      'nameThai': 'คาร์เนชั่น',
      'nameEnglish': 'carnation',
      'useFor': ['ความรัก', 'ความภาคภูมิใจ', 'ความงดงาม', 'ความบริสุทธิ์'],
      'imagePath': 'asset/carnation.png',
    },
    {
      'nameThai': 'เยอบีร่า',
      'nameEnglish': 'gerbera',
      'useFor': ['ความหลากหลาย', 'ความรัก', 'ความอดทน', 'ความเป็นไปได้'],
      'imagePath': 'asset/transvaal.png',
    },
    {
      'nameThai': 'ลิลลี่',
      'nameEnglish': 'lily',
      'useFor': ['ความบริสุทธิ์', 'ความงดงาม', 'ความสง่างาม', 'ความสดชื่น'],
      'imagePath': 'asset/lily.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFFE8F0)),
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
    return Stack(
      children: [
        // Flower list
        Positioned.fill(
          top: 155,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 20,
            ),
            itemCount: _flowers.length + 1,
            itemBuilder: (context, index) {
              if (index == _flowers.length) {
                return _buildQuoteSection();
              }

              final flower = _flowers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFlowerCard(flower),
              );
            },
          ),
        ),

        // Back button
        Positioned(
          top: 12,
          left: 16,
          child: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(217, 217, 217, 1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color.fromRGBO(238, 82, 164, 1),
                size: 20,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),

        // Title box
        Positioned(
          top: 72,
          left: 0,
          child: Container(
            width: 365,
            height: 63,
            decoration: const BoxDecoration(
              color: Color(0xFFA4798D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(0),
                bottomLeft: Radius.circular(0),
                topRight: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: const Center(
              child: Text(
                'ดอกไม้ที่คนทั่วโลกนิยมใช้',
                style: TextStyle(
                  fontFamily: 'Kanit',
                  fontSize: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Column(
      children: [
        // Top bar with back button and title
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(217, 217, 217, 1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Color.fromRGBO(238, 82, 164, 1),
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFA4798D),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'ดอกไม้ที่คนทั่วโลกนิยมใช้',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scrollable flower grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _flowers.length + 1,
            itemBuilder: (context, index) {
              if (index == _flowers.length) {
                return _buildQuoteSection();
              }

              final flower = _flowers[index];
              return _buildFlowerCard(flower, isLandscape: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Image.asset(
                  'asset/streamline-flex_flower-solid.png',
                  width: 20,
                  height: 20,
                  color: Color.fromRGBO(255, 131, 176, 1),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Every flower blooms in its own time.',
            style: const TextStyle(
              fontFamily: 'Enriqueta',
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Color(0xFFA4798D),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFlowerCard(
    Map<String, dynamic> flower, {
    bool isLandscape = false,
  }) {
    final String nameThai = flower['nameThai'] ?? '';
    final String nameEnglish = flower['nameEnglish'] ?? '';
    final List<String> useFor = List<String>.from(flower['useFor'] ?? []);
    final String? imagePath = flower['imagePath'];

    return Center(
      child: GestureDetector(
        onTap: () async {
          final dbHelper = DatabaseHelper();

          // Name mapping for flowers that have different names in database
          final nameMapping = {
            'กุหลาบ': 'ดอกกุหลาบ',
            'rose': 'Rose',
            'ลิลลี่': 'ดอกลิลลี่',
            'lily': 'Lily',
          };

          // Get mapped names or use original names
          final mappedThaiName = nameMapping[nameThai] ?? nameThai;
          final mappedEnglishName = nameMapping[nameEnglish] ?? nameEnglish;

          // Try to find flower by Thai name first (try both original and mapped)
          var flowerData = await dbHelper.getFlowerByName(nameThai);
          flowerData ??= await dbHelper.getFlowerByName(mappedThaiName);

          // If not found, try English name (try both original and mapped)
          flowerData ??= await dbHelper.getFlowerByName(nameEnglish);
          flowerData ??= await dbHelper.getFlowerByName(mappedEnglishName);

          // If not found and name contains color, try to find by base name
          if (flowerData == null) {
            // List of Thai color words to remove
            final colorWords = [
              'สีขาว',
              'สีแดง',
              'สีชมพู',
              'สีเหลือง',
              'สีส้ม',
              'สีม่วง',
              'สีฟ้า',
              'สีน้ำเงิน',
              'สีเขียว',
            ];

            // Try to remove color from flower name
            String baseFlowerName = nameThai;
            for (var color in colorWords) {
              if (nameThai.contains(color)) {
                baseFlowerName = nameThai.replaceAll(color, '').trim();
                break;
              }
            }

            // Try again with base name if it's different
            if (baseFlowerName != nameThai) {
              flowerData = await dbHelper.getFlowerByName(baseFlowerName);
            }
          }

          if (flowerData != null) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlowerDetailScreen(flower: flowerData!),
              ),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่พบข้อมูลดอกไม้')),
            );
          }
        },
        child: Container(
        width: isLandscape ? null : 330,
        height: isLandscape ? null : 165,
        constraints: isLandscape
            ? null
            : const BoxConstraints(maxWidth: 330, maxHeight: 165),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 204, 237, 1),
          borderRadius: BorderRadius.circular(37),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image section
            Expanded(
              flex: isLandscape ? 3 : 1,
              child: Container(
                width: isLandscape ? null : 175,
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imagePath != null
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.local_florist,
                                size: 60,
                                color: Color(0xFFFF94B7),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.local_florist,
                            size: 60,
                            color: Color(0xFFFF94B7),
                          ),
                        ),
                ),
              ),
            ),

            // Content section
            Expanded(
              flex: isLandscape ? 2 : 1,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 12 : 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Flower name
                    Flexible(
                      child: Text(
                        nameEnglish,
                        style: TextStyle(
                          fontFamily: 'Encode',
                          fontSize: isLandscape ? 13 : 14,
                          color: Color.fromRGBO(91, 14, 43, 1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        nameThai,
                        style: TextStyle(
                          fontFamily: 'Encode',
                          fontSize: isLandscape ? 13 : 14,
                          color: Color.fromRGBO(91, 14, 43, 1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Use for list
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: useFor.take(3).map((use) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                use.toString(),
                                style: TextStyle(
                                  fontFamily: 'Encode',
                                  fontSize: isLandscape ? 11 : 12,
                                  color: Color.fromRGBO(75, 7, 33, 1),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
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