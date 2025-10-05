import 'package:flutter/material.dart';

class SeasonalFlowersScreen extends StatefulWidget {
  const SeasonalFlowersScreen({super.key});

  @override
  State<SeasonalFlowersScreen> createState() => _SeasonalFlowersScreenState();
}

class _SeasonalFlowersScreenState extends State<SeasonalFlowersScreen> {
  // Fixed data for seasonal flowers based on the design
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
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFFE8F0)),
        child: Stack(
          children: [
            // Flower list
            Positioned.fill(
              top:
                  statusBarHeight +
                  155, // Status bar + Back button (72) + Title (83)
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 10,
                  bottom: 20,
                ),
                itemCount: _flowers.length,
                itemBuilder: (context, index) {
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
              top: statusBarHeight + 12,
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

            // Title box (on top)
            Positioned(
              top: statusBarHeight + 72,
              left: 0,
              child: Container(
                width: 387,
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
        ),
      ),
    );
  }

  Widget _buildFlowerCard(Map<String, dynamic> flower) {
    final String nameThai = flower['nameThai'] ?? '';
    final String nameEnglish = flower['nameEnglish'] ?? '';
    final List<String> useFor = List<String>.from(flower['useFor'] ?? []);
    final String? imagePath = flower['imagePath'];

    return Center(
      child: Container(
        width: 330,
        height: 165,
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
            // Image section with padding
            Container(
              width: 175,
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

            // Content section
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Flower name - English first
                    Text(
                      nameEnglish,
                      style: const TextStyle(
                        fontFamily: 'Encode',
                        fontSize: 14,
                        color: Color.fromRGBO(91, 14, 43, 1),
                      ),
                    ),
                    Text(
                      nameThai,
                      style: const TextStyle(
                        fontFamily: 'Encode',
                        fontSize: 14,
                        color: Color.fromRGBO(91, 14, 43, 1),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                style: const TextStyle(
                                  fontFamily: 'Encode',
                                  fontSize: 12,
                                  color: Color.fromRGBO(75, 7, 33, 1),
                                ),
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
    );
  }
}
