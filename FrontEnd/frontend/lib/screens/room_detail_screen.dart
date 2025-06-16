import 'package:flutter/material.dart';
import 'package:studyroom_app/api_service.dart';
import 'package:studyroom_app/models/room.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room; // La sala que se está visualizando/editando
  final String loggedInUsername; // Para pasar el usuario logueado al ApiService

  const RoomDetailScreen({super.key, required this.room, required this.loggedInUsername});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _descriptionController;
  late RoomType _selectedRoomType;

  bool _isEditing = false; // Estado para alternar entre vista y edición
  bool _isLoading = false; // Para el estado de los botones (guardar/eliminar)
  String? _errorMessage; // Para mostrar errores

  @override
  void initState() {
    super.initState();
    // Inicializa los controladores con los datos de la sala recibida
    _nameController = TextEditingController(text: widget.room.name);
    _capacityController = TextEditingController(text: widget.room.capacity.toString());
    _descriptionController = TextEditingController(text: widget.room.description);
    _selectedRoomType = widget.room.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Método para guardar los cambios de la sala
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final updatedRoom = Room(
        id: widget.room.id, // Es crucial mantener el mismo ID al actualizar
        name: _nameController.text.trim(),
        capacity: int.parse(_capacityController.text.trim()),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        creatorUsername: widget.room.creatorUsername, // El creador no cambia
        type: _selectedRoomType,
      );

      final result = await _apiService.updateRoom(updatedRoom);

      setState(() {
        _isLoading = false;
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sala actualizada con éxito!'), backgroundColor: Colors.green),
          );
          // Vuelve a la vista no editable y pasa un indicador de que se actualizó
          setState(() {
            _isEditing = false;
          });
          Navigator.pop(context, true); // Regresa a RoomsScreen indicando éxito
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  // Método para eliminar la sala
  Future<void> _deleteRoom() async {
    // Confirmación antes de eliminar
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850], // Fondo oscuro
        title: const Text('Confirmar Eliminación', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que quieres eliminar esta sala?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // No eliminar
            child: const Text('Cancelar', style: TextStyle(color: Colors.tealAccent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirmar eliminación
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false; // En caso de que se cierre el diálogo sin seleccionar nada

    if (confirmDelete) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await _apiService.deleteRoom(widget.room.id);

      setState(() {
        _isLoading = false;
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sala eliminada con éxito!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Regresa a RoomsScreen indicando éxito
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Comprueba si el usuario logueado es el creador de la sala
    final bool isCreator = widget.loggedInUsername == widget.room.creatorUsername;

    return Scaffold(
      backgroundColor: Colors.black, // Fondo oscuro
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar Sala' : widget.room.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // Color del icono de retroceso
        actions: [
          if (isCreator && !_isEditing) // Solo el creador puede editar, y solo si no está ya editando
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.tealAccent),
              onPressed: () {
                setState(() {
                  _isEditing = true; // Activa el modo de edición
                });
              },
              tooltip: 'Editar sala',
            ),
          if (isCreator && !_isEditing) // Solo el creador puede eliminar, y solo si no está editando
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteRoom,
              tooltip: 'Eliminar sala',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // Título y tipo de sala
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.meeting_room, size: 80, color: Colors.tealAccent),
                    const SizedBox(height: 10),
                    Text(
                      widget.room.name,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.room.type == RoomType.grupal ? 'Cubículo Grupal' : 'Cubículo Individual',
                      style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Campos de texto para editar/mostrar
              _buildTextFormField(
                controller: _nameController,
                labelText: 'Nombre de la Sala',
                icon: Icons.edit,
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese un nombre para la sala';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                controller: _capacityController,
                labelText: 'Capacidad (personas)',
                icon: Icons.people,
                enabled: _isEditing,
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

              // Selector de tipo de sala (solo editable si está en modo edición)
              if (_isEditing) // Solo muestra el selector en modo edición
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
                              onChanged: _isEditing ? (RoomType? value) {
                                setState(() {
                                  _selectedRoomType = value!;
                                });
                              } : null,
                              activeColor: Colors.tealAccent,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<RoomType>(
                              title: const Text('Individual', style: TextStyle(color: Colors.white)),
                              value: RoomType.individual,
                              groupValue: _selectedRoomType,
                              onChanged: _isEditing ? (RoomType? value) {
                                setState(() {
                                  _selectedRoomType = value!;
                                });
                              } : null,
                              activeColor: Colors.tealAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else // Muestra el texto si no está en modo edición
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(widget.room.type == RoomType.grupal ? Icons.groups : Icons.person, color: Colors.white70),
                      const SizedBox(width: 10),
                      Text(
                        'Tipo: ${widget.room.type == RoomType.grupal ? 'Grupal' : 'Individual'}',
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _descriptionController,
                labelText: 'Descripción (Opcional)',
                icon: Icons.description,
                enabled: _isEditing,
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 25),

              // Mensaje de error
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Botones de acción (Guardar cambios / Cancelar)
              if (_isEditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveChanges,
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditing = false; // Cancela el modo de edición
                            // Restaura los valores originales si se cancela la edición
                            _nameController.text = widget.room.name;
                            _capacityController.text = widget.room.capacity.toString();
                            _descriptionController.text = widget.room.description ?? '';
                            _selectedRoomType = widget.room.type;
                            _errorMessage = null; // Limpia errores
                          });
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),

              // Información de Creador
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Creado por: ${widget.room.creatorUsername}',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para TextFormFields con estilos comunes
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int minLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      decoration: InputDecoration(
        labelText: labelText,
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
        disabledBorder: OutlineInputBorder( // Estilo cuando está deshabilitado
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        prefixIcon: Icon(icon, color: Colors.tealAccent),
      ),
      validator: validator,
    );
  }
}
