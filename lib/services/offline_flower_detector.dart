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
  static const int inputSize = 640;

  // 🎯 Confidence Threshold: ค่าความมั่นใจขั้นต่ำที่จะยอมรับผล (0.0 - 1.0)
  // ค่าสูง (0.5-0.9) = เข้มงวด, detect น้อย แต่แม่นกว่า
  // ค่าต่ำ (0.15-0.3) = ผ่อนปรน, detect เยอะ แต่อาจผิดบ้าง
  //
  // 💡 ปรับค่านี้ตามความต้องการ:
  // - 0.15 = detect ง่ายมาก (แนะนำถ้า model ไม่ค่อยแม่น)
  // - 0.25 = พอดี (ค่าปกติสำหรับ YOLOv8)
  // - 0.35 = ค่อนข้างเข้มงวด
  // - 0.50 = เข้มงวดมาก (ค่าเดิม)
  static const double confidenceThreshold = 0.15; // 👈 ปรับค่านี้

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

  bool _isInitialized = false;

  /// โหลด model และ labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🔄 Loading TFLite model...');

      final options = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = false;

      // ✅ เปลี่ยนเป็น float32
      _interpreter = await Interpreter.fromAsset(
        'asset/models/best_float32.tflite',
        options: options,
      );

      print('✅ Interpreter created');

      // โหลด labels
      final labelsData = await rootBundle.loadString('asset/models/labels.txt');
      _labels = labelsData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();

      // ตรวจสอบ input/output shape
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);

      print('✅ Model loaded successfully!');
      print('📊 Input shape: ${inputTensor.shape}');
      print('📊 Input type: ${inputTensor.type}');
      print('📊 Output shape: ${outputTensor.shape}');
      print('📊 Output type: ${outputTensor.type}');
      print('🏷️  Labels: ${_labels!.length} classes');

      // ทดสอบว่า model ใช้งานได้ไหม
      await _testModelInference();

      _isInitialized = true;
    } catch (e, stackTrace) {
      print('❌ Error loading model: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
      throw Exception('ไม่สามารถโหลด model ได้: $e');
    }
  }

  /// ทดสอบ inference ด้วยรูปปลอม
  Future<void> _testModelInference() async {
    try {
      print('🧪 Testing model inference...');

      final testImage = img.Image(width: inputSize, height: inputSize);
      img.fill(testImage, color: img.ColorRgb8(128, 128, 128));

      final input = _preprocessImage(testImage);
      final inputTensor = input.reshape([1, inputSize, inputSize, 3]);

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      print('📐 Output shape for test: $outputShape');

      final output = List.generate(
        outputShape[0],
        (_) => List.generate(
          outputShape[1],
          (_) => List.filled(outputShape[2], 0.0),
        ),
      );

      _interpreter!.run(inputTensor, output);

      print('✅ Model inference test passed!');
    } catch (e) {
      print('❌ Model inference test failed: $e');
      throw Exception('Model ใช้งานไม่ได้: $e');
    }
  }

  /// ตรวจจับดอกไม้
  Future<RecognitionResult> recognizeFlower(String imagePath) async {
    if (!_isInitialized) {
      await initialize();
    }

    final stopwatch = Stopwatch()..start();

    try {
      print('🌸 Starting flower detection...');
      print('📁 Image: $imagePath');

      // อ่านรูป
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

      // Preprocess
      final input = _preprocessImage(image);
      final preprocessTime = stopwatch.elapsedMilliseconds;
      print('⏱️  Preprocess: ${preprocessTime}ms');

      // Run inference with error handling
      List<dynamic> output;
      try {
        output = _runInference(input);
        final inferenceTime = stopwatch.elapsedMilliseconds - preprocessTime;
        print('🧠 Inference: ${inferenceTime}ms');
      } catch (e) {
        print('❌ Inference failed: $e');
        return RecognitionResult(
          success: false,
          message: 'ไม่สามารถประมวลผลได้: $e',
        );
      }

      // Postprocess
      final detections = _postProcess(output, image.width, image.height);
      final postprocessTime = stopwatch.elapsedMilliseconds - preprocessTime;
      print('🔍 Postprocess: ${postprocessTime}ms');

      stopwatch.stop();
      print('✨ Total time: ${stopwatch.elapsedMilliseconds}ms');
      print('🎯 Detections: ${detections.length}');

      if (detections.isEmpty) {
        return RecognitionResult(
          success: false,
          message: 'ไม่พบดอกไม้ในรูปภาพ\nลองปรับมุมกล้องหรือแสง',
        );
      }

      // เรียงและเลือกตัวที่ confidence สูงสุด
      detections.sort((a, b) => b.confidence.compareTo(a.confidence));
      final mainDetection = detections.first;

      final flowerNameEn = mainDetection.label;
      final flowerNameTh = flowerNamesTh[flowerNameEn] ?? flowerNameEn;

      // วาดกรอบ
      final annotatedImageBase64 = _drawDetectionsOnImage(image, detections);

      // สร้าง summary
      final Map<String, int> flowerCounts = {};
      for (var det in detections) {
        flowerCounts[det.label] = (flowerCounts[det.label] ?? 0) + 1;
      }

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
    } catch (e, stackTrace) {
      print('❌ Error: $e');
      print('Stack trace: $stackTrace');
      return RecognitionResult(success: false, message: 'เกิดข้อผิดพลาด: $e');
    }
  }

  /// วาดกรอบบนรูป
  String _drawDetectionsOnImage(img.Image image, List<Detection> detections) {
    final annotated = img.Image.from(image);

    final boxColor = img.ColorRgb8(255, 20, 147);
    final textColor = img.ColorRgb8(255, 255, 255);
    final bgColor = img.ColorRgb8(255, 20, 147);

    for (var detection in detections) {
      final x1 = detection.x1.toInt().clamp(0, image.width - 1);
      final y1 = detection.y1.toInt().clamp(0, image.height - 1);
      final x2 = detection.x2.toInt().clamp(0, image.width - 1);
      final y2 = detection.y2.toInt().clamp(0, image.height - 1);

      // วาดกรอบ
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

      // ข้อความ
      final flowerNameTh = flowerNamesTh[detection.label] ?? detection.label;
      final label =
          '$flowerNameTh ${(detection.confidence * 100).toStringAsFixed(0)}%';

      // พื้นหลังข้อความ
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

      // ข้อความ
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

  /// Preprocess image
  Float32List _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = Float32List(1 * inputSize * inputSize * 3);
    int pixelIndex = 0;

    // 🔄 ลองทั้ง 2 แบบ ดูว่าแบบไหนแม่นกว่า

    // ✅ แบบที่ 1: Normalization แบบธรรมดา (0-1) - Default YOLOv8
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    // 🔄 แบบที่ 2: ImageNet Normalization
    // ถ้าแบบแรกไม่แม่น ให้ comment แบบแรกออก แล้ว uncomment ด้านล่างนี้
    /*
    const imagenetMean = [0.485, 0.456, 0.406];
    const imagenetStd = [0.229, 0.224, 0.225];
    
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = (pixel.r / 255.0 - imagenetMean[0]) / imagenetStd[0];
        input[pixelIndex++] = (pixel.g / 255.0 - imagenetMean[1]) / imagenetStd[1];
        input[pixelIndex++] = (pixel.b / 255.0 - imagenetMean[2]) / imagenetStd[2];
      }
    }
    */

    print(
      '📊 Preprocessing: Normalization 0-1 (change to ImageNet if accuracy is low)',
    );

    return input;
  }

  /// Run inference
  List<dynamic> _runInference(Float32List input) {
    final inputTensor = input.reshape([1, inputSize, inputSize, 3]);

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.generate(
      outputShape[0],
      (_) => List.generate(
        outputShape[1],
        (_) => List.filled(outputShape[2], 0.0),
      ),
    );

    _interpreter!.run(inputTensor, output);

    return output[0];
  }

  /// Postprocess
  List<Detection> _postProcess(
    List<dynamic> output,
    int originalWidth,
    int originalHeight,
  ) {
    List<Detection> detections = [];

    final numClasses = output.length - 4;
    final numBoxes = output[0].length;

    // 🔍 Debug: ดู raw scores
    print('\n🔬 DEBUG - Top 5 raw predictions:');
    List<Map<String, dynamic>> allPredictions = [];

    for (int i = 0; i < numBoxes; i++) {
      double maxScore = 0;
      int classId = 0;

      for (int c = 0; c < numClasses; c++) {
        final score = output[4 + c][i].toDouble();
        if (score > maxScore) {
          maxScore = score;
          classId = c;
        }
      }

      if (maxScore > 0.1) {
        // แสดงทุกอันที่มากกว่า 10%
        allPredictions.add({
          'classId': classId,
          'className': _labels![classId],
          'score': maxScore,
        });
      }
    }

    // เรียงตาม score
    allPredictions.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );

    // แสดง top 5
    for (
      int i = 0;
      i < (allPredictions.length > 5 ? 5 : allPredictions.length);
      i++
    ) {
      final pred = allPredictions[i];
      print(
        '   ${i + 1}. ${pred['className']} - ${(pred['score'] * 100).toStringAsFixed(2)}%',
      );
    }
    print('');

    // Process detections ตามปกติ
    for (int i = 0; i < numBoxes; i++) {
      double x = output[0][i].toDouble();
      double y = output[1][i].toDouble();
      double w = output[2][i].toDouble();
      double h = output[3][i].toDouble();

      double maxScore = 0;
      int classId = 0;

      for (int c = 0; c < numClasses; c++) {
        final score = output[4 + c][i].toDouble();
        if (score > maxScore) {
          maxScore = score;
          classId = c;
        }
      }

      if (maxScore > confidenceThreshold) {
        final scaleX = originalWidth / inputSize;
        final scaleY = originalHeight / inputSize;

        final x1 = ((x - w / 2) * scaleX)
            .clamp(0.0, originalWidth.toDouble())
            .toDouble();
        final y1 = ((y - h / 2) * scaleY)
            .clamp(0.0, originalHeight.toDouble())
            .toDouble();
        final x2 = ((x + w / 2) * scaleX)
            .clamp(0.0, originalWidth.toDouble())
            .toDouble();
        final y2 = ((y + h / 2) * scaleY)
            .clamp(0.0, originalHeight.toDouble())
            .toDouble();

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

    return _applyNMS(detections);
  }

  /// NMS
  List<Detection> _applyNMS(List<Detection> detections) {
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    List<Detection> result = [];

    while (detections.isNotEmpty) {
      final best = detections.removeAt(0);
      result.add(best);

      detections.removeWhere((detection) {
        if (best.classId != detection.classId) return false;
        return _calculateIOU(best, detection) > iouThreshold;
      });
    }

    return result;
  }

  /// Calculate IOU
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
