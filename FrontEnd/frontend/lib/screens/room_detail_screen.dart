import 'package:flutter/material.dart';
import 'package:studyroom_app/api_service.dart';
import 'package:studyroom_app/models/room.dart';
import 'package:studyroom_app/models/reservation.dart'; // Importación para el modelo Reservation

class RoomDetailScreen extends StatefulWidget {
  final Room room; // La sala que se está visualizando/editando
  final String loggedInUsername; // Para pasar el usuario logueado al ApiService

  const RoomDetailScreen({super.key, required this.room, required this.loggedInUsername});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _formKey = GlobalKey<FormState>(); // Clave para validar el formulario
  final ApiService _apiService = ApiService(); // Instancia del servicio de API

  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _descriptionController;
  late RoomType _selectedRoomType;

  bool _isEditing = false; // Estado para alternar entre vista y edición
  bool _isLoading = false; // Para el estado de los botones (guardar/eliminar/reservar)
  String? _errorMessage; // Para mostrar errores

  // Propiedades para la selección de fecha y hora de la reserva
  DateTime? _selectedStartDate;
  TimeOfDay? _selectedStartTime;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedEndTime;

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

  // Método para seleccionar la fecha de inicio
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now(), // No se puede seleccionar una fecha pasada
      lastDate: DateTime.now().add(const Duration(days: 365)), // Un año en el futuro
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.teal, // Color de encabezado
              onPrimary: Colors.white, // Color de texto de encabezado
              surface: Colors.grey, // Fondo del calendario
              onSurface: Colors.white, // Color de texto de los días
            ),
            dialogBackgroundColor: Colors.grey[800], // Fondo del diálogo
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedStartDate) {
      setState(() {
        _selectedStartDate = pickedDate;
        // Si la fecha de inicio es después de la fecha de fin, reinicia la fecha de fin
        if (_selectedEndDate != null && _selectedStartDate!.isAfter(_selectedEndDate!)) {
          _selectedEndDate = _selectedStartDate;
        }
      });
    }
  }

  // Método para seleccionar la hora de inicio
  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.teal, // Color del dial del reloj
              onPrimary: Colors.white, // Color de los números del reloj
              surface: Colors.grey, // Fondo del selector
              onSurface: Colors.white, // Color de texto de las horas
            ),
            dialogBackgroundColor: Colors.grey[800], // Fondo del diálogo
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _selectedStartTime) {
      setState(() {
        _selectedStartTime = pickedTime;
      });
    }
  }

  // Método para seleccionar la fecha de fin
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? _selectedStartDate ?? DateTime.now(),
      firstDate: _selectedStartDate ?? DateTime.now(), // No puede ser antes de la fecha de inicio
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.teal,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[800],
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedEndDate) {
      setState(() {
        _selectedEndDate = pickedDate;
      });
    }
  }

  // Método para seleccionar la hora de fin
  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.teal,
              onPrimary: Colors.white,
              surface: Colors.grey,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.grey[800],
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && pickedTime != _selectedEndTime) {
      setState(() {
        _selectedEndTime = pickedTime;
      });
    }
  }

  // Método para manejar la creación de una reserva
  Future<void> _bookRoom() async {
    // Validaciones de los campos de fecha y hora
    if (_selectedStartDate == null || _selectedStartTime == null ||
        _selectedEndDate == null || _selectedEndTime == null) {
      setState(() {
        _errorMessage = 'Por favor, selecciona la fecha y hora de inicio y fin.';
      });
      return;
    }

    // Combina fecha y hora para obtener los objetos DateTime completos
    final DateTime startDateTime = DateTime(
      _selectedStartDate!.year,
      _selectedStartDate!.month,
      _selectedStartDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );

    final DateTime endDateTime = DateTime(
      _selectedEndDate!.year,
      _selectedEndDate!.month,
      _selectedEndDate!.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );

    // Valida que la hora de inicio sea anterior a la de fin
    if (!startDateTime.isBefore(endDateTime)) {
      setState(() {
        _errorMessage = 'La hora de inicio debe ser anterior a la hora de fin.';
      });
      return;
    }

    // Valida que la reserva no sea en el pasado
    // Se mantiene esta validación con .now() ya que la hora que se selecciona es la local
    if (startDateTime.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
      setState(() {
        _errorMessage = 'No se puede reservar en el pasado.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newReservation = Reservation(
      roomId: widget.room.id,
      username: widget.loggedInUsername,
      // --- CAMBIO CLAVE AQUÍ: Eliminamos .toUtc() al enviar las horas ---
      // Las horas se envían tal cual fueron seleccionadas (horas locales).
      startTime: startDateTime,
      endTime: endDateTime,
      status: ReservationStatus.confirmed,
    );

    final result = await _apiService.createReservation(newReservation);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Sala reservada con éxito!'), backgroundColor: Colors.green),
        );
        // Limpia los selectores después de una reserva exitosa
        _selectedStartDate = null;
        _selectedStartTime = null;
        _selectedEndDate = null;
        _selectedEndTime = null;
      } else {
        _errorMessage = result['message'];
      }
    });
  }

  // --- FUNCIÓN: Formatea TimeOfDay a una cadena HH:MM ---
  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) {
      return '';
    }
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  // --- FIN FUNCIÓN ---

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

              // Sección para "Reservar Sala"
              if (!_isEditing) // Solo muestra la sección de reserva si no está editando la sala
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reservar Sala', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 15),
                    // Selector de fecha de inicio
                    _buildDateTimeSelector(
                      context,
                      'Fecha Inicio',
                      _selectedStartDate,
                      Icons.calendar_today,
                      _selectStartDate,
                      _selectedStartDate?.toShortDateString(),
                    ),
                    const SizedBox(height: 15),
                    // Selector de hora de inicio
                    _buildDateTimeSelector(
                      context,
                      'Hora Inicio',
                      _selectedStartTime,
                      Icons.access_time,
                      _selectStartTime,
                      _formatTimeOfDay(_selectedStartTime),
                    ),
                    const SizedBox(height: 15),
                    // Selector de fecha de fin
                    _buildDateTimeSelector(
                      context,
                      'Fecha Fin',
                      _selectedEndDate,
                      Icons.calendar_today,
                      _selectEndDate,
                      _selectedEndDate?.toShortDateString(),
                    ),
                    const SizedBox(height: 15),
                    // Selector de hora de fin
                    _buildDateTimeSelector(
                      context,
                      'Hora Fin',
                      _selectedEndTime,
                      Icons.access_time,
                      _selectEndTime,
                      _formatTimeOfDay(_selectedEndTime),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _bookRoom,
                      icon: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.book),
                      label: Text(_isLoading ? 'Reservando...' : 'Reservar Sala'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),

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

  // Widget auxiliar para selectores de fecha/hora
  Widget _buildDateTimeSelector(
      BuildContext context,
      String label,
      dynamic selectedValue,
      IconData icon,
      Future<void> Function(BuildContext) onTap,
      String? displayValue,
      ) {
    return GestureDetector(
      onTap: _isLoading ? null : () => onTap(context),
      child: AbsorbPointer(
        child: TextFormField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
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
            prefixIcon: Icon(icon, color: Colors.tealAccent),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
          controller: TextEditingController(text: displayValue ?? ''), // Muestra el valor seleccionado
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, seleccione $label';
            }
            return null;
          },
        ),
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
    // Asegura que la hora se convierta a local antes de formatear.
    final localTime = this.toLocal();
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }
}
