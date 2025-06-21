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
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this reservation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return; // If user cancels, do nothing

    setState(() {
      _isLoading = true; // Show loading indicator
      _errorMessage = null;
    });

    final result = await _apiService.cancelReservation(reservationId);

    setState(() {
      _isLoading = false; // Hide loading indicator
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        _fetchUserReservations(); // Refresh the list after cancellation
      } else {
        _errorMessage = result['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${_errorMessage!}')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        title: const Text('My Reservations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black, // Dark AppBar background
        iconTheme: const IconThemeData(color: Colors.white), // White back icon
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchUserReservations,
            tooltip: 'Refresh Reservations',
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
              const Icon(Icons.error, color: Colors.redAccent, size: 60),
              const SizedBox(height: 15),
              Text(
                'Error loading reservations: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 18),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _fetchUserReservations,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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
            Icon(Icons.event_busy, size: 100, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'You have no active reservations.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, color: Colors.white70),
            ),
            SizedBox(height: 10),
            Text(
              'Go to the "Study Rooms" tab to book one!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white60),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _reservations.length,
        itemBuilder: (context, index) {
          final reservation = _reservations[index];
          final room = reservation.room; // Get the nested Room object

          // Determine status text and color
          String statusText;
          Color statusColor;
          switch (reservation.status) {
            case ReservationStatus.confirmed:
              statusText = 'Confirmed';
              statusColor = Colors.greenAccent;
              break;
            case ReservationStatus.cancelled:
              statusText = 'Cancelled';
              statusColor = Colors.redAccent;
              break;
            case ReservationStatus.completed:
              statusText = 'Completed';
              statusColor = Colors.orangeAccent;
              break;
          }

          // Determine if cancellation is allowed (e.g., if it's confirmed and in the future)
          final bool canCancel = reservation.status == ReservationStatus.confirmed &&
              reservation.endTime.isAfter(DateTime.now());

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            elevation: 6,
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Room Name and Type Icon
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              room?.type == RoomType.grupal ? Icons.groups : Icons.person,
                              color: Colors.tealAccent,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                room?.name ?? 'Unknown Room', // Display room name
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Text
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
                  // Reservation Time
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.blueGrey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'From: ${reservation.startTime.toLocal().toShortDateString()} ${reservation.startTime.toLocal().toShortTimeString()}',
                        style: const TextStyle(fontSize: 15, color: Colors.white70),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled, color: Colors.blueGrey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'To: ${reservation.endTime.toLocal().toShortDateString()} ${reservation.endTime.toLocal().toShortTimeString()}',
                        style: const TextStyle(fontSize: 15, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Room Description (if available)
                  if (room?.description != null && room!.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Description: ${room.description!}',
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white60),
                      ),
                    ),
                  const SizedBox(height: 15),
                  // Cancel Button
                  if (canCancel)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _cancelReservation(reservation.id),
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text('Cancel Reservation', style: TextStyle(color: Colors.white)),
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
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
