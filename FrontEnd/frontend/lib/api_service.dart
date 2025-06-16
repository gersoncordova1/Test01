import 'dart:convert'; // Para codificar y decodificar JSON
import 'package:http/http.dart' as http; // Importa el paquete http
import 'package:studyroom_app/models/room.dart'; // Importa el nuevo modelo Room

class ApiService {
  // Define la URL base de tu API de ASP.NET Core.
  // Asegúrate de que tu API esté ejecutándose en este puerto.
  final String _baseUrl = 'http://localhost:5056';

  // --- Métodos de Autenticación (ya existentes) ---
  Future<Map<String, dynamic>> registerUser(String username, String password) async {
    final url = Uri.parse('$_baseUrl/Auth/register');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'username': username, 'password': password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['message'] ?? 'Error desconocido'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final url = Uri.parse('$_baseUrl/Auth/login');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'username': username, 'password': password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['message'] ?? 'Credenciales inválidas'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // --- NUEVOS Métodos para la Gestión de Salas (Rooms) ---

  // Método para crear una nueva sala
  Future<Map<String, dynamic>> createRoom(Room room) async {
    final url = Uri.parse('$_baseUrl/Rooms');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(room.toJson()); // Convierte el objeto Room a JSON

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) { // 201 Created es el código esperado para POST exitoso
        return {'success': true, 'data': Room.fromJson(jsonDecode(response.body))};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['title'] ?? 'Error al crear sala'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Método para obtener todas las salas
  Future<Map<String, dynamic>> getRooms() async {
    final url = Uri.parse('$_baseUrl/Rooms');
    final headers = {'Content-Type': 'application/json'}; // No siempre es necesario para GET, pero buena práctica

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Mapea la lista de JSON a una lista de objetos Room
        List<dynamic> roomsJson = jsonDecode(response.body);
        List<Room> rooms = roomsJson.map((json) => Room.fromJson(json)).toList();
        return {'success': true, 'data': rooms};
      } else {
        return {'success': false, 'message': 'Error al obtener salas'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Método para obtener una sala por su ID
  Future<Map<String, dynamic>> getRoomById(String id) async {
    final url = Uri.parse('$_baseUrl/Rooms/$id');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return {'success': true, 'data': Room.fromJson(jsonDecode(response.body))};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Sala no encontrada'};
      } else {
        return {'success': false, 'message': 'Error al obtener sala'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Método para actualizar una sala existente
  Future<Map<String, dynamic>> updateRoom(Room room) async {
    final url = Uri.parse('$_baseUrl/Rooms/${room.id}');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(room.toJson()); // Convierte el objeto Room a JSON

    try {
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 204) { // 204 No Content es el código esperado para PUT exitoso
        return {'success': true, 'message': 'Sala actualizada con éxito'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Sala no encontrada para actualizar'};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['title'] ?? 'Error al actualizar sala'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Método para eliminar una sala
  Future<Map<String, dynamic>> deleteRoom(String id) async {
    final url = Uri.parse('$_baseUrl/Rooms/$id');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 204) { // 204 No Content es el código esperado para DELETE exitoso
        return {'success': true, 'message': 'Sala eliminada con éxito'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Sala no encontrada para eliminar'};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['title'] ?? 'Error al eliminar sala'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
