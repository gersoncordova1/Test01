import 'package:flutter/material.dart';
import 'package:studyroom_app/api_service.dart';
import 'package:studyroom_app/models/reservation.dart';
import 'package:studyroom_app/models/room.dart'; // Necesario para mostrar detalles de la sala anidada

class MyReservationsScreen extends StatefulWidget {
  final String loggedInUsername;

  const MyReservationsScreen({super.key, required this.loggedInUsername});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final ApiService _apiService = ApiService();
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserReservations(); // Load user reservations when the screen initializes
  }

  // Method to fetch reservations for the logged-in user
  Future<void> _fetchUserReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _apiService.getUserReservations(widget.loggedInUsername);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _reservations = result['data'] as List<Reservation>;
      } else {
        _errorMessage = result['message'];
      }
    });
  }

  // Method to cancel a reservation
  Future<void> _cancelReservation(String reservationId) async {
    // Show a confirmation dialog before canceling
    final bool confirmCancel = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850], // Fondo oscuro para el diálogo
        title: const Text('Confirmar Cancelación', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que quieres cancelar esta reserva?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // No cancelar
            child: const Text('No', style: TextStyle(color: Colors.tealAccent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirmar cancelación
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Sí, Cancelar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false; // En caso de que el diálogo se cierre sin selección

    if (confirmCancel) {
      setState(() {
        _isLoading = true; // Mostrar carga al cancelar
      });
      final result = await _apiService.cancelReservation(reservationId);
      setState(() {
        _isLoading = false; // Ocultar carga
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada exitosamente!'), backgroundColor: Colors.green),
        );
        _fetchUserReservations(); // Recargar la lista de reservas
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar: ${result['message']}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro
      appBar: AppBar(
        title: const Text('Mis Reservas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black, // Fondo oscuro del AppBar
        iconTheme: const IconThemeData(color: Colors.white), // Color del icono de retroceso
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchUserReservations,
            tooltip: 'Recargar mis reservas',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 15),
              Text(
                'Error al cargar reservas: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _fetchUserReservations,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      )
          : _reservations.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.calendar_month, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No tienes reservas activas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.white70),
            ),
            Text(
              '¡Explora las salas y haz una reserva!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _reservations.length,
        itemBuilder: (context, index) {
          final reservation = _reservations[index];
          // Determina si la reserva puede ser cancelada (si la hora de fin no ha pasado)
          final bool canCancel = reservation.endTime.isAfter(DateTime.now());

          // Estilos basados en el estado de la reserva
          Color cardColor = Colors.grey[850]!;
          Color statusColor = Colors.tealAccent;
          String statusText = 'Confirmada';
          IconData statusIcon = Icons.check_circle_outline;

          if (reservation.status == ReservationStatus.cancelled) {
            cardColor = Colors.red[900]!;
            statusColor = Colors.redAccent;
            statusText = 'Cancelada';
            statusIcon = Icons.cancel;
          } else if (reservation.status == ReservationStatus.completed) {
            cardColor = Colors.blueGrey[900]!;
            statusColor = Colors.blueGrey;
            statusText = 'Completada';
            statusIcon = Icons.check_circle;
          } else if (reservation.endTime.isBefore(DateTime.now())) {
            // Si no está cancelada/completada pero ya pasó la hora, la marcamos visualmente como completada
            cardColor = Colors.blueGrey[900]!;
            statusColor = Colors.blueGrey;
            statusText = 'Completada (Auto)'; // Para distinguir visualmente
            statusIcon = Icons.check_circle;
          }

          // Asumiendo que la propiedad 'room' siempre viene incluida ahora
          final room = reservation.room;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            color: cardColor,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Reserva en: ${room?.name ?? 'Sala Desconocida'}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(statusIcon, color: statusColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Fecha: ${reservation.startTime.toShortDateString()}',
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hora: ${reservation.startTime.toShortTimeString()} - ${reservation.endTime.toShortTimeString()}',
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                  const SizedBox(height: 15),
                  if (room?.description != null && room!.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: Text(
                        'Descripción: ${room.description!}',
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white60),
                      ),
                    ),
                  // Botón de Cancelar
                  if (canCancel && reservation.status == ReservationStatus.confirmed) // Solo mostrar si puede cancelar y no está ya cancelada/completada
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _cancelReservation(reservation.id),
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text('Cancelar Reserva', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Extension to format DateTime for display
extension DateFormatting on DateTime {
  String toShortDateString() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year.toString().substring(2)}';
  }

  String toShortTimeString() {
    // Aquí el cambio clave: aseguramos que la hora se convierta a local antes de formatear.
    final localTime = this.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }
}
