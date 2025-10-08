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

  Future<void> _initializeSystem() async {
    setState(() {
      _statusText = 'กำลังโหลด AI model...';
    });

    try {
      await _detector.initialize();
      final dbInfo = await _database.getDatabaseInfo();
      print('📊 Database info: $dbInfo');

      setState(() {
        _isInitialized = true;
        _statusText = 'พร้อมใช้งาน!';
      });

      print('✅ System ready!');
    } catch (e) {
      setState(() {
        _statusText = 'เกิดข้อผิดพลาด: $e';
      });
      print('❌ Initialization error: $e');
    }
  }

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

      await _detectAndNavigate(image.path);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = 'เกิดข้อผิดพลาด: $e';
      });
      _showSnackBar('เกิดข้อผิดพลาดในการเลือกรูป');
    }
  }

  Future<void> _detectAndNavigate(String imagePath) async {
    try {
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

      try {
        final boxesData = result.allDetections
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
            .toList();

        await _database.saveDetectionResult(
          flowerName: flowerData.nameThai,
          detectedAt: result.detectedAt!,
          confidence: result.confidence!,
          detectedImageBase64: result.annotatedImageBase64!,
          detectionBoxes: boxesData,
        );

        print('✅ Detection saved to database');
      } catch (e) {
        print('⚠️ Warning: Detection data not saved - $e');
      }

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

      if (!mounted) return;

      await Navigator.push<Flower>(
        context,
        MaterialPageRoute(
          builder: (context) => FlowerDetailScreen(flower: detectedFlower),
        ),
      );

      setState(() {
        _selectedImage = null;
        _statusText = 'พร้อมใช้งาน!';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'ตรวจจับดอกไม้',
          style: TextStyle(
            fontFamily: 'Kanit',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background
          Container(color: Colors.black),

          // Image preview or placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Camera frame / Image preview
                if (_selectedImage != null)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: 300,
                        height: 350,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 300,
                    height: 350,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: CustomPaint(painter: CornerPainter()),
                  ),

                const SizedBox(height: 30),

                // Status text
                if (_isLoading)
                  Column(
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFFFF94B7),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _statusText,
                        style: const TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                else if (!_isInitialized)
                  Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFFF94B7)),
                      const SizedBox(height: 16),
                      Text(
                        _statusText,
                        style: const TextStyle(
                          fontFamily: 'Kanit',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    _statusText,
                    style: const TextStyle(
                      fontFamily: 'Kanit',
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _selectedImage != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Retake button
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFFFF94B7),
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                              _statusText = 'พร้อมใช้งาน!';
                            });
                          },
                        ),
                        // Done button
                        ElevatedButton(
                          onPressed: _isLoading ? null : () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF94B7),
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'ยืนยัน',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Kanit',
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery button
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library,
                                color: _isLoading ? Colors.grey : Colors.black,
                                size: 36,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'เลือกรูป',
                                style: TextStyle(
                                  fontFamily: 'Kanit',
                                  fontSize: 12,
                                  color: _isLoading
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Capture button
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => _pickImage(ImageSource.camera),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: _isLoading
                                  ? Colors.grey
                                  : const Color(0xFFFF94B7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                        // Placeholder
                        const SizedBox(width: 60),
                      ],
                    ),
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

// Corner painter for camera frame
class CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(
      Offset(size.width - cornerLength, 0),
      Offset(size.width, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(0, size.height - cornerLength),
      Offset(0, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLength, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(size.width - cornerLength, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - cornerLength),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
