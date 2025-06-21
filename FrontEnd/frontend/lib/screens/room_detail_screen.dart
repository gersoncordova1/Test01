import 'package:flutter/material.dart';
import 'package:studyroom_app/api_service.dart';
import 'package:studyroom_app/models/room.dart';
import 'package:studyroom_app/models/reservation.dart'; // ¡Nueva importación para el modelo Reservation!

class RoomDetailScreen extends StatefulWidget {
  final Room room; // The room being viewed/edited
  final String loggedInUsername; // To pass the logged-in user to ApiService

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

  bool _isEditing = false; // State to toggle between view and edit mode
  bool _isLoading = false; // For button states (save/delete/book)
  String? _errorMessage; // To display errors

  DateTime? _selectedStartDate; // For booking
  TimeOfDay? _selectedStartTime; // For booking
  DateTime? _selectedEndDate; // For booking
  TimeOfDay? _selectedEndTime; // For booking

  @override
  void initState() {
    super.initState();
    // Initialize controllers with room data
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

  // Method to save room changes
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final updatedRoom = Room(
        id: widget.room.id, // Crucial to keep the same ID when updating
        name: _nameController.text.trim(),
        capacity: int.parse(_capacityController.text.trim()),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        creatorUsername: widget.room.creatorUsername, // Creator does not change
        type: _selectedRoomType,
      );

      final result = await _apiService.updateRoom(updatedRoom);

      setState(() {
        _isLoading = false;
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room updated successfully!'), backgroundColor: Colors.green),
          );
          setState(() {
            _isEditing = false; // Go back to view mode
          });
          Navigator.pop(context, true); // Return to RoomsScreen indicating success
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  // Method to delete the room
  Future<void> _deleteRoom() async {
    // Confirmation before deletion
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850], // Dark background
        title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this room?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Do not delete
            child: const Text('Cancel', style: TextStyle(color: Colors.tealAccent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Confirm deletion
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false; // In case dialog is dismissed without selection

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
            const SnackBar(content: Text('Room deleted successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Return to RoomsScreen indicating success
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  // --- NEW: Method to handle date selection for booking ---
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)), // Up to 1 year from now
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.teal, // Color for selected date
              onPrimary: Colors.white, // Text color on selected date
              surface: Colors.grey, // Background color of picker
              onSurface: Colors.white, // Text color on picker surface
            ),
            dialogBackgroundColor: Colors.grey[800], // Dialog background
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = pickedDate;
          // If start date changes, reset end date if it's before new start date
          if (_selectedEndDate != null && _selectedEndDate!.isBefore(_selectedStartDate!)) {
            _selectedEndDate = _selectedStartDate;
          }
        } else {
          _selectedEndDate = pickedDate;
          // If end date changes, ensure it's not before start date
          if (_selectedStartDate != null && _selectedEndDate!.isBefore(_selectedStartDate!)) {
            _selectedEndDate = _selectedStartDate;
          }
        }
      });
    }
  }

  // --- NEW: Method to handle time selection for booking ---
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.teal, // Color for selected time
              onPrimary: Colors.white, // Text color on selected time
              surface: Colors.grey, // Background color of picker
              onSurface: Colors.white, // Text color on picker surface
            ),
            dialogBackgroundColor: Colors.grey[800], // Dialog background
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = pickedTime;
        } else {
          _selectedEndTime = pickedTime;
        }
      });
    }
  }

  // --- NEW: Method to create a reservation ---
  Future<void> _createReservation() async {
    if (_selectedStartDate == null || _selectedStartTime == null ||
        _selectedEndDate == null || _selectedEndTime == null) {
      setState(() {
        _errorMessage = 'Please select both start and end date/time for the reservation.';
      });
      return;
    }

    // Combine date and time into DateTime objects
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

    // Basic validation
    if (startDateTime.isAfter(endDateTime) || startDateTime.isAtSameMomentAs(endDateTime)) {
      setState(() {
        _errorMessage = 'End time must be after start time.';
      });
      return;
    }

    if (startDateTime.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
      setState(() {
        _errorMessage = 'Cannot book a room in the past.';
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
      startTime: startDateTime.toUtc(), // Send as UTC to backend
      endTime: endDateTime.toUtc(), // Send as UTC to backend
      status: ReservationStatus.confirmed, // Default status
    );

    final result = await _apiService.createReservation(newReservation);

    setState(() {
      _isLoading = false;
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation created successfully!'), backgroundColor: Colors.green),
        );
        // Clear date/time selectors after successful booking
        _selectedStartDate = null;
        _selectedStartTime = null;
        _selectedEndDate = null;
        _selectedEndTime = null;
      } else {
        _errorMessage = result['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${_errorMessage!}')),
        );
      }
    });
  }

  // --- NEW: Helper method to build action buttons or booking section ---
  Widget _buildRoomActions() {
    if (_isEditing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveChanges,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
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
                  _isEditing = false; // Cancel edit mode
                  // Restore original values if editing is canceled
                  _nameController.text = widget.room.name;
                  _capacityController.text = widget.room.capacity.toString();
                  _descriptionController.text = widget.room.description ?? '';
                  _selectedRoomType = widget.room.type;
                  _errorMessage = null; // Clear errors
                });
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
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
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Book this room:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Start Date & Time Pickers
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectDate(context, true),
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: Text(
                    _selectedStartDate == null
                        ? 'Select Start Date'
                        : 'Start Date: ${_selectedStartDate!.toLocal().toShortDateString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectTime(context, true),
                  icon: const Icon(Icons.alarm, color: Colors.white),
                  label: Text(
                    _selectedStartTime == null
                        ? 'Select Start Time'
                        : 'Start Time: ${_selectedStartTime!.format(context)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // End Date & Time Pickers
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectDate(context, false),
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: Text(
                    _selectedEndDate == null
                        ? 'Select End Date'
                        : 'End Date: ${_selectedEndDate!.toLocal().toShortDateString()}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _selectTime(context, false),
                  icon: const Icon(Icons.alarm, color: Colors.white),
                  label: Text(
                    _selectedEndTime == null
                        ? 'Select End Time'
                        : 'End Time: ${_selectedEndTime!.format(context)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          // Book Room Button
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _createReservation,
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.bookmark_add, color: Colors.white),
            label: Text(_isLoading ? 'Booking...' : 'Book Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the logged-in user is the room creator
    final bool isCreator = widget.loggedInUsername == widget.room.creatorUsername;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Room' : widget.room.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white), // White back icon
        actions: [
          if (isCreator && !_isEditing) // Only creator can edit, and only if not already editing
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.tealAccent),
              onPressed: () {
                setState(() {
                  _isEditing = true; // Activate edit mode
                });
              },
              tooltip: 'Edit room',
            ),
          if (isCreator && !_isEditing) // Only creator can delete, and only if not editing
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteRoom,
              tooltip: 'Delete room',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // Title and room type
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
                      widget.room.type == RoomType.grupal ? 'Group Cubicle' : 'Individual Cubicle',
                      style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Text fields for editing/display
              _buildTextFormField(
                controller: _nameController,
                labelText: 'Room Name',
                icon: Icons.edit,
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a room name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              _buildTextFormField(
                controller: _capacityController,
                labelText: 'Capacity (people)',
                icon: Icons.people,
                enabled: _isEditing,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter capacity';
                  }
                  if (int.tryParse(value.trim()) == null || int.parse(value.trim()) <= 0) {
                    return 'Please enter a valid number greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Room type selector (only editable if in edit mode)
              if (_isEditing) // Only show selector in edit mode
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Room Type:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<RoomType>(
                              title: const Text('Group', style: TextStyle(color: Colors.white)),
                              value: RoomType.grupal,
                              groupValue: _selectedRoomType,
                              onChanged: _isEditing ? (RoomType? value) {
                                setState(() {
                                  _selectedRoomType = value!;
                                });
                              } : null,
                              activeColor: Colors.tealAccent, // Color when selected
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
              else // Show text if not in edit mode
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  child: Row(
                    children: [
                      Icon(widget.room.type == RoomType.grupal ? Icons.groups : Icons.person, color: Colors.white70),
                      const SizedBox(width: 10),
                      Text(
                        'Type: ${widget.room.type == RoomType.grupal ? 'Group' : 'Individual'}',
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 15),

              _buildTextFormField(
                controller: _descriptionController,
                labelText: 'Description (Optional)',
                icon: Icons.description,
                enabled: _isEditing,
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 25),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Call the new helper method here
              _buildRoomActions(),

              // Creator Information
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Created by: ${widget.room.creatorUsername}',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget for TextFormFields with common styles
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
        disabledBorder: OutlineInputBorder( // Style when disabled
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        prefixIcon: Icon(icon, color: Colors.tealAccent),
      ),
      validator: validator,
    );
  }
}

// Extension to format DateTime for display (re-added for consistency)
extension DateFormatting on DateTime {
  String toShortDateString() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year.toString().substring(2)}';
  }

  String toShortTimeString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
