import 'dart:convert'; // For encoding and decoding JSON
import 'package:http/http.dart' as http; // Import the http package
import 'package:studyroom_app/models/room.dart'; // Import the Room model
import 'package:studyroom_app/models/reservation.dart'; // Import the new Reservation model

class ApiService {
  // Define the base URL of your ASP.NET Core API.
  // Ensure your API is running on this port.
  // Later, when the API is on Azure, you will change this to the Azure URL.
  final String _baseUrl = 'http://localhost:5056';

  // --- Authentication Methods (existing) ---
  Future<Map<String, dynamic>> registerUser(String username, String password) async {
    final url = Uri.parse('$_baseUrl/Auth/register');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'username': username, 'password': password});

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['message'] ?? 'Unknown error'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
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
        return {'success': false, 'message': jsonDecode(response.body)['message'] ?? 'Invalid credentials'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // --- Room Management Methods (existing) ---

  // Method to create a new room
  Future<Map<String, dynamic>> createRoom(Room room) async {
    final url = Uri.parse('$_baseUrl/Rooms');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(room.toJson());

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': Room.fromJson(jsonDecode(response.body))};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['title'] ?? 'Error creating room'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Method to get all rooms
  Future<Map<String, dynamic>> getRooms() async {
    final url = Uri.parse('$_baseUrl/Rooms');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> roomsJson = jsonDecode(response.body);
        List<Room> rooms = roomsJson.map((json) => Room.fromJson(json)).toList();
        return {'success': true, 'data': rooms};
      } else {
        return {'success': false, 'message': 'Error getting rooms'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Method to get a room by its ID
  Future<Map<String, dynamic>> getRoomById(String id) async {
    final url = Uri.parse('$_baseUrl/Rooms/$id');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return {'success': true, 'data': Room.fromJson(jsonDecode(response.body))};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Room not found'};
      } else {
        return {'success': false, 'message': 'Error getting room'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Method to update an existing room
  Future<Map<String, dynamic>> updateRoom(Room room) async {
    final url = Uri.parse('$_baseUrl/Rooms/${room.id}');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(room.toJson());

    try {
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 204) {
        return {'success': true, 'message': 'Room updated successfully'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Room not found for update'};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['title'] ?? 'Error updating room'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Method to delete a room
  Future<Map<String, dynamic>> deleteRoom(String id) async {
    final url = Uri.parse('$_baseUrl/Rooms/$id');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 204) {
        return {'success': true, 'message': 'Room deleted successfully'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Room not found for deletion'};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['title'] ?? 'Error deleting room'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // --- NEW Methods for Reservation Management ---

  // Method to create a new reservation
  Future<Map<String, dynamic>> createReservation(Reservation reservation) async {
    final url = Uri.parse('$_baseUrl/Reservations');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(reservation.toJson()); // Converts the Reservation object to JSON

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) { // 201 Created is the expected code for successful POST
        return {'success': true, 'data': Reservation.fromJson(jsonDecode(response.body))};
      } else {
        // Attempt to extract the error message from the response body
        String? errorMessage;
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson.containsKey('message')) {
            errorMessage = errorJson['message'];
          } else if (errorJson.containsKey('title')) { // Common for validation errors
            errorMessage = errorJson['title'];
          } else if (errorJson.containsKey('errors') && errorJson['errors'] is Map) {
            // Extract validation errors
            Map<String, dynamic> errors = errorJson['errors'];
            errorMessage = errors.values.expand((e) => e as List).join('; ');
          }
        } catch (e) {
          // Fallback if response body is not valid JSON
          errorMessage = 'Server error: ${response.statusCode}';
        }
        return {'success': false, 'message': errorMessage ?? 'Unknown error creating reservation'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Method to get all reservations for a specific user
  Future<Map<String, dynamic>> getUserReservations(String username) async {
    final url = Uri.parse('$_baseUrl/Reservations/ByUser/$username');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        // Since the backend now sends a list of reservations with nested Room objects,
        // we map each JSON object to a Reservation model.
        List<dynamic> reservationsJson = jsonDecode(response.body);
        List<Reservation> reservations = reservationsJson.map((json) => Reservation.fromJson(json)).toList();
        return {'success': true, 'data': reservations};
      } else {
        return {'success': false, 'message': 'Error getting user reservations'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Method to get all reservations for a specific room
  Future<Map<String, dynamic>> getRoomReservations(String roomId) async {
    final url = Uri.parse('$_baseUrl/Reservations/ByRoom/$roomId');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> reservationsJson = jsonDecode(response.body);
        List<Reservation> reservations = reservationsJson.map((json) => Reservation.fromJson(json)).toList();
        return {'success': true, 'data': reservations};
      } else {
        return {'success': false, 'message': 'Error getting room reservations'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Method to cancel a reservation
  Future<Map<String, dynamic>> cancelReservation(String id) async {
    final url = Uri.parse('$_baseUrl/Reservations/Cancel/$id');

    try {
      final response = await http.put(url); // PUT request to change status

      if (response.statusCode == 204) { // 204 No Content is expected for successful PUT
        return {'success': true, 'message': 'Reservation cancelled successfully'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Reservation not found for cancellation'};
      } else {
        // Handle other error codes, similar to createReservation
        String? errorMessage;
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage = errorJson['message'] ?? errorJson['title'] ?? (errorJson.containsKey('errors') ? (errorJson['errors'].values.expand((e) => e as List).join('; ')) : null);
        } catch (e) {
          errorMessage = 'Server error: ${response.statusCode}';
        }
        return {'success': false, 'message': errorMessage ?? 'Unknown error cancelling reservation'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Method to delete a reservation
  Future<Map<String, dynamic>> deleteReservation(String id) async {
    final url = Uri.parse('$_baseUrl/Reservations/$id');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 204) { // 204 No Content is expected for successful DELETE
        return {'success': true, 'message': 'Reservation deleted successfully'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Reservation not found for deletion'};
      } else {
        return {'success': false, 'message': jsonDecode(response.body)['title'] ?? 'Error deleting reservation'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
