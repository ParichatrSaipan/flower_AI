import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'services/offline_flower_detector.dart';
import 'services/database_helper.dart';
import 'models/flower.dart';
import 'flower_detail_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription>? cameras;
  String? _imagePath;
  bool _isInitialized = false;
  final ImagePicker _picker = ImagePicker();
  final OfflineFlowerDetector _detector = OfflineFlowerDetector();
  final DatabaseHelper _database = DatabaseHelper();
  bool _isDetectorReady = false;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    // Initialize camera first
    _initializeCamera();

    // Initialize detector after a short delay
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        await _detector.initialize();
        if (mounted) {
          setState(() {
            _isDetectorReady = true;
          });
        }
        print('✅ Detector initialized');
      } catch (e) {
        print('❌ Detector initialization error: $e');
        if (mounted) {
          _showSnackBar('ไม่สามารถโหลด AI model ได้: $e');
        }
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _controller = CameraController(cameras![0], ResolutionPreset.high);
        _initializeControllerFuture = _controller!.initialize();
        await _initializeControllerFuture;
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      setState(() {
        _imagePath = image.path;
      });
      print('Picture saved to: ${image.path}');
    } catch (e) {
      print('Error taking picture: $e');
    }
  }

  void _retakePicture() {
    setState(() {
      _imagePath = null;
    });
  }

  // ✅ แก้ส่วน _donePicture() ตรงบรรทัด 180-230
  Future<void> _donePicture() async {
    if (_imagePath == null) return;

    if (!_isDetectorReady) {
      _showSnackBar('กรุณารอระบบโหลดเสร็จก่อน');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.pink.shade300),
                const SizedBox(height: 16),
                const Text(
                  '🔍 กำลังวิเคราะห์รูปภาพ...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Use offline detector instead of API
      final result = await _detector.recognizeFlower(_imagePath!);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (!result.success) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('ไม่พบดอกไม้'),
                content: Text(
                  result.message ?? 'ไม่พบดอกไม้ในรูป กรุณาลองใหม่',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // ✅ เพิ่ม null check
      if (result.flowerNameEn == null || result.flowerNameEn!.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('เกิดข้อผิดพลาด'),
                content: const Text('ไม่สามารถระบุชื่อดอกไม้ได้'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // Search in local database using detected name
      final flowerData = await _database.findByDetectedName(
        result.flowerNameEn!,
      );

      if (flowerData == null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('ไม่พบข้อมูล'),
                content: Text(
                  'ตรวจพบ: ${result.flowerName ?? result.flowerNameEn}\nแต่ไม่พบข้อมูลในฐานข้อมูล',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // Show success message
      if (mounted) {
        final confidencePercent = ((result.confidence ?? 0) * 100)
            .toStringAsFixed(1);
        print('✅ FINAL RESULT: ${flowerData.nameThai} ($confidencePercent%)');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ตรวจพบ: ${flowerData.nameThai} ($confidencePercent%)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Save detection result to database
      try {
        // ✅ ตรวจสอบว่ามีข้อมูลครบก่อนบันทึก
        if (result.annotatedImageBase64 != null &&
            result.annotatedImageBase64!.isNotEmpty &&
            result.detectedAt != null &&
            result.confidence != null) {
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
        } else {
          print(
            '⚠️ Warning: Incomplete detection data, not saving to database',
          );
        }
      } catch (e) {
        print('⚠️ Warning: Detection data not saved - $e');
      }

      // Create flower object with detection data
      // ✅ ให้ค่าเป็น null ได้ถ้าไม่มีข้อมูล
      final detectedFlower = flowerData.copyWith(
        detectedAt: result.detectedAt,
        confidence: result.confidence,
        detectedImageBase64: result.annotatedImageBase64, // อาจเป็น null
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

      // Navigate to flower detail screen
      if (mounted) {
        Navigator.pop(context); // Close camera screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlowerDetailScreen(flower: detectedFlower),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Close loading dialog if still open
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }

      // Show error message
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('เกิดข้อผิดพลาด'),
              content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      print('❌ Detection error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
        print('Image picked from gallery: ${image.path}');
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.pink.shade300,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview or captured image
          if (_imagePath != null)
            Center(child: Image.file(File(_imagePath!), fit: BoxFit.contain))
          else if (_isInitialized && _controller != null)
            Center(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Overlay frame (only show when taking photo)
          if (_imagePath == null && _isInitialized)
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomPaint(painter: CornerPainter()),
              ),
            ),

          // Close button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // Detector status indicator (top right)
          if (!_isDetectorReady)
            Positioned(
              top: 40,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading AI...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              color: Colors.white,
              child: _imagePath != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Retake button
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.pink,
                            size: 32,
                          ),
                          onPressed: _retakePicture,
                        ),
                        // Done button
                        ElevatedButton(
                          onPressed: _isDetectorReady ? _donePicture : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade300,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'DONE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery button
                        IconButton(
                          icon: Icon(
                            Icons.photo_library,
                            color: Colors.pink.shade200,
                            size: 32,
                          ),
                          onPressed: _pickImageFromGallery,
                        ),
                        // Capture button
                        GestureDetector(
                          onTap: _isInitialized ? _takePicture : null,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        // Placeholder
                        Container(width: 32, height: 32),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for corner brackets
class CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-right corner
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

    // Bottom-left corner
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

    // Bottom-right corner
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
