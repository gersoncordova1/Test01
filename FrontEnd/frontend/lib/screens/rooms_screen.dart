import 'package:flutter/material.dart';
import 'package:studyroom_app/screens/auth_screen.dart';
import 'package:studyroom_app/api_service.dart';
import 'package:studyroom_app/models/room.dart';
import 'package:studyroom_app/screens/create_room_screen.dart';
import 'package:studyroom_app/screens/room_detail_screen.dart'; // ¡NUEVA IMPORTACIÓN!

class RoomsScreen extends StatefulWidget {
  final String loggedInUsername;

  const RoomsScreen({super.key, required this.loggedInUsername});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Room> _allRooms = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _apiService.getRooms();

    setState(() {
      _isLoading = false;
      if (result['success']) {
        _allRooms = result['data'] as List<Room>;
      } else {
        _errorMessage = result['message'];
      }
    });
  }

  // Método para construir la tarjeta de una sala
  Widget _buildRoomCard(Room room) {
    final bool isAvailable = true; // TODO: Implementar lógica de disponibilidad/reserva
    final Color availabilityColor = isAvailable ? Colors.greenAccent : Colors.redAccent;
    final String availabilityText = isAvailable ? 'Disponible' : 'Reservado';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      color: Colors.grey[850],
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () async { // Hacemos el onTap asíncrono para esperar el resultado de la navegación
          // Navega a la pantalla de detalle y pasa la sala, además del username logueado
          final bool? roomModified = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomDetailScreen(
                room: room,
                loggedInUsername: widget.loggedInUsername, // Pasa el username
              ),
            ),
          );
          // Si la sala fue modificada o eliminada, recarga la lista
          if (roomModified == true) {
            _fetchRooms();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    room.type == RoomType.grupal ? Icons.groups : Icons.person,
                    color: Colors.tealAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    availabilityText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: availabilityColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people_alt, color: Colors.blueGrey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Capacidad: ${room.capacity} personas',
                    style: const TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                ],
              ),
              if (room.description != null && room.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    room.description!,
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white60),
                  ),
                ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Creador: ${room.creatorUsername}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Room> groupRooms = _allRooms.where((room) => room.type == RoomType.grupal).toList();
    final List<Room> individualRooms = _allRooms.where((room) => room.type == RoomType.individual).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('UPSA StudyRoom', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchRooms,
            tooltip: 'Recargar salas',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.tealAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Cubículos Grupales', icon: Icon(Icons.groups)),
            Tab(text: 'Cubículos Individuales', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
              : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)))
              : groupRooms.isEmpty
              ? const Center(
            child: Text('No hay cubículos grupales disponibles.', style: TextStyle(color: Colors.white70, fontSize: 16)),
          )
              : ListView.builder(
            itemCount: groupRooms.length,
            itemBuilder: (context, index) {
              return _buildRoomCard(groupRooms[index]);
            },
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
              : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)))
              : individualRooms.isEmpty
              ? const Center(
            child: Text('No hay cubículos individuales disponibles.', style: TextStyle(color: Colors.white70, fontSize: 16)),
          )
              : ListView.builder(
            itemCount: individualRooms.length,
            itemBuilder: (context, index) {
              return _buildRoomCard(individualRooms[index]);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newRoomCreated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateRoomScreen(creatorUsername: widget.loggedInUsername)),
          );
          if (newRoomCreated == true) {
            _fetchRooms();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Crear Sala', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        tooltip: 'Crear una nueva sala de estudio',
      ),
    );
  }
}
