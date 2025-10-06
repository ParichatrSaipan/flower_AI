import 'package:flutter/material.dart';

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
        'nameThai': 'ดอกมะลิ',
        'imageUrl': 'asset/mondayflower.png',
      },
      {
        'day': 'อังคาร',
        'nameThai': 'ดอกกุหลาบสีชมพู',
        'imageUrl': 'asset/tuesdayflower.png',
      },
      {
        'day': 'พุธ',
        'nameThai': 'ดอกบัว',
        'imageUrl': 'asset/wednesdayflower.jpg',
      },
      {
        'day': 'พฤหัสบดี',
        'nameThai': 'ดอกกุหลาบสีเหลือง',
        'imageUrl': 'asset/thursdayflower.png',
      },
      {
        'day': 'ศุกร์',
        'nameThai': 'ดอกไวโอเลต',
        'imageUrl': 'asset/fridayflower.png',
      },
      {
        'day': 'เสาร์',
        'nameThai': 'ดอกลิลลี่สีขาว',
        'imageUrl': 'asset/saturdayflower.png',
      },
      {
        'day': 'อาทิตย์',
        'nameThai': 'ดอกทานตะวัน',
        'imageUrl': 'asset/sundayflower.png',
      },
    ];
  }

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
        // Scrollable flower list
        Positioned.fill(
          top: 155,
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
                  'ดอกไม้ประจำวันเกิด',
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _flowers.length,
                  itemBuilder: (context, index) {
                    final flower = _flowers[index];
                    return _buildFlowerDayCard(
                      flower['day'] ?? '',
                      flower['nameThai'] ?? '',
                      flower['imagePath'],
                      isLandscape: true,
                    );
                  },
                ),
        ),
      ],
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
    return 'asset/mondayflower.png';
  }

  Color _getColorForDay(String day) {
    final dayLower = day.toLowerCase();
    if (dayLower.contains('จันทร์') || dayLower.contains('monday')) {
      return Color.fromRGBO(91, 14, 43, 1);
    } else if (dayLower.contains('อังคาร') || dayLower.contains('tuesday')) {
      return Color.fromRGBO(91, 14, 43, 1);
    } else if (dayLower.contains('พุธ') || dayLower.contains('wednesday')) {
      return Color.fromRGBO(91, 14, 43, 1);
    } else if (dayLower.contains('พฤหัสบดี') || dayLower.contains('thursday')) {
      return Color.fromRGBO(91, 14, 43, 1);
    } else if (dayLower.contains('ศุกร์') || dayLower.contains('friday')) {
      return Color.fromRGBO(91, 14, 43, 1);
    } else if (dayLower.contains('เสาร์') || dayLower.contains('saturday')) {
      return Color.fromRGBO(91, 14, 43, 1);
    } else if (dayLower.contains('อาทิตย์') || dayLower.contains('sunday')) {
      return Color.fromRGBO(91, 14, 43, 1);
    }
    return const Color.fromRGBO(91, 14, 43, 1);
  }

  Widget _buildFlowerDayCard(
    String day,
    String flowerName,
    String? imagePath, {
    bool isLandscape = false,
  }) {
    return Center(
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
            ),

            // Content section
            Expanded(
              flex: isLandscape ? 2 : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: isLandscape ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: _getColorForDay(day),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        '"$flowerName"',
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: isLandscape ? 16 : 18,
                          color: Color.fromRGBO(91, 14, 43, 1),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
