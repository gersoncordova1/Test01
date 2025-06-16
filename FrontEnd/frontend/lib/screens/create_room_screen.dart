import 'package:flutter/material.dart';
import 'package:studyroom_app/api_service.dart';
import 'package:studyroom_app/models/room.dart';

class CreateRoomScreen extends StatefulWidget {
  final String creatorUsername;

  const CreateRoomScreen({super.key, required this.creatorUsername});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  RoomType _selectedRoomType = RoomType.grupal; // Valor por defecto

  // Método para crear la sala
  Future<void> _createRoom() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final room = Room(
        name: _nameController.text.trim(),
        capacity: int.parse(_capacityController.text.trim()),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        creatorUsername: widget.creatorUsername,
        type: _selectedRoomType, // Usa el tipo de sala seleccionado
      );

      final result = await _apiService.createRoom(room);

      setState(() {
        _isLoading = false;
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sala creada con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro
      appBar: AppBar(
        title: const Text('Crear Nueva Sala', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black, // Fondo oscuro del AppBar
        iconTheme: const IconThemeData(color: Colors.white), // Color del icono de retroceso
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              const Icon(Icons.add_business_outlined, size: 80, color: Colors.tealAccent), // Icono con color
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white), // Texto de entrada blanco
                decoration: InputDecoration(
                  labelText: 'Nombre de la Sala',
                  hintText: 'Ej. Sala de concentración',
                  labelStyle: const TextStyle(color: Colors.white70), // Color del label
                  hintStyle: const TextStyle(color: Colors.white54), // Color del hint
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder( // Borde normal
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder( // Borde cuando está en foco
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.tealAccent), // Color de foco
                  ),
                  prefixIcon: const Icon(Icons.meeting_room, color: Colors.tealAccent),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese un nombre para la sala';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _capacityController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Capacidad (personas)',
                  hintText: 'Ej. 5',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.tealAccent),
                  ),
                  prefixIcon: const Icon(Icons.people, color: Colors.tealAccent),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese la capacidad';
                  }
                  if (int.tryParse(value.trim()) == null || int.parse(value.trim()) <= 0) {
                    return 'Por favor ingrese un número válido mayor que 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Selector de tipo de sala (Radio Buttons)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tipo de Sala:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<RoomType>(
                            title: const Text('Grupal', style: TextStyle(color: Colors.white)),
                            value: RoomType.grupal,
                            groupValue: _selectedRoomType,
                            onChanged: (RoomType? value) {
                              setState(() {
                                _selectedRoomType = value!;
                              });
                            },
                            activeColor: Colors.tealAccent, // Color cuando está seleccionado
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<RoomType>(
                            title: const Text('Individual', style: TextStyle(color: Colors.white)),
                            value: RoomType.individual,
                            groupValue: _selectedRoomType,
                            onChanged: (RoomType? value) {
                              setState(() {
                                _selectedRoomType = value!;
                              });
                            },
                            activeColor: Colors.tealAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  hintText: 'Escribe una breve descripción de la sala...',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.tealAccent),
                  ),
                  prefixIcon: const Icon(Icons.description, color: Colors.tealAccent),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 25),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createRoom,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Creando...' : 'Crear Sala'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Color del botón
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
