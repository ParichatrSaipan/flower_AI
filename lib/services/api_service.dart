import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ApiService {
  static const String backendUrl =
      'https://cr2amx-flower-detector.hf.space/api/detect';

  // ✅ แก้จาก 0.25 เป็น 0.6 (60%)
  static const double confidenceThreshold = 0.6;
  static const double iouThreshold = 0.45;

  static const Map<String, String> flowerNamesTh = {
    "carnation": "คาร์เนชั่น",
    "ixora": "ดอกเข็ม",
    "gerbera": "เยอบีร์า",
    "lotus": "ดอกบัว",
    "globe amaranth": "ดอกบานไม่รู้โรย",
    "orchid": "ดอกกล้วยไม้",
    "rose": "ดอกกุหลาบ",
    "gardenia augusta": "ดอกพุดซ้อน",
  };

  /// ตรวจจับดอกไม้โดยใช้ YOLO model ผ่าน API
  static Future<RecognitionResult> recognizeFlower(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    try {
      print('🌸 Starting flower detection via API...');
      print('📁 Image: $imagePath');

      // อ่านไฟล์รูปภาพ
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('ไม่พบไฟล์รูปภาพ');
      }

      final imageBytes = await imageFile.readAsBytes();
      print('📊 Original image size: ${imageBytes.length} bytes');

      // Decode และ resize รูปภาพ
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('ไม่สามารถ decode รูปภาพได้');
      }

      print('🖼️  Original dimensions: ${image.width}x${image.height}');

      // Resize เป็น 640px (เก็บ aspect ratio)
      img.Image resizedImage;
      if (image.width > 640 || image.height > 640) {
        resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? 640 : null,
          height: image.height > image.width ? 640 : null,
        );
        print('✨ Resized to: ${resizedImage.width}x${resizedImage.height}');
      } else {
        resizedImage = image;
      }

      // แปลงเป็น JPEG คุณภาพ 85%
      final jpegBytes = img.encodeJpg(resizedImage, quality: 85);
      print('📦 Compressed size: ${jpegBytes.length} bytes');

      // แปลงเป็น base64
      final base64Image = base64Encode(jpegBytes);
      print('✅ Converted to base64');

      // สร้าง request body
      final requestBody = jsonEncode({
        'image': base64Image,
        'confidence': confidenceThreshold, // ใช้ 0.6
      });

      print('📤 Sending request to: $backendUrl');
      print(
        '⚙️  Confidence threshold: ${(confidenceThreshold * 100).toStringAsFixed(0)}%',
      );

      // ส่ง request ไปยัง backend
      final response = await http
          .post(
            Uri.parse(backendUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      final apiTime = stopwatch.elapsedMilliseconds;
      print('📥 Response status: ${response.statusCode}');
      print('⏱️  API response time: ${apiTime}ms');

      if (response.statusCode == 200) {
        // Decode response
        final responseBody = utf8.decode(response.bodyBytes);
        print(
          '📄 Response body: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}...',
        );

        final Map<String, dynamic> result = json.decode(responseBody);

        // 🔍 Debug: แสดง structure ของ response
        print('🔍 Response structure:');
        print('  - success: ${result['success']}');
        print('  - message: ${result['message']}');
        print('  - detections: ${result['detections']?.length ?? 0}');

        // ตรวจสอบว่ามี detections หรือไม่
        if (result['success'] == true && result['detections'] != null) {
          final List<dynamic> detections = result['detections'];

          if (detections.isEmpty) {
            print('❌ No detections found');
            return RecognitionResult(
              success: false,
              message: 'ไม่พบดอกไม้ในรูปภาพ\nลองปรับมุมกล้องหรือแสง',
              detectedAt: DateTime.now(),
            );
          }

          // 🔍 Debug: ดู structure ของ detection แรก
          print('🔍 First detection structure:');
          print(json.encode(detections.first));

          // เรียงตาม confidence
          detections.sort(
            (a, b) =>
                (b['confidence'] as num).compareTo(a['confidence'] as num),
          );

          // ดอกไม้หลัก (confidence สูงสุด)
          final mainFlower = detections.first;

          // รองรับหลาย field names
          final flowerNameEn =
              (mainFlower['class'] ??
                      mainFlower['name'] ??
                      mainFlower['label'] ??
                      mainFlower['flower_name'] ??
                      mainFlower['name_en'] ??
                      '')
                  .toString()
                  .toLowerCase();

          final confidence = (mainFlower['confidence'] as num).toDouble();

          // confidence เป็น % แล้ว ไม่ต้องคูณ 100
          print(
            '🌺 Detected: $flowerNameEn (${confidence.toStringAsFixed(1)}%)',
          );

          // แปลงชื่อเป็นภาษาไทย (เอา [] ออก)
          String cleanFlowerName = flowerNameEn
              .replaceAll('[', '')
              .replaceAll(']', '')
              .trim();
          final flowerNameTh =
              flowerNamesTh[cleanFlowerName] ?? cleanFlowerName;

          // สร้าง Detection objects
          final detectionList = <Detection>[];
          for (var det in detections) {
            // รองรับทั้ง 'box' และ 'bbox'
            final bbox = det['box'] ?? det['bbox'];
            if (bbox != null && bbox is Map) {
              // ถ้าเป็น object {x1, y1, x2, y2}
              detectionList.add(
                Detection(
                  x1: (bbox['x1'] as num).toDouble(),
                  y1: (bbox['y1'] as num).toDouble(),
                  x2: (bbox['x2'] as num).toDouble(),
                  y2: (bbox['y2'] as num).toDouble(),
                  confidence: (det['confidence'] as num).toDouble(),
                  label: (det['name_en'] ?? det['class'] ?? det['label'] ?? '')
                      .toString()
                      .toLowerCase(),
                  labelTh:
                      det['name_th']?.toString() ??
                      flowerNamesTh[(det['name_en'] ?? '')
                          .toString()
                          .toLowerCase()] ??
                      '',
                ),
              );
            } else if (bbox != null && bbox is List && bbox.length >= 4) {
              // ถ้าเป็น array [x1, y1, x2, y2]
              String className =
                  (det['name_en'] ??
                          det['class'] ??
                          det['name'] ??
                          det['label'] ??
                          det['flower_name'] ??
                          '')
                      .toString()
                      .toLowerCase();

              // เอา [] ออก
              className = className
                  .replaceAll('[', '')
                  .replaceAll(']', '')
                  .trim();

              if (className.isEmpty) {
                print('⚠️ Warning: Detection has no class name, skipping...');
                continue;
              }

              detectionList.add(
                Detection(
                  x1: (bbox[0] as num).toDouble(),
                  y1: (bbox[1] as num).toDouble(),
                  x2: (bbox[2] as num).toDouble(),
                  y2: (bbox[3] as num).toDouble(),
                  confidence: (det['confidence'] as num).toDouble(),
                  label: className,
                  labelTh:
                      det['name_th']?.toString() ??
                      flowerNamesTh[className] ??
                      className,
                ),
              );
            }
          }

          // วาดกรอบบนรูป
          String? annotatedImageBase64;
          if (detectionList.isNotEmpty) {
            annotatedImageBase64 = _drawDetectionsOnImage(
              resizedImage,
              detectionList,
            );
            print('✅ Drew ${detectionList.length} bounding boxes');
          }

          // สร้าง summary
          final Map<String, dynamic> summary = {};
          final Map<String, int> flowerCounts = {};

          for (var det in detectionList) {
            final key = det.label.toLowerCase();
            flowerCounts[key] = (flowerCounts[key] ?? 0) + 1;
          }

          flowerCounts.forEach((key, value) {
            summary[key] = {
              'name_th': flowerNamesTh[key] ?? key,
              'count': value,
            };
          });

          stopwatch.stop();
          final totalTime = stopwatch.elapsedMilliseconds;

          print('✅ Main flower: $flowerNameTh ($flowerNameEn)');
          print('📊 Confidence: ${confidence.toStringAsFixed(1)}%');
          print('🎯 Total detections: ${detectionList.length}');
          print('✨ Total time: ${totalTime}ms');

          _printTopPredictions(detectionList);

          return RecognitionResult(
            success: true,
            flowerName: flowerNameTh,
            flowerNameEn: flowerNameEn,
            confidence: confidence,
            message: 'ตรวจจับดอกไม้สำเร็จ',
            totalFlowers: detectionList.length,
            allDetections: detectionList,
            summary: summary,
            inferenceTime: totalTime,
            annotatedImageBase64: annotatedImageBase64,
            detectedAt: DateTime.now(),
            rawResults: result,
          );
        } else {
          // ไม่มี detections
          final message =
              result['message'] ??
              'ไม่พบดอกไม้ในรูปภาพ\nลองปรับมุมกล้องหรือแสง';
          print('❌ Detection failed: $message');

          return RecognitionResult(
            success: false,
            message: message,
            detectedAt: DateTime.now(),
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('ไม่พบ API endpoint กรุณาตรวจสอบ URL');
      } else if (response.statusCode == 500) {
        throw Exception('เกิดข้อผิดพลาดในเซิร์ฟเวอร์');
      } else {
        throw Exception('Backend error (status ${response.statusCode})');
      }
    } on SocketException catch (e) {
      print('❌ Network error: $e');
      throw Exception('ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้');
    } on TimeoutException catch (e) {
      print('❌ Timeout error: $e');
      throw Exception('การประมวลผลใช้เวลานานเกินไป\nกรุณาลองใหม่อีกครั้ง');
    } on FormatException catch (e) {
      print('❌ Format error: $e');
      throw Exception('ข้อมูลที่ได้รับจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    } catch (e, stackTrace) {
      print('❌ Unexpected error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  static void _printTopPredictions(List<Detection> detections) {
    if (detections.isEmpty) return;

    print('\n🔬 DEBUG - Top predictions:');
    final sorted = List<Detection>.from(detections)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final topCount = sorted.length > 5 ? 5 : sorted.length;
    for (int i = 0; i < topCount; i++) {
      final det = sorted[i];
      print(
        '   ${i + 1}. ${det.labelTh} (${det.label}) - ${det.confidence.toStringAsFixed(2)}%',
      );
    }
    print('');
  }

  static String _drawDetectionsOnImage(
    img.Image image,
    List<Detection> detections,
  ) {
    final annotated = img.Image.from(image);
    final boxColor = img.ColorRgb8(255, 20, 147);
    final textColor = img.ColorRgb8(255, 255, 255);
    final bgColor = img.ColorRgb8(255, 20, 147);

    for (var detection in detections) {
      final x1 = detection.x1.toInt().clamp(0, image.width - 1);
      final y1 = detection.y1.toInt().clamp(0, image.height - 1);
      final x2 = detection.x2.toInt().clamp(0, image.width - 1);
      final y2 = detection.y2.toInt().clamp(0, image.height - 1);

      for (int i = 0; i < 3; i++) {
        img.drawRect(
          annotated,
          x1: x1 - i,
          y1: y1 - i,
          x2: x2 + i,
          y2: y2 + i,
          color: boxColor,
        );
      }

      final label =
          '${detection.labelTh} ${detection.confidence.toStringAsFixed(0)}%';
      final textBgHeight = 25;
      final textWidth = (label.length * 8) + 10;

      img.fillRect(
        annotated,
        x1: x1,
        y1: (y1 - textBgHeight).clamp(0, image.height - 1),
        x2: (x1 + textWidth).clamp(0, image.width - 1),
        y2: y1,
        color: bgColor,
      );

      img.drawString(
        annotated,
        label,
        font: img.arial14,
        x: x1 + 5,
        y: (y1 - textBgHeight + 5).clamp(0, image.height - 1),
        color: textColor,
      );
    }

    final png = img.encodePng(annotated);
    return base64Encode(png);
  }

  static Future<bool> testConnection() async {
    try {
      print('🔌 Testing server connection...');
      final baseUrl = backendUrl.replaceAll('/api/detect', '');
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));

      final connected = response.statusCode == 200;
      print(connected ? '✅ Server is reachable' : '❌ Server not responding');
      return connected;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}

class Detection {
  final double x1, y1, x2, y2;
  final double confidence;
  final String label;
  final String labelTh;

  Detection({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.label,
    required this.labelTh,
  });

  @override
  String toString() {
    return 'Detection(label: $labelTh ($label), confidence: ${confidence.toStringAsFixed(1)}%)';
  }
}

class RecognitionResult {
  final bool success;
  final String? flowerName;
  final String? flowerNameEn;
  final double? confidence;
  final String? message;
  final int? totalFlowers;
  final List<Detection>? allDetections;
  final Map<String, dynamic>? summary;
  final int? inferenceTime;
  final String? annotatedImageBase64;
  final DateTime? detectedAt;
  final Map<String, dynamic>? rawResults;

  RecognitionResult({
    required this.success,
    this.flowerName,
    this.flowerNameEn,
    this.confidence,
    this.message,
    this.totalFlowers,
    this.allDetections,
    this.summary,
    this.inferenceTime,
    this.annotatedImageBase64,
    this.detectedAt,
    this.rawResults,
  });

  @override
  String toString() {
    if (!success) return 'RecognitionResult(success: false, message: $message)';
    return 'RecognitionResult(flower: $flowerName, confidence: ${confidence!.toStringAsFixed(1)}%, time: ${inferenceTime}ms)';
  }
}
