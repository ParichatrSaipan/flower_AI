import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// ผลลัพธ์จากการตรวจจับดอกไม้
class RecognitionResult {
  final bool success;
  final String? flowerName; // ชื่อภาษาไทย
  final String? flowerNameEn; // ชื่อภาษาอังกฤษ
  final String? message;
  final String? resultText; // ข้อความผลลัพธ์ทั้งหมด
  final String? imageBase64; // รูปภาพที่มีกรอบ (base64)
  final int? totalFlowers; // จำนวนดอกไม้ทั้งหมด
  final Map<String, int>? flowerCounts; // นับจำนวนแต่ละชนิด

  RecognitionResult({
    required this.success,
    this.flowerName,
    this.flowerNameEn,
    this.message,
    this.resultText,
    this.imageBase64,
    this.totalFlowers,
    this.flowerCounts,
  });

  @override
  String toString() {
    return 'RecognitionResult(success: $success, flowerName: $flowerName, totalFlowers: $totalFlowers)';
  }
}

class ApiService {
  static const String baseUrl = 'https://cr2amx-flower-detector.hf.space';

  /// ชื่อดอกไม้ภาษาไทย
  static const Map<String, String> flowerNamesTh = {
    "carnation": "คาร์เนชั่น",
    "ixora": "ดอกเข็ม",
    "gerbera": "เยอบีร่า",
    "lotus": "ดอกบัว",
    "globe amaranth": "ดอกบานไม่รู้โรย",
    "orchid": "ดอกกล้วยไม้",
    "rose": "ดอกกุหลาบ",
    "gardenia augusta": "ดอกพุดซ้อน",
  };

  /// ฟังก์ชันส่งภาพไปให้โมเดลใน Hugging Face
  static Future<RecognitionResult> recognizeFlower(
    String imagePath, {
    double confidence = 0.3,
  }) async {
    try {
      final File imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        return RecognitionResult(success: false, message: 'ไม่พบไฟล์รูปภาพ');
      }

      // อ่านและแปลงภาพเป็น base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Image';

      print('🔄 กำลังส่งรูปภาพไปยัง API...');

      // ใช้ gradio_client predict API กับชื่อฟังก์ชันที่ถูกต้อง
      final response = await http
          .post(
            Uri.parse('$baseUrl/run/detect_flowers'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'data': [
                dataUrl, // image
                confidence, // confidence slider
              ],
            }),
          )
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw TimeoutException(
                'การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง',
              );
            },
          );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('📦 Response: $decoded');

        // Gradio จะส่งกลับมาใน format: {"data": [imageBase64, resultText]}
        final data = decoded['data'];

        if (data != null && data.length >= 2) {
          final String? annotatedImageData = data[0]; // รูปที่มีกรอบ
          final String resultText = data[1] ?? ''; // ข้อความผลลัพธ์

          // แยกข้อมูลจาก resultText
          final parsedResult = _parseResultText(resultText);

          return RecognitionResult(
            success: true,
            message: 'ตรวจจับสำเร็จ',
            resultText: resultText,
            imageBase64: annotatedImageData,
            totalFlowers: parsedResult['totalFlowers'],
            flowerCounts: parsedResult['flowerCounts'],
            flowerName: parsedResult['firstFlowerTh'],
            flowerNameEn: parsedResult['firstFlowerEn'],
          );
        } else {
          return RecognitionResult(
            success: false,
            message: 'ไม่พบดอกไม้ในรูปภาพ ลองปรับค่า Confidence',
          );
        }
      } else {
        return RecognitionResult(
          success: false,
          message:
              'เซิร์ฟเวอร์ตอบกลับ ${response.statusCode}: ${response.body}',
        );
      }
    } on SocketException {
      return RecognitionResult(
        success: false,
        message: 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้',
      );
    } on TimeoutException catch (e) {
      return RecognitionResult(
        success: false,
        message: e.message ?? 'หมดเวลาการเชื่อมต่อ',
      );
    } on FormatException {
      return RecognitionResult(
        success: false,
        message: 'รูปแบบข้อมูลไม่ถูกต้อง',
      );
    } catch (e) {
      print('❌ Error: $e');
      return RecognitionResult(
        success: false,
        message: 'เกิดข้อผิดพลาด: ${e.toString()}',
      );
    }
  }

  /// แยกข้อมูลจาก resultText
  static Map<String, dynamic> _parseResultText(String text) {
    final Map<String, dynamic> result = {
      'totalFlowers': 0,
      'flowerCounts': <String, int>{},
      'firstFlowerTh': null,
      'firstFlowerEn': null,
    };

    try {
      // ดึงจำนวนดอกไม้ทั้งหมด
      final totalMatch = RegExp(r'พบดอกไม้ทั้งหมด:\s*(\d+)').firstMatch(text);
      if (totalMatch != null) {
        result['totalFlowers'] = int.parse(totalMatch.group(1)!);
      }

      // ดึงรายการดอกไม้และจำนวน (เช่น "• ดอกกุหลาบ: 3 ดอก")
      final countMatches = RegExp(
        r'•\s*([^:]+):\s*(\d+)\s*ดอก',
      ).allMatches(text);

      Map<String, int> flowerCounts = {};
      String? firstFlowerTh;

      for (var match in countMatches) {
        final flowerTh = match.group(1)!.trim();
        final count = int.parse(match.group(2)!);

        flowerCounts[flowerTh] = count;

        if (firstFlowerTh == null) {
          firstFlowerTh = flowerTh;
        }
      }

      result['flowerCounts'] = flowerCounts;
      result['firstFlowerTh'] = firstFlowerTh;

      // หาชื่อภาษาอังกฤษจาก map
      if (firstFlowerTh != null) {
        result['firstFlowerEn'] = flowerNamesTh.entries
            .firstWhere(
              (entry) => entry.value == firstFlowerTh,
              orElse: () => const MapEntry('unknown', 'unknown'),
            )
            .key;
      }
    } catch (e) {
      print('⚠️ Error parsing result text: $e');
    }

    return result;
  }

  /// ทดสอบการเชื่อมต่อ API
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}
