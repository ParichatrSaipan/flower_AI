import 'dart:convert';

class Flower {
  final int? id; // ← เพิ่ม id จาก database
  final String day;
  final String nameThai;
  final String? nameEnglish;
  final String? imageUrl;
  final String? imageBase64;
  final Meanings meanings; // ← เปลี่ยนจาก FlowerMeanings เป็น Meanings
  final List<String>? useFor;
  final bool isFavorite;

  // ข้อมูลเพิ่มจาก Detection
  final DateTime? detectedAt;
  final double? confidence;
  final String? detectedImageBase64;
  final List<DetectionBox>? detectionBoxes;

  // Timestamps จาก database
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Flower({
    this.id,
    required this.day,
    required this.nameThai,
    this.nameEnglish,
    this.imageUrl,
    this.imageBase64,
    required this.meanings,
    this.useFor,
    this.isFavorite = false,
    this.detectedAt,
    this.confidence,
    this.detectedImageBase64,
    this.detectionBoxes,
    this.createdAt,
    this.updatedAt,
  });

  // fromJson สำหรับ JSON import (เดิม)
  factory Flower.fromJson(Map<String, dynamic> json) {
    return Flower(
      day: json['day'] ?? '',
      nameThai: json['nameThai'] ?? '',
      nameEnglish: json['nameEnglish'],
      imageUrl: json['imageUrl'],
      imageBase64: json['imageBase64'],
      meanings: Meanings.fromJson(json['meanings'] ?? {}),
      useFor: (json['useFor'] as List?)?.cast<String>(),
      isFavorite: json['isFavorite'] ?? false,
      detectedAt: json['detectedAt'] != null
          ? DateTime.parse(json['detectedAt'])
          : null,
      confidence: json['confidence']?.toDouble(),
      detectedImageBase64: json['detectedImageBase64'],
      detectionBoxes: (json['detectionBoxes'] as List?)
          ?.map((e) => DetectionBox.fromJson(e))
          .toList(),
    );
  }

  // fromMap สำหรับ SQLite (ใช้กับ DatabaseHelper)
  factory Flower.fromMap(Map<String, dynamic> map) {
    // Parse colorMeanings from JSON string
    List<FlowerTypeMeanning>? colorMeanings;
    if (map['colorMeanings'] != null && map['colorMeanings'] is String) {
      try {
        final decoded = json.decode(map['colorMeanings']);
        colorMeanings = (decoded as List)
            .map((e) => FlowerTypeMeanning.fromJson(e))
            .toList();
      } catch (e) {
        print('Error parsing colorMeanings: $e');
      }
    }

    // Parse useFor from JSON string
    List<String>? useFor;
    if (map['useFor'] != null && map['useFor'] is String) {
      try {
        final decoded = json.decode(map['useFor']);
        useFor = (decoded as List).cast<String>();
      } catch (e) {
        print('Error parsing useFor: $e');
      }
    }

    // Parse detectionBoxes from JSON string
    List<DetectionBox>? detectionBoxes;
    if (map['detectionBoxes'] != null && map['detectionBoxes'] is String) {
      try {
        final decoded = json.decode(map['detectionBoxes']);
        detectionBoxes = (decoded as List)
            .map((e) => DetectionBox.fromJson(e))
            .toList();
      } catch (e) {
        print('Error parsing detectionBoxes: $e');
      }
    }

    return Flower(
      id: map['id'],
      day: map['day'] ?? '',
      nameThai: map['nameThai'] ?? '',
      nameEnglish: map['nameEnglish'],
      imageUrl: map['imageUrl'],
      imageBase64: map['imageBase64'],
      meanings: Meanings(
        colorMeanings: colorMeanings,
        other: map['otherMeanings'],
      ),
      useFor: useFor,
      isFavorite: map['isFavorite'] == 1,
      detectedAt: map['detectedAt'] != null
          ? DateTime.parse(map['detectedAt'])
          : null,
      confidence: map['confidence']?.toDouble(),
      detectedImageBase64: map['detectedImageBase64'],
      detectionBoxes: detectionBoxes,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  // toMap สำหรับ SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'day': day,
      'nameThai': nameThai,
      'nameEnglish': nameEnglish,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'colorMeanings': meanings.colorMeanings != null
          ? json.encode(meanings.colorMeanings!.map((e) => e.toJson()).toList())
          : null,
      'otherMeanings': meanings.other,
      'useFor': useFor != null ? json.encode(useFor) : null,
      'isFavorite': isFavorite ? 1 : 0,
      'detectedAt': detectedAt?.toIso8601String(),
      'confidence': confidence,
      'detectedImageBase64': detectedImageBase64,
      'detectionBoxes': detectionBoxes != null
          ? json.encode(detectionBoxes!.map((e) => e.toJson()).toList())
          : null,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'day': day,
      'nameThai': nameThai,
      'nameEnglish': nameEnglish,
      'imageUrl': imageUrl,
      'imageBase64': imageBase64,
      'meanings': meanings.toJson(),
      'useFor': useFor,
      'isFavorite': isFavorite,
      'detectedAt': detectedAt?.toIso8601String(),
      'confidence': confidence,
      'detectedImageBase64': detectedImageBase64,
      'detectionBoxes': detectionBoxes?.map((e) => e.toJson()).toList(),
    };
  }

  Flower copyWith({
    int? id,
    String? day,
    String? nameThai,
    String? nameEnglish,
    String? imageUrl,
    String? imageBase64,
    Meanings? meanings,
    List<String>? useFor,
    bool? isFavorite,
    DateTime? detectedAt,
    double? confidence,
    String? detectedImageBase64,
    List<DetectionBox>? detectionBoxes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flower(
      id: id ?? this.id,
      day: day ?? this.day,
      nameThai: nameThai ?? this.nameThai,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      meanings: meanings ?? this.meanings,
      useFor: useFor ?? this.useFor,
      isFavorite: isFavorite ?? this.isFavorite,
      detectedAt: detectedAt ?? this.detectedAt,
      confidence: confidence ?? this.confidence,
      detectedImageBase64: detectedImageBase64 ?? this.detectedImageBase64,
      detectionBoxes: detectionBoxes ?? this.detectionBoxes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// เปลี่ยนชื่อจาก FlowerMeanings เป็น Meanings (ตรงกับ database)
class Meanings {
  final List<FlowerTypeMeanning>? colorMeanings;
  final String? other;

  Meanings({this.colorMeanings, this.other});

  factory Meanings.fromJson(Map<String, dynamic> json) {
    return Meanings(
      colorMeanings: (json['colorMeanings'] as List?)
          ?.map((e) => FlowerTypeMeanning.fromJson(e))
          .toList(),
      other: json['other'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colorMeanings': colorMeanings?.map((e) => e.toJson()).toList(),
      'other': other,
    };
  }
}

class FlowerTypeMeanning {
  final String color;
  final String meaning;

  FlowerTypeMeanning({required this.color, required this.meaning});

  factory FlowerTypeMeanning.fromJson(Map<String, dynamic> json) {
    return FlowerTypeMeanning(
      color: json['color'] ?? '',
      meaning: json['meaning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'color': color, 'meaning': meaning};
  }
}

// กรอบของการ detect แต่ละตัว
class DetectionBox {
  final double x1, y1, x2, y2;
  final String label;
  final double confidence;

  DetectionBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.label,
    required this.confidence,
  });

  factory DetectionBox.fromJson(Map<String, dynamic> json) {
    return DetectionBox(
      x1: json['x1'].toDouble(),
      y1: json['y1'].toDouble(),
      x2: json['x2'].toDouble(),
      y2: json['y2'].toDouble(),
      label: json['label'],
      confidence: json['confidence'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
      'label': label,
      'confidence': confidence,
    };
  }
}
