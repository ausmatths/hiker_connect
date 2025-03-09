import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/events_provider.dart';
import '../../models/event_data.dart';
import '../../screens/events/location_picker_screen.dart'; // Import the LocationPickerScreen
import 'dart:developer' as developer;

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({Key? key}) : super(key: key);

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _participantLimitController = TextEditingController(text: '20');

  // Form values
  DateTime _eventDate = DateTime.now().add(const Duration(days: 7, hours: 10));
  DateTime _endDate = DateTime.now().add(const Duration(days: 7, hours: 13));
  String _category = 'Hiking';
  int _difficulty = 3;
  bool _isFree = true;
  String _price = '';
  double? _latitude;
  double? _longitude;

  // UI state
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLocationEditable = true;
  final List<String> _categories = [
    'Hiking',
    'Trail Running',
    'Backpacking',
    'Climbing',
    'Nature Walk',
    'Photography',
    'Wildlife',
    'Camping',
    'Volunteer',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize default values
    _participantLimitController.text = '20';
  }

  Future<void> _selectEventDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      // Show time picker
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_eventDate),
      );

      if (time != null && mounted) {
        setState(() {
          _eventDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );

          // Auto-update end date to be 3 hours after start date
          _endDate = _eventDate.add(const Duration(hours: 3));
        });
      }
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _eventDate,
      lastDate: _eventDate.add(const Duration(days: 7)),
    );

    if (picked != null && mounted) {
      // Show time picker
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate),
      );

      if (time != null && mounted) {
        setState(() {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  // Updated _pickLocation method
  Future<void> _pickLocation() async {
    // Using LocationData from location_picker_screen.dart
    // Import the LocationData class properly
    final result = await Navigator.push<LocationData>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _latitude != null && _longitude != null && _locationController.text.isNotEmpty
              ? LocationData(
            name: _locationController.text,
            latitude: _latitude!,
            longitude: _longitude!,
          )
              : null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _locationController.text = result.name;
        _latitude = result.latitude;
        _longitude = result.longitude;
        _isLocationEditable = false;
      });
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      developer.log('Creating new event', name: 'EventFormScreen');

      final eventsProvider = Provider.of<EventsProvider>(context, listen: false);

      // Calculate duration
      final duration = _endDate.difference(_eventDate);

      // Create event data object
      final eventData = EventData(
        id: '', // Will be set by Firestore
        title: _titleController.text,
        description: _descriptionController.text,
        eventDate: _eventDate,
        endDate: _endDate,
        duration: duration,
        location: _locationController.text,
        category: _category,
        difficulty: _difficulty,
        latitude: _latitude,
        longitude: _longitude,
        participantLimit: int.tryParse(_participantLimitController.text) ?? 20,
        isFree: _isFree,
        price: _isFree ? null : _price,
        attendees: [], // No attendees initially
        createdBy: eventsProvider.isAuthenticated ? 'user' : 'system', // Will be replaced with actual user ID
        organizer: 'Hiker Connect User', // Can be updated with user profile name
      );

      // Create event
      await eventsProvider.createEvent(eventData);

      if (mounted) {
        // Show success and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      developer.log('Error creating event: $e', name: 'EventFormScreen', error: e);

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create event: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participantLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('E, MMM d, yyyy · h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please provide a description'
                    : null,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Location with Map Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                        hintText: 'Enter location or pick on map',
                      ),
                      enabled: _isLocationEditable,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a location'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(_isLocationEditable
                        ? Icons.map
                        : Icons.edit_location),
                    onPressed: _pickLocation,
                    tooltip: _isLocationEditable
                        ? 'Pick on map'
                        : 'Edit location',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              if (_latitude != null && _longitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Coordinates: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Date and time pickers
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEventDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date & Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(dateFormat.format(_eventDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectEndDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date & Time',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event_available),
                        ),
                        child: Text(dateFormat.format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Difficulty slider
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Difficulty Level',
                  border: OutlineInputBorder(),
                ),
                child: Column(
                  children: [
                    Slider(
                      value: _difficulty.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _getDifficultyLabel(_difficulty),
                      onChanged: (value) {
                        setState(() {
                          _difficulty = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Easy'),
                        Text('Moderate'),
                        Text('Hard'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Participant limit
              TextFormField(
                controller: _participantLimitController,
                decoration: const InputDecoration(
                  labelText: 'Participant Limit',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a participant limit';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price settings
              SwitchListTile(
                title: const Text('Free Event'),
                value: _isFree,
                onChanged: (value) {
                  setState(() {
                    _isFree = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),

              if (!_isFree)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Price (\$)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _price = value;
                  },
                  validator: (value) {
                    if (!_isFree && (value == null || value.isEmpty)) {
                      return 'Please enter a price';
                    }
                    return null;
                  },
                ),

              // Error message if any
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 24),

              // Submit button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _createEvent,
                icon: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Icon(Icons.add_circle_outline),
                label: Text(_isLoading ? 'CREATING...' : 'CREATE EVENT'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Very Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Moderate';
      case 4:
        return 'Challenging';
      case 5:
        return 'Very Difficult';
      default:
        return 'Moderate';
    }
  }
}