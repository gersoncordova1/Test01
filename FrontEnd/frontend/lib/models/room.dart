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
    // Maneja el tipo que viene como int desde el backend
    // Si json['type'] es un int (0 o 1), lo mapea al RoomType correspondiente
    // Si por alguna razón viene como String (ej. "Grupal"), también lo maneja (aunque la DB lo guarda como int)
    RoomType parsedType;
    if (json['type'] is int) {
      parsedType = RoomType.values[json['type'] as int]; // Mapea int a enum
    } else if (json['type'] is String) {
      // Caso de fallback si el backend envia el string (aunque no es lo que vemos ahora)
      parsedType = (json['type'] as String).toLowerCase() == 'grupal' ? RoomType.grupal : RoomType.individual;
    } else {
      // Valor por defecto o manejo de error si el tipo no es ni int ni String
      parsedType = RoomType.grupal; // O RoomType.individual, o lanzar un error
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
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'description': description,
      'creatorUsername': creatorUsername,
      'type': type.index, // Envía el índice entero del enum al backend
    };
  }
}
