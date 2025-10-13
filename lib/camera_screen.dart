import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';
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
  final DatabaseHelper _database = DatabaseHelper();
  bool _isApiReady = true;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    _initializeCamera();

    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final connected = await ApiService.testConnection();
        if (mounted) {
          setState(() {
            _isApiReady = connected;
          });
        }
        print(connected ? '✅ API connected' : '⚠️ API not available');
      } catch (e) {
        print('⚠️ API connection test error: $e');
        if (mounted) {
          setState(() {
            _isApiReady = false;
          });
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

  Future<void> _donePicture() async {
    if (_imagePath == null) return;

    if (!_isApiReady) {
      _showSnackBar('API ยังไม่พร้อม กรุณารอสักครู่');
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
                  'กำลังวิเคราะห์รูปภาพ...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Send image to API
      final result = await ApiService.recognizeFlower(_imagePath!);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // แสดง debug info
      print('📊 API Result:');
      print('  Success: ${result.success}');
      print('  FlowerName: ${result.flowerName}');
      print('  FlowerNameEn: ${result.flowerNameEn}');
      print('  Confidence: ${result.confidence}');
      print('  Message: ${result.message}');

      if (!result.success) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('ไม่พบดอกไม้'),
                content: Text(
                  result.message ??
                      'ไม่พบดอกไม้ในรูปภาพ\nลองปรับมุมกล้องหรือแสง',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('ตกลง'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // Check if flower name is available
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
                    child: const Text('ตกลง'),
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
                    child: const Text('ตกลง'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // Show success message - ✅ แก้ตรงนี้: ลบ * 100
      if (mounted) {
        final confidencePercent = (result.confidence ?? 0).toStringAsFixed(1);
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

      // บันทึกรูปที่ detect ไว้
      String? detectedImageBase64;
      try {
        final imageFile = File(_imagePath!);
        final imageBytes = await imageFile.readAsBytes();
        detectedImageBase64 = base64Encode(imageBytes);
        print('📸 Encoded detected image: ${imageBytes.length} bytes');
      } catch (e) {
        print('⚠️ Error encoding detected image: $e');
      }

      // บันทึกผล detection ลง database - ✅ ส่งค่า confidence โดยตรง (85.34)
      if (detectedImageBase64 != null) {
        try {
          await _database.saveDetectionResult(
            flowerName: flowerData.nameThai,
            detectedAt: DateTime.now(),
            confidence: result.confidence ?? 0.0, // ส่งค่าตรงๆ ไม่ต้องคูณ
            detectedImageBase64: detectedImageBase64,
          );
          print('✅ Detection result saved to database');
        } catch (e) {
          print('⚠️ Warning: Failed to save detection - $e');
        }
      }

      // สร้าง flower object สำหรับส่งไปหน้า detail
      final detectedFlower = flowerData.copyWith(
        detectedAt: DateTime.now(),
        confidence: result.confidence,
        updatedAt: DateTime.now(),
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
                  child: const Text('ตกลง'),
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

          // API status indicator
          if (!_isApiReady)
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
                      'Loading API...',
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
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Colors.pink,
                            size: 32,
                          ),
                          onPressed: _retakePicture,
                        ),
                        ElevatedButton(
                          onPressed: _isApiReady ? _donePicture : null,
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
                        IconButton(
                          icon: Icon(
                            Icons.photo_library,
                            color: Colors.pink.shade200,
                            size: 32,
                          ),
                          onPressed: _pickImageFromGallery,
                        ),
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

class CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const cornerLength = 30.0;

    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

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
