import 'dart:convert';

class Flower {
  final int? id; // Local database ID
  final String? day; // วันเกิด (optional)
  final String nameThai;
  final String nameEnglish;
  final String? imageUrl;
  final Meanings meanings;
  final List<String>? useFor;
  final bool isFavorite;
  final String? imageBase64; // For storing cached images locally

  // ข้อมูลเพิ่มจาก Detection
  final DateTime? detectedAt;
  final double? confidence;
  final String? detectedImageBase64;
  final List<DetectionBox>? detectionBoxes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Flower({
    this.id,
    this.day,
    required this.nameThai,
    required this.nameEnglish,
    this.imageUrl,
    required this.meanings,
    this.useFor,
    this.isFavorite = false,
    this.imageBase64,
    this.detectedAt,
    this.confidence,
    this.detectedImageBase64,
    this.detectionBoxes,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON (for API responses)
  factory Flower.fromJson(Map<String, dynamic> json) {
    return Flower(
      day: json['day']?.toString(),
      nameThai: json['nameThai'] ?? '',
      nameEnglish: json['nameEnglish'] ?? '',
      imageUrl: json['imageUrl'],
      meanings: json['meanings'] != null
          ? Meanings.fromJson(json['meanings'])
          : Meanings(colorMeanings: null, other: null),
      useFor: json['useFor'] != null ? List<String>.from(json['useFor']) : null,
      isFavorite: json['isFavorite'] ?? false,
      imageBase64: json['imageBase64'],
      detectedAt: json['detectedAt'] != null
          ? DateTime.parse(json['detectedAt'])
          : null,
      confidence: json['confidence']?.toDouble(),
      detectedImageBase64: json['detectedImageBase64'],
      detectionBoxes: (json['detectionBoxes'] as List?)
          ?.map((e) => DetectionBox.fromJson(e))
          .toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'nameThai': nameThai,
      'nameEnglish': nameEnglish,
      'imageUrl': imageUrl,
      'meanings': meanings.toJson(),
      'useFor': useFor,
      'isFavorite': isFavorite,
      'imageBase64': imageBase64,
      'detectedAt': detectedAt?.toIso8601String(),
      'confidence': confidence,
      'detectedImageBase64': detectedImageBase64,
      'detectionBoxes': detectionBoxes?.map((e) => e.toJson()).toList(),
    };
  }

  // Convert Flower object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'nameThai': nameThai,
      'nameEnglish': nameEnglish,
      'imageUrl': imageUrl,
      'colorMeanings': meanings.colorMeanings != null
          ? jsonEncode(meanings.colorMeanings!.map((e) => e.toJson()).toList())
          : null,
      'otherMeanings': meanings.other,
      'useFor': useFor?.join(','), // Store list as comma-separated string
      'isFavorite': isFavorite ? 1 : 0, // SQLite uses integers for booleans
      'imageBase64': imageBase64,
      'detectedAt': detectedAt?.toIso8601String(),
      'confidence': confidence,
      'detectedImageBase64': detectedImageBase64,
      'detectionBoxes': detectionBoxes != null
          ? jsonEncode(detectionBoxes!.map((e) => e.toJson()).toList())
          : null,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create Flower object from Map (from database)
  factory Flower.fromMap(Map<String, dynamic> map) {
    // Parse colorMeanings from JSON string
    List<FlowerTypeMeanning>? colorMeaningsList;
    if (map['colorMeanings'] != null && map['colorMeanings'].isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(map['colorMeanings']);
        colorMeaningsList = decoded
            .map((item) => FlowerTypeMeanning.fromJson(item))
            .toList();
      } catch (e) {
        print('Error parsing colorMeanings: $e');
      }
    }

    // Parse detectionBoxes from JSON string
    List<DetectionBox>? detectionBoxes;
    if (map['detectionBoxes'] != null &&
        map['detectionBoxes'].toString().isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(map['detectionBoxes']);
        detectionBoxes = decoded
            .map((item) => DetectionBox.fromJson(item))
            .toList();
      } catch (e) {
        print('Error parsing detectionBoxes: $e');
      }
    }

    return Flower(
      id: map['id']?.toInt(),
      day: map['day']?.toString(),
      nameThai: map['nameThai'] ?? '',
      nameEnglish: map['nameEnglish'] ?? '',
      imageUrl: map['imageUrl'],
      meanings: Meanings(
        colorMeanings: colorMeaningsList,
        other: map['otherMeanings'],
      ),
      useFor: map['useFor'] != null && map['useFor'].isNotEmpty
          ? map['useFor'].split(',')
          : null,
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      imageBase64: map['imageBase64'],
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

  // Create a copy with updated values
  Flower copyWith({
    int? id,
    String? day,
    String? nameThai,
    String? nameEnglish,
    String? imageUrl,
    Meanings? meanings,
    List<String>? useFor,
    bool? isFavorite,
    String? imageBase64,
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
      meanings: meanings ?? this.meanings,
      useFor: useFor ?? this.useFor,
      isFavorite: isFavorite ?? this.isFavorite,
      imageBase64: imageBase64 ?? this.imageBase64,
      detectedAt: detectedAt ?? this.detectedAt,
      confidence: confidence ?? this.confidence,
      detectedImageBase64: detectedImageBase64 ?? this.detectedImageBase64,
      detectionBoxes: detectionBoxes ?? this.detectionBoxes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Meanings {
  final List<FlowerTypeMeanning>? colorMeanings;
  final String? other;

  Meanings({this.colorMeanings, this.other});

  factory Meanings.fromJson(Map<String, dynamic> json) {
    List<FlowerTypeMeanning>? colorMeaningsList;
    if (json['colorMeanings'] != null) {
      colorMeaningsList = (json['colorMeanings'] as List)
          .map((item) => FlowerTypeMeanning.fromJson(item))
          .toList();
    }

    return Meanings(colorMeanings: colorMeaningsList, other: json['other']);
  }

  Map<String, dynamic> toJson() {
    return {
      'colorMeanings': colorMeanings?.map((item) => item.toJson()).toList(),
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
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
      label: json['label']?.toString() ?? '',
      confidence: (json['confidence'] as num).toDouble(),
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
