import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class OfflineFlowerDetector {
  Interpreter? _interpreter;
  List<String>? _labels;

  // Model configuration
  static const int inputSize = 320; // ต้องตรงกับตอน export
  static const double confidenceThreshold = 0.6;
  static const double iouThreshold = 0.45;

  // ชื่อดอกไม้ภาษาไทย (เหมือนเดิม)
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

  bool _isInitialized = false;

  /// โหลด model และ labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔄 Loading TFLite model...');

      // โหลด model
      final options = InterpreterOptions()..threads = 4;

      // ถ้าต้องการใช้ GPU (ทดสอบดู)
      // options.addDelegate(GpuDelegateV2());

      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_int8.tflite',
        options: options,
      );

      // โหลด labels
      final labelsData = await rootBundle.loadString(
        'assets/models/labels.txt',
      );
      _labels = labelsData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();

      _isInitialized = true;

      print('✅ Model loaded successfully!');
      print('📊 Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('📊 Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      print('🏷️  Labels: ${_labels!.length} classes');
    } catch (e) {
      print('❌ Error loading model: $e');
      throw Exception('ไม่สามารถโหลด model ได้: $e');
    }
  }

  /// ตรวจจับดอกไม้พร้อมวาดกรอบ (แทน API call)
  Future<RecognitionResult> recognizeFlower(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    final stopwatch = Stopwatch()..start();

    try {
      print('🌸 Starting flower detection...');
      print('📁 Image: $imagePath');

      // 1. อ่านและ decode รูป
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('ไม่พบไฟล์รูปภาพ');
      }

      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('ไม่สามารถ decode รูปภาพได้');
      }

      print('🖼️  Image size: ${image.width}x${image.height}');

      // 2. Preprocess
      final input = _preprocessImage(image);
      final preprocessTime = stopwatch.elapsedMilliseconds;
      print('⏱️  Preprocess: ${preprocessTime}ms');

      // 3. Run inference
      final output = _runInference(input);
      final inferenceTime = stopwatch.elapsedMilliseconds - preprocessTime;
      print('🧠 Inference: ${inferenceTime}ms');

      // 4. Postprocess
      final detections = _postProcess(output, image.width, image.height);
      final postprocessTime =
          stopwatch.elapsedMilliseconds - inferenceTime - preprocessTime;
      print('🔍 Postprocess: ${postprocessTime}ms');

      stopwatch.stop();
      print('✨ Total time: ${stopwatch.elapsedMilliseconds}ms');
      print('🎯 Detections: ${detections.length}');

      // 5. สร้างผลลัพธ์
      if (detections.isEmpty) {
        return RecognitionResult(
          success: false,
          message: 'ไม่พบดอกไม้ในรูปภาพ\nลองปรับมุมกล้องหรือแสง',
        );
      }

      // เรียงตาม confidence แล้วเอาตัวแรก
      detections.sort((a, b) => b.confidence.compareTo(a.confidence));
      final mainDetection = detections.first;

      final flowerNameEn = mainDetection.label;
      final flowerNameTh = flowerNamesTh[flowerNameEn] ?? flowerNameEn;

      // 6. วาดกรอบและชื่อบนรูป
      final annotatedImageBase64 = _drawDetectionsOnImage(image, detections);

      // นับจำนวนแต่ละชนิด
      final Map<String, int> flowerCounts = {};
      for (var det in detections) {
        flowerCounts[det.label] = (flowerCounts[det.label] ?? 0) + 1;
      }

      // สร้าง summary
      final summary = flowerCounts.map(
        (key, value) => MapEntry(key, {
          'name_th': flowerNamesTh[key] ?? key,
          'count': value,
        }),
      );

      print('🌺 Main flower: $flowerNameTh ($flowerNameEn)');
      print(
        '📊 Confidence: ${(mainDetection.confidence * 100).toStringAsFixed(1)}%',
      );

      return RecognitionResult(
        success: true,
        flowerName: flowerNameTh,
        flowerNameEn: flowerNameEn,
        confidence: mainDetection.confidence,
        message: 'ตรวจจับดอกไม้สำเร็จ',
        totalFlowers: detections.length,
        allDetections: detections,
        summary: summary,
        inferenceTime: stopwatch.elapsedMilliseconds,
        annotatedImageBase64: annotatedImageBase64,
        detectedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error: $e');
      return RecognitionResult(success: false, message: 'เกิดข้อผิดพลาด: $e');
    }
  }

  /// วาดกรอบและชื่อดอกไม้บนรูป
  String _drawDetectionsOnImage(img.Image image, List<Detection> detections) {
    // สร้าง copy ของรูป
    final annotated = img.Image.from(image);

    // สีสำหรับวาด (ชมพูสดใส)
    final boxColor = img.ColorRgb8(255, 20, 147); // DeepPink
    final textColor = img.ColorRgb8(255, 255, 255); // White
    final bgColor = img.ColorRgb8(255, 20, 147); // DeepPink background

    for (var detection in detections) {
      final x1 = detection.x1.toInt();
      final y1 = detection.y1.toInt();
      final x2 = detection.x2.toInt();
      final y2 = detection.y2.toInt();

      // วาดกรอบ (หนา 3 pixel)
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

      // เตรียมข้อความ
      final flowerNameTh = flowerNamesTh[detection.label] ?? detection.label;
      final label =
          '$flowerNameTh ${(detection.confidence * 100).toStringAsFixed(0)}%';

      // วาดพื้นหลังข้อความ
      final textBgHeight = 25;
      img.fillRect(
        annotated,
        x1: x1,
        y1: y1 - textBgHeight,
        x2: x1 + (label.length * 8) + 10,
        y2: y1,
        color: bgColor,
      );

      // วาดข้อความ (ใช้ drawString)
      img.drawString(
        annotated,
        label,
        font: img.arial14,
        x: x1 + 5,
        y: y1 - textBgHeight + 5,
        color: textColor,
      );
    }

    // แปลงเป็น base64
    final png = img.encodePng(annotated);
    return base64Encode(png);
  }

  /// Preprocess image สำหรับ YOLOv8
  Float32List _preprocessImage(img.Image image) {
    // Resize to input size
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to Float32 [1, 320, 320, 3] และ normalize 0-1
    final input = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  /// Run model inference
  List<dynamic> _runInference(Float32List input) {
    // Reshape input
    final inputTensor = input.reshape([1, inputSize, inputSize, 3]);

    // Prepare output
    // YOLOv8 output: [1, 84, 8400] หรือ [1, num_classes+4, num_boxes]
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape[2], 0.0),
      ),
    );

    // Run inference
    _interpreter!.run(inputTensor, output);

    return output[0]; // [84, 8400]
  }

  /// Postprocess YOLOv8 output
  List<Detection> _postProcess(
    List<dynamic> output,
    int originalWidth,
    int originalHeight,
  ) {
    List<Detection> detections = [];

    // YOLOv8 output format: [num_classes+4, num_boxes]
    // First 4 rows: x_center, y_center, width, height
    // Remaining rows: class probabilities

    final numClasses = output.length - 4;
    final numBoxes = output[0].length;

    for (int i = 0; i < numBoxes; i++) {
      // Get box coordinates (normalized 0-1)
      double x = output[0][i].toDouble();
      double y = output[1][i].toDouble();
      double w = output[2][i].toDouble();
      double h = output[3][i].toDouble();

      // Get class with highest score
      double maxScore = 0;
      int classId = 0;

      for (int c = 0; c < numClasses; c++) {
        final score = output[4 + c][i].toDouble();
        if (score > maxScore) {
          maxScore = score;
          classId = c;
        }
      }

      // Filter by confidence
      if (maxScore > confidenceThreshold) {
        // Convert to original image coordinates
        final scaleX = originalWidth / inputSize;
        final scaleY = originalHeight / inputSize;

        // Convert from center format to corner format
        final x1 = (x - w / 2) * scaleX;
        final y1 = (y - h / 2) * scaleY;
        final x2 = (x + w / 2) * scaleX;
        final y2 = (y + h / 2) * scaleY;

        detections.add(
          Detection(
            x1: x1,
            y1: y1,
            x2: x2,
            y2: y2,
            confidence: maxScore,
            classId: classId,
            label: _labels![classId],
          ),
        );
      }
    }

    // Apply Non-Maximum Suppression
    return _applyNMS(detections);
  }

  /// Non-Maximum Suppression
  List<Detection> _applyNMS(List<Detection> detections) {
    // Sort by confidence (descending)
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    List<Detection> result = [];

    while (detections.isNotEmpty) {
      final best = detections.removeAt(0);
      result.add(best);

      // Remove overlapping boxes
      detections.removeWhere((detection) {
        if (best.classId != detection.classId) return false;
        return _calculateIOU(best, detection) > iouThreshold;
      });
    }

    return result;
  }

  /// Calculate Intersection over Union
  double _calculateIOU(Detection box1, Detection box2) {
    final x1 = box1.x1 > box2.x1 ? box1.x1 : box2.x1;
    final y1 = box1.y1 > box2.y1 ? box1.y1 : box2.y1;
    final x2 = box1.x2 < box2.x2 ? box1.x2 : box2.x2;
    final y2 = box1.y2 < box2.y2 ? box1.y2 : box2.y2;

    if (x2 < x1 || y2 < y1) return 0.0;

    final intersectionArea = (x2 - x1) * (y2 - y1);
    final box1Area = (box1.x2 - box1.x1) * (box1.y2 - box1.y1);
    final box2Area = (box2.x2 - box2.x1) * (box2.y2 - box2.y1);
    final unionArea = box1Area + box2Area - intersectionArea;

    return intersectionArea / unionArea;
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

/// Detection class
class Detection {
  final double x1, y1, x2, y2;
  final double confidence;
  final int classId;
  final String label;

  Detection({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.classId,
    required this.label,
  });

  @override
  String toString() {
    return 'Detection(label: $label, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
  }
}

/// Recognition Result (เหมือนเดิม แต่เพิ่มข้อมูล)
class RecognitionResult {
  final bool success;
  final String? flowerName;
  final String? flowerNameEn;
  final double? confidence;
  final String? message;
  final int? totalFlowers;
  final List<Detection>? allDetections;
  final Map<String, dynamic>? summary;
  final int? inferenceTime; // เวลาที่ใช้ (ms)
  final String? annotatedImageBase64; // รูปที่วาดกรอบแล้ว
  final DateTime? detectedAt; // วันที่-เวลาที่ detect

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
  });

  @override
  String toString() {
    if (!success) return 'RecognitionResult(success: false, message: $message)';
    return 'RecognitionResult(flower: $flowerName, confidence: ${(confidence! * 100).toStringAsFixed(1)}%, time: ${inferenceTime}ms)';
  }
}
