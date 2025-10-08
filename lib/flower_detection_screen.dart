import 'dart:io';
import 'package:florasign_ai/services/offline_flower_detector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/database_helper.dart';
import 'models/flower.dart';
import 'flower_detail_screen.dart';

class FlowerDetectionScreen extends StatefulWidget {
  const FlowerDetectionScreen({Key? key}) : super(key: key);

  @override
  State<FlowerDetectionScreen> createState() => _FlowerDetectionScreenState();
}

class _FlowerDetectionScreenState extends State<FlowerDetectionScreen> {
  final OfflineFlowerDetector _detector = OfflineFlowerDetector();
  final DatabaseHelper _database = DatabaseHelper();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isLoading = false;
  String _statusText = 'กำลังเตรียมระบบ...';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  /// เตรียมระบบ: โหลด model + database
  Future<void> _initializeSystem() async {
    setState(() {
      _statusText = 'กำลังโหลด AI model...';
    });

    try {
      // โหลด detector และรอ database พร้อม
      await _detector.initialize();

      // Database จะ auto-load จาก JSON ตอน first run
      final dbInfo = await _database.getDatabaseInfo();
      print('📊 Database info: $dbInfo');

      setState(() {
        _isInitialized = true;
        _statusText = 'พร้อมใช้งาน! 📸 เลือกรูปเพื่อเริ่มต้น';
      });

      print('✅ System ready!');
    } catch (e) {
      setState(() {
        _statusText = 'เกิดข้อผิดพลาด: $e';
      });
      print('❌ Initialization error: $e');
    }
  }

  /// เลือกรูปจากแหล่งที่มา
  Future<void> _pickImage(ImageSource source) async {
    if (!_isInitialized) {
      _showSnackBar('กรุณารอระบบโหลดเสร็จก่อน');
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
        _isLoading = true;
        _statusText = '🔍 กำลังวิเคราะห์รูปภาพ...';
      });

      // Detect ดอกไม้
      await _detectAndNavigate(image.path);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = 'เกิดข้อผิดพลาด: $e';
      });
      _showSnackBar('เกิดข้อผิดพลาดในการเลือกรูป');
    }
  }

  /// Detect และไปหน้า Detail
  Future<void> _detectAndNavigate(String imagePath) async {
    try {
      // 1. Detect ดอกไม้
      final result = await _detector.recognizeFlower(imagePath);

      setState(() {
        _isLoading = false;
      });

      if (!result.success) {
        setState(() {
          _statusText = result.message ?? 'ไม่พบดอกไม้';
        });
        _showSnackBar('ไม่พบดอกไม้ในรูป กรุณาลองใหม่');
        return;
      }

      // 2. ค้นหาข้อมูลดอกไม้จาก database
      final flowerData = await _database.findByDetectedName(
        result.flowerNameEn!,
      );

      if (flowerData == null) {
        setState(() {
          _statusText = 'ตรวจพบ: ${result.flowerName}\nแต่ไม่พบข้อมูลในระบบ';
        });
        _showSnackBar('ไม่พบข้อมูลดอกไม้ในฐานข้อมูล');
        return;
      }

      // 3. บันทึกผลการ detect ลง database
      await _database.saveDetectionResult(
        flowerName: flowerData.nameThai,
        detectedAt: result.detectedAt!,
        confidence: result.confidence!,
        detectedImageBase64: result.annotatedImageBase64!,
        detectionBoxes: result.allDetections
            ?.map(
              (det) => {
                'x1': det.x1,
                'y1': det.y1,
                'x2': det.x2,
                'y2': det.y2,
                'label': det.label,
                'confidence': det.confidence,
              },
            )
            .toList(),
      );

      print('✅ Detection saved to database');

      // 4. สร้าง Flower object พร้อมข้อมูล detection
      final detectedFlower = flowerData.copyWith(
        detectedAt: result.detectedAt,
        confidence: result.confidence,
        detectedImageBase64: result.annotatedImageBase64,
        detectionBoxes: result.allDetections
            ?.map(
              (det) => DetectionBox(
                x1: det.x1,
                y1: det.y1,
                x2: det.x2,
                y2: det.y2,
                label: det.label,
                confidence: det.confidence,
              ),
            )
            .toList(),
      );

      // 5. ไปหน้า Detail
      if (!mounted) return;

      await Navigator.push<Flower>(
        context,
        MaterialPageRoute(
          builder: (context) => FlowerDetailScreen(flower: detectedFlower),
        ),
      );

      // 6. รีเซ็ตหน้าจอ
      setState(() {
        _selectedImage = null;
        _statusText = 'พร้อมใช้งาน! 📸 เลือกรูปเพื่อเริ่มต้น';
      });

      print('✅ Detection completed successfully!');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = 'เกิดข้อผิดพลาด: $e';
      });
      _showSnackBar('เกิดข้อผิดพลาด: $e');
      print('❌ Detection error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF94B7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '🌸 ตรวจจับดอกไม้',
          style: TextStyle(fontFamily: 'Kanit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF94B7),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFF1F7),
            child: Column(
              children: [
                Text(
                  _statusText,
                  style: const TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!_isInitialized && !_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: CircularProgressIndicator(color: Color(0xFFFF94B7)),
                  ),
              ],
            ),
          ),

          // Image preview area
          Expanded(child: _buildImagePreview()),

          // Action buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 28),
                      label: const Text(
                        'ถ่ายรูป',
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF94B7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 28),
                      label: const Text(
                        'เลือกรูป',
                        style: TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF94B7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
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
  }

  Widget _buildImagePreview() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFFF94B7),
              strokeWidth: 4,
            ),
            const SizedBox(height: 20),
            Text(
              _statusText,
              style: const TextStyle(
                fontFamily: 'Kanit',
                fontSize: 16,
                color: Color(0xFF5A4A52),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedImage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(_selectedImage!, fit: BoxFit.contain),
          ),
        ),
      );
    }

    // Placeholder
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_florist, size: 120, color: Colors.pink.shade200),
          const SizedBox(height: 20),
          const Text(
            'เลือกรูปดอกไม้\nเพื่อเริ่มตรวจจับ',
            style: TextStyle(
              fontFamily: 'Kanit',
              fontSize: 20,
              color: Color(0xFFA4798D),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F7),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFFF94B7), width: 2),
            ),
            child: const Column(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFFF94B7), size: 32),
                SizedBox(height: 8),
                Text(
                  'คำแนะนำ',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A4A52),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• ถ่ายรูปดอกไม้ให้ชัดเจน\n'
                  '• หลีกเลี่ยงแสงสะท้อน\n'
                  '• ดอกไม้ควรเต็มกรอบ\n'
                  '• พื้นหลังไม่รกเกินไป',
                  style: TextStyle(
                    fontFamily: 'Kanit',
                    fontSize: 14,
                    color: Color(0xFF5A4A52),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }
}
