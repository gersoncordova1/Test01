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
    // Si por alguna razón viene como String (ej. "Grupal" o "grupal"), también lo maneja
    RoomType parsedType;
    if (json['type'] is int) {
      // Esta rama se activaría si el backend guardara el enum como int.
      parsedType = RoomType.values[json['type'] as int];
    } else if (json['type'] is String) {
      // Esta es la rama que debería activarse ahora que el backend guarda el enum como string.
      // Compara el string de forma insensible a mayúsculas/minúsculas para la recepción.
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
    // Convierte el enum a su nombre en string (ej. 'grupal' o 'individual')
    String enumName = type.toString().split('.').last;
    // Capitaliza la primera letra para que coincida con el backend (Grupal, Individual)
    String capitalizedEnumName = enumName.substring(0, 1).toUpperCase() + enumName.substring(1);

    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'description': description,
      'creatorUsername': creatorUsername,
      'type': capitalizedEnumName, // <--- CAMBIO CLAVE: Envía el nombre del enum capitalizado
    };
  }
}
