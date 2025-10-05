import 'package:flutter/material.dart';
import 'flower_detail_screen.dart';
import 'services/database_helper.dart';

class BirthFlowersScreen extends StatefulWidget {
  const BirthFlowersScreen({super.key});

  @override
  State<BirthFlowersScreen> createState() => _BirthFlowersScreenState();
}

class _BirthFlowersScreenState extends State<BirthFlowersScreen> {
  List<dynamic> _flowers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFlowers();
  }

  Future<void> _loadFlowers() async {
    try {
      // Static flower data instead of API
      final flowers = _getStaticFlowerData();
      setState(() {
        _flowers = flowers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getStaticFlowerData() {
    return [
      {
        'day': 'จันทร์',
        'nameThai': 'ดอกดาวเรือง',
        'imageUrl': 'asset/mondayflower.png'
      },
      {
        'day': 'อังคาร',
        'nameThai': 'ดอกอิกซอร่า',
        'imageUrl': 'asset/tuesdayflower.png'
      },
      {
        'day': 'พุธ',
        'nameThai': 'ดอกบัว',
        'imageUrl': 'asset/wednesdayflower.png'
      },
      {
        'day': 'พฤหัสบดี',
        'nameThai': 'ดอกพิกุล',
        'imageUrl': 'asset/thursdayflower.png'
      },
      {
        'day': 'ศุกร์',
        'nameThai': 'ดอกชบา',
        'imageUrl': 'asset/fridayflower.png'
      },
      {
        'day': 'เสาร์',
        'nameThai': 'ดอกกุหลาบ',
        'imageUrl': 'asset/saturdayflower.png'
      },
      {
        'day': 'อาทิตย์',
        'nameThai': 'ดอกทานตะวัน',
        'imageUrl': 'asset/sundayflower.png'
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFE8F0),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Stack(
            children: [
              // Scrollable flower list
              Positioned.fill(
                top: 155, // Back button (72) + Title (83)
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Text(
                              'Error: $_error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : ListView.builder(
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
                                child: _buildFlowerDayCard(
                                  flower['day'] ?? '',
                                  flower['nameThai'] ?? '',
                                  flower['imagePath'],
                                ),
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

              // Title box (on top)
              Positioned(
                top: 72,
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
                      'ดอกไม้ประจำวันเกิด',
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
      ),
    );
  }

  String _getImageForDay(String day) {
    final dayLower = day.toLowerCase();
    if (dayLower.contains('จันทร์') || dayLower.contains('monday')) {
      return 'asset/mondayflower.png';
    } else if (dayLower.contains('อังคาร') || dayLower.contains('tuesday')) {
      return 'asset/tuesdayflower.png';
    } else if (dayLower.contains('พุธ') || dayLower.contains('wednesday')) {
      return 'asset/wednesdayflower.png';
    } else if (dayLower.contains('พฤหัสบดี') || dayLower.contains('thursday')) {
      return 'asset/thursdayflower.png';
    } else if (dayLower.contains('ศุกร์') || dayLower.contains('friday')) {
      return 'asset/fridayflower.png';
    } else if (dayLower.contains('เสาร์') || dayLower.contains('saturday')) {
      return 'asset/saturdayflower.png';
    } else if (dayLower.contains('อาทิตย์') || dayLower.contains('sunday')) {
      return 'asset/sundayflower.png';
    }
    return 'asset/mondayflower.png'; // default
  }

  Color _getColorForDay(String day) {
    final dayLower = day.toLowerCase();
    if (dayLower.contains('จันทร์') || dayLower.contains('monday')) {
      return const Color.fromRGBO(255, 241, 203, 1); // Yellow
    } else if (dayLower.contains('อังคาร') || dayLower.contains('tuesday')) {
      return const Color.fromRGBO(255, 255, 248, 1); // Pink
    } else if (dayLower.contains('พุธ') || dayLower.contains('wednesday')) {
      return const Color.fromRGBO(199, 230, 169, 1); // Green
    } else if (dayLower.contains('พฤหัสบดี') || dayLower.contains('thursday')) {
      return const Color.fromRGBO(255, 196, 0, 1); // Orange
    } else if (dayLower.contains('ศุกร์') || dayLower.contains('friday')) {
      return const Color.fromRGBO(207, 231, 255, 1); // Light Blue
    } else if (dayLower.contains('เสาร์') || dayLower.contains('saturday')) {
      return const Color.fromRGBO(250, 190, 255, 1); // Purple
    } else if (dayLower.contains('อาทิตย์') || dayLower.contains('sunday')) {
      return const Color.fromRGBO(255, 199, 199, 1); // Red
    }
    return const Color.fromRGBO(91, 14, 43, 1); // default
  }

  Widget _buildFlowerDayCard(
    String day,
    String flowerName,
    String? imagePath,
  ) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          // Load flower from database
          final dbHelper = DatabaseHelper();
          final flower = await dbHelper.getFlowerByName(flowerName);

          if (flower != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlowerDetailScreen(flower: flower),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่พบข้อมูลดอกไม้')),
            );
          }
        },
        child: Container(
            width: 330,
            height: 165,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(237, 137, 177, 1),
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
                    child: Image.asset(
                      _getImageForDay(day),
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
                    ),
                  ),
                ),

                // Content section
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontFamily: 'Kanit',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getColorForDay(day),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"$flowerName"',
                          style: const TextStyle(
                            fontFamily: 'Kanit',
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
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

