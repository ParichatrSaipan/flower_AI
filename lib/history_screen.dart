import 'dart:convert';
import 'dart:typed_data';
import 'package:florasign_ai/flower_detail_screen.dart';
import 'package:florasign_ai/models/flower.dart';
import 'package:florasign_ai/services/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// import 'services/database_helper.dart';
// import 'models/flower.dart';
// import 'screens/flower_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _database = DatabaseHelper();
  List<Flower> _detectionHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th', null);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // ดึงประวัติการ detect ล่าสุด
      final history = await _database.getRecentDetections(limit: 50);

      setState(() {
        _detectionHistory = history;
        _isLoading = false;
      });

      print('📜 Loaded ${history.length} detection history');
    } catch (e) {
      print('❌ Error loading history: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC0CB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'history',
          style: TextStyle(
            fontFamily: 'Kanit',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            onPressed: () {
              // Navigate to favorites
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF94B7)),
      );
    }

    if (_detectionHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 100, color: Colors.pink.shade200),
            const SizedBox(height: 20),
            const Text(
              'ยังไม่มีประวัติการตรวจจับ',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 18,
                color: Color(0xFFA4798D),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ถ่ายรูปดอกไม้เพื่อเริ่มต้น',
              style: TextStyle(
                fontFamily: 'Kanit',
                fontSize: 14,
                color: Color(0xFFA4798D),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFFFF94B7),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _detectionHistory.length,
        itemBuilder: (context, index) {
          final flower = _detectionHistory[index];
          return _buildHistoryItem(flower);
        },
      ),
    );
  }

  Widget _buildHistoryItem(Flower flower) {
    // Format วันที่-เวลา
    final dateFormat = DateFormat('dd/MM/yyyy', 'th');
    final timeFormat = DateFormat('HH:mm', 'th');
    final detectedDate = flower.detectedAt != null
        ? dateFormat.format(flower.detectedAt!)
        : '-';
    final detectedTime = flower.detectedAt != null
        ? timeFormat.format(flower.detectedAt!)
        : '-';

    // Decode รูปต้นฉบับ (imageBase64 = รูปจาก assets)
    Uint8List? originalImageBytes;
    if (flower.imageBase64 != null && flower.imageBase64!.isNotEmpty) {
      try {
        originalImageBytes = base64Decode(flower.imageBase64!);
      } catch (e) {
        print('Error decoding original image: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F7),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showDetectedImageDialog(flower),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // รูปต้นฉบับ (รูปที่ถ่าย)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: originalImageBytes != null
                        ? Image.memory(originalImageBytes, fit: BoxFit.cover)
                        : const Icon(
                            Icons.local_florist,
                            size: 40,
                            color: Color(0xFFA4798D),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // ข้อมูลดอกไม้
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อดอกไม้
                      Text(
                        flower.nameThai,
                        style: const TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A4A52),
                        ),
                      ),
                      if (flower.nameEnglish != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          flower.nameEnglish!,
                          style: const TextStyle(
                            fontFamily: 'Kanit',
                            fontSize: 13,
                            color: Color(0xFFA4798D),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // วันที่และเวลา
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Color(0xFFA4798D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            detectedDate,
                            style: const TextStyle(
                              fontFamily: 'Kanit',
                              fontSize: 13,
                              color: Color(0xFF5A4A52),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Color(0xFFA4798D),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            detectedTime,
                            style: const TextStyle(
                              fontFamily: 'Kanit',
                              fontSize: 13,
                              color: Color(0xFF5A4A52),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ไอคอนกดดูรูป
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF94B7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// แสดง popup รูปที่มีกรอบ detection
  void _showDetectedImageDialog(Flower flower) {
    // Decode รูปที่ detect แล้ว (มีกรอบ)
    Uint8List? detectedImageBytes;
    if (flower.detectedImageBase64 != null &&
        flower.detectedImageBase64!.isNotEmpty) {
      try {
        detectedImageBytes = base64Decode(flower.detectedImageBase64!);
      } catch (e) {
        print('Error decoding detected image: $e');
      }
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              // รูปที่มีกรอบ
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: detectedImageBytes != null
                        ? Image.memory(detectedImageBytes, fit: BoxFit.contain)
                        : Container(
                            color: const Color(0xFFFFF1F7),
                            child: const Center(
                              child: Icon(
                                Icons.local_florist,
                                size: 100,
                                color: Color(0xFFA4798D),
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // ปุ่มปิด
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF94B7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

              // ข้อมูลดอกไม้ด้านล่าง
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flower.nameThai,
                        style: const TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (flower.nameEnglish != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          flower.nameEnglish!,
                          style: const TextStyle(
                            fontFamily: 'Kanit',
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                      if (flower.confidence != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.greenAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ความมั่นใจ: ${(flower.confidence! * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontFamily: 'Kanit',
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      // ปุ่มดูรายละเอียด
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // ปิด dialog
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FlowerDetailScreen(flower: flower),
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text(
                            'ดูรายละเอียด',
                            style: TextStyle(
                              fontFamily: 'Kanit',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF94B7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
