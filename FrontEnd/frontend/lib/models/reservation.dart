import 'package:uuid/uuid.dart'; // Para generar IDs únicas si es necesario
import 'package:studyroom_app/models/room.dart'; // Importa el modelo Room

// Enum para definir el estado de una reserva en Flutter
// Coincide con el enum del backend (Confirmed, Cancelled, Completed)
enum ReservationStatus {
  confirmed,
  cancelled,
  completed,
}

class Reservation {
  final String id;
  final String roomId;
  final Room? room; // Propiedad de navegación para la sala, ahora será incluida
  final String username;
  final DateTime startTime;
  final DateTime endTime;
  final ReservationStatus status;

  Reservation({
    String? id, // ID opcional para nuevas reservas, se generará si es nulo
    required this.roomId,
    this.room, // 'room' puede ser nulo si no se incluye en la respuesta (aunque ahora debería incluirse)
    required this.username,
    required this.startTime,
    required this.endTime,
    required this.status,
  }) : id = id ?? const Uuid().v4(); // Genera un ID si no se proporciona

  // Factory constructor para crear una instancia de Reservation desde un mapa JSON
  factory Reservation.fromJson(Map<String, dynamic> json) {
    // Convierte la cadena de estado del backend a nuestro enum ReservationStatus
    ReservationStatus parsedStatus;
    switch ((json['status'] as String).toLowerCase()) {
      case 'confirmed':
        parsedStatus = ReservationStatus.confirmed;
        break;
      case 'cancelled':
        parsedStatus = ReservationStatus.cancelled;
        break;
      case 'completed':
        parsedStatus = ReservationStatus.completed;
        break;
      default:
        parsedStatus = ReservationStatus.confirmed; // Valor por defecto en caso de error
    }

    return Reservation(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      // Intenta parsear el objeto 'room' anidado si existe en el JSON
      room: json['room'] != null ? Room.fromJson(json['room']) : null,
      username: json['username'] as String,
      // Parsea las cadenas de fecha/hora ISO 8601 a objetos DateTime
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: parsedStatus,
    );
  }

  // Método para convertir una instancia de Reservation a un mapa JSON
  // Este método se usará cuando enviemos una reserva al backend (ej. al crear)
  Map<String, dynamic> toJson() {
    return {
      // 'id' no se suele enviar al crear, ya que el backend lo genera
      'roomId': roomId,
      // 'room' no se envía al backend, ya que el backend lo carga por RoomId
      'username': username,
      // Convierte DateTime a cadena ISO 8601 (formato que espera el backend)
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      // Envía el nombre del enum de estado como string capitalizado (ej. "Confirmed")
      'status': status.toString().split('.').last.substring(0, 1).toUpperCase() + status.toString().split('.').last.substring(1),
    };
  }
}
