import 'package:uuid/uuid.dart';

// Enum para los tipos de sala en Flutter
enum RoomType {
  grupal,
  individual,
}

class Room {
  final String id;
  final String name;
  final int capacity;
  final String? description;
  final String creatorUsername;
  final RoomType type;

  Room({
    String? id,
    required this.name,
    required this.capacity,
    this.description,
    required this.creatorUsername,
    required this.type,
  }) : id = id ?? const Uuid().v4();

  // Factory constructor para crear una instancia de Room desde un mapa JSON
  factory Room.fromJson(Map<String, dynamic> json) {
    RoomType parsedType;
    if (json['type'] is int) {
      // Esta rama se activaría si el backend guardara el enum como int.
      parsedType = RoomType.values[json['type'] as int];
    } else if (json['type'] is String) {
      // Esta es la rama que debería activarse ahora que el backend guarda el enum como string.
      String typeString = (json['type'] as String).toLowerCase();
      if (typeString == 'grupal') {
        parsedType = RoomType.grupal;
      } else if (typeString == 'individual') {
        parsedType = RoomType.individual;
      } else {
        // Valor por defecto o manejo de error si el tipo no es válido
        parsedType = RoomType.grupal;
      }
    } else {
      // Valor por defecto si el tipo no es ni int ni String
      parsedType = RoomType.grupal;
    }

    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      capacity: json['capacity'] as int,
      description: json['description'] as String?,
      creatorUsername: json['creatorUsername'] as String,
      type: parsedType, // Usa el tipo de sala parseado
    );
  }

  // Método para convertir una instancia de Room a un mapa JSON
  Map<String, dynamic> toJson() {
    String enumName = type.toString().split('.').last;
    String capitalizedEnumName = enumName.substring(0, 1).toUpperCase() + enumName.substring(1);

    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'description': description,
      'creatorUsername': creatorUsername,
      'type': capitalizedEnumName,
    };
  }
}
