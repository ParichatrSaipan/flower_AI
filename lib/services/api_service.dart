import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String backendUrl =
      'https://cr2amx-flower-detector.hf.space/api/detect';

  /// ตรวจจับดอกไม้โดยใช้ YOLO model
  static Future<RecognitionResult> recognizeFlower(String imagePath) async {
    try {
      print('Starting flower recognition...');
      print('Image path: $imagePath');

      // อ่านไฟล์รูปภาพ
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found');
      }

      final imageBytes = await imageFile.readAsBytes();
      print('Image size: ${imageBytes.length} bytes');

      // แปลงเป็น base64
      final base64Image = base64Encode(imageBytes);
      print('Converted to base64');

      // สร้าง request body
      final requestBody = jsonEncode({
        'image': 'data:image/jpeg;base64,$base64Image',
        'confidence': 0.6, // ค่าความมั่นใจ (0.1-1.0)
      });

      print('Sending request to: $backendUrl');

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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(
          utf8.decode(response.bodyBytes),
        );

        if (result['success'] == true && result['api_result'] != null) {
          final apiResult = result['api_result'];

          if (apiResult['success'] == true &&
              apiResult['main_flower'] != null) {
            // ดึงข้อมูลดอกไม้
            final flowerNameTh = apiResult['main_flower']['name_th'];
            final flowerNameEn = apiResult['main_flower']['name_en'];
            final confidence = (apiResult['main_confidence'] ?? 0.0) / 100.0;

            print('Detected flower: $flowerNameTh ($flowerNameEn)');
            print('Confidence: ${(confidence * 100).toStringAsFixed(2)}%');

            return RecognitionResult(
              success: true,
              flowerName: flowerNameTh,
              flowerNameEn: flowerNameEn,
              message: 'ตรวจจับดอกไม้สำเร็จ',
              rawResults: apiResult,
            );
          } else {
            // ไม่พบดอกไม้
            final message = apiResult['message'] ?? 'ไม่พบดอกไม้ในรูปภาพ';
            print('No flower detected: $message');

            return RecognitionResult(success: false, message: message);
          }
        }

        return RecognitionResult(
          success: false,
          message: 'เกิดข้อผิดพลาดในการประมวลผล',
        );
      } else if (response.statusCode == 404) {
        throw Exception('ไม่พบ API endpoint กรุณาตรวจสอบ URL');
      } else if (response.statusCode == 500) {
        throw Exception('เกิดข้อผิดพลาดในเซิร์ฟเวอร์');
      } else {
        throw Exception('Backend error (status ${response.statusCode})');
      }
    } on SocketException catch (e) {
      print('Network error: $e');
      throw Exception(
        'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้\nกรุณาตรวจสอบ:\n1. เซิร์ฟเวอร์ทำงานอยู่หรือไม่\n2. URL ถูกต้องหรือไม่\n3. อินเทอร์เน็ตเชื่อมต่ออยู่หรือไม่',
      );
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      throw Exception('การประมวลผลใช้เวลานานเกินไป\nกรุณาลองใหม่อีกครั้ง');
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('ข้อมูลที่ได้รับจากเซิร์ฟเวอร์ไม่ถูกต้อง');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }

  /// ทดสอบการเชื่อมต่อกับเซิร์ฟเวอร์
  static Future<bool> testConnection() async {
    try {
      final baseUrl = backendUrl.replaceAll('/api/detect', '');
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}

/// ผลลัพธ์จากการตรวจจับดอกไม้
class RecognitionResult {
  final bool success;
  final String? flowerName; // ชื่อภาษาไทย
  final String? flowerNameEn; // ชื่อภาษาอังกฤษ
  final String? message;
  final Map<String, dynamic>? rawResults; // ข้อมูลเต็มจาก API

  RecognitionResult({
    required this.success,
    this.flowerName,
    this.flowerNameEn,
    this.message,
    this.rawResults,
  });

  @override
  String toString() {
    return 'RecognitionResult(success: $success, flowerName: $flowerName, ';
  }
}
