import 'dart:convert';

class Flower {
  final int? id; // Local database ID
  final String day;
  final String nameThai;
  final String nameEnglish;
  final String? imageUrl;
  final Meanings meanings;
  final List<String>? useFor;
  final bool isFavorite;
  final String? imageBase64; // For storing cached images locally
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Flower({
    this.id,
    required this.day,
    required this.nameThai,
    required this.nameEnglish,
    this.imageUrl,
    required this.meanings,
    this.useFor,
    this.isFavorite = false,
    this.imageBase64,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from JSON (for API responses)
  factory Flower.fromJson(Map<String, dynamic> json) {
    return Flower(
      day: json['day'] ?? '',
      nameThai: json['nameThai'] ?? '',
      nameEnglish: json['nameEnglish'] ?? '',
      imageUrl: json['imageUrl'],
      meanings: json['meanings'] != null
          ? Meanings.fromJson(json['meanings'])
          : Meanings(colorMeanings: null, other: null),
      useFor: json['useFor'] != null ? List<String>.from(json['useFor']) : null,
      isFavorite: json['isFavorite'] ?? false,
      imageBase64: json['imageBase64'],
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

    return Flower(
      id: map['id']?.toInt(),
      day: map['day'] ?? '',
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Meanings {
  final List<FlowerTypeMeanning>? colorMeanings;
  final String? other;

  Meanings({
    this.colorMeanings,
    this.other,
  });

  factory Meanings.fromJson(Map<String, dynamic> json) {
    List<FlowerTypeMeanning>? colorMeaningsList;
    if (json['colorMeanings'] != null) {
      colorMeaningsList = (json['colorMeanings'] as List)
          .map((item) => FlowerTypeMeanning.fromJson(item))
          .toList();
    }

    return Meanings(
      colorMeanings: colorMeaningsList,
      other: json['other'],
    );
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

  FlowerTypeMeanning({
    required this.color,
    required this.meaning,
  });

  factory FlowerTypeMeanning.fromJson(Map<String, dynamic> json) {
    return FlowerTypeMeanning(
      color: json['color'] ?? '',
      meaning: json['meaning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color,
      'meaning': meaning,
    };
  }
}
