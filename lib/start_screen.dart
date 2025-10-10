import 'package:flutter/material.dart';
import 'home_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

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
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 200),
                child: Image.asset(
                  'asset/logo.png',
                  width: 329,
                  height: 230,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 150),
                    child: Container(
                      width: 348,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(
                          width: 0,
                          color: Colors.transparent,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFF2F2F2),
                              Color(0xFF818181),
                              Color(0xFFFFFFFF),
                            ],
                            stops: [0.0, 0.41, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(23),
                        ),
                        padding: EdgeInsets.all(4.65),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(214, 214, 214, 0.3),
                            borderRadius: BorderRadius.circular(18.35),
                          ),
                          child: TextButton(
                            onPressed: () => _showHomeModal(context),
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(
                                fontSize: 54,
                              ),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18.35),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              "Let's start",
                              style: TextStyle(
                                fontFamily: 'Angsana New',
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHomeModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
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
                  // Top row with title and close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 36),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 248, 121, 178),
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
                        // Close button
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.pink.shade300),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      _buildModalListItem(context, 'ดอกบานไม่รู้โรย (Globe Amaranth)'),
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

  Widget _buildModalListItem(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
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
}

