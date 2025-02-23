import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/services/databaseservice.dart';
import 'package:hiker_connect/utils/async_context_handler.dart';
import 'package:hiker_connect/utils/logger.dart';

class TrailEditScreen extends StatefulWidget {
  final String trailName;
  final Function(TrailData)? onUpdate;

  const TrailEditScreen({
    super.key,
    required this.trailName,
    this.onUpdate
  });

  @override
  _TrailEditScreenState createState() => _TrailEditScreenState();
}

class _TrailEditScreenState extends State<TrailEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noticeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();

  String _difficulty = 'Easy';
  List<String> _images = [];
  DateTime _selectedDate = DateTime.now();
  Duration _duration = const Duration(hours: 1);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrailData();
  }

  Future<void> _loadTrailData() async {
    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        final databaseService = DatabaseService();
        final trail = await databaseService.getTrailByName(widget.trailName);
        if (trail != null) {
          setState(() {
            _descriptionController.text = trail.trailDescription;
            _noticeController.text = trail.trailNotice;
            _locationController.text = trail.trailLocation;
            _participantsController.text = trail.trailParticipantNumber.toString();
            _difficulty = trail.trailDifficulty;
            _images = trail.trailImages;
            _selectedDate = trail.trailDate;
            _duration = trail.trailDuration;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        AppLogger.error('Error loading trail data', stackTrace: StackTrace.current);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading trail data')),
        );
        setState(() => _isLoading = false);
      },
    );
  }

  Future<void> _pickImage() async {
    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (pickedFile != null) {
          setState(() {
            _images.add(pickedFile.path);
          });
        }
      },
      onError: (error) {
        AppLogger.error('Error picking image', stackTrace: StackTrace.current);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error selecting image')),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null && picked != _selectedDate) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      onError: (error) {
        AppLogger.error('Error selecting date', stackTrace: StackTrace.current);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error selecting date')),
        );
      },
    );
  }

  Future<void> _selectDuration() async {
    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: _duration.inHours,
            minute: (_duration.inMinutes % 60),
          ),
        );
        if (picked != null) {
          setState(() {
            _duration = Duration(hours: picked.hour, minutes: picked.minute);
          });
        }
      },
      onError: (error) {
        AppLogger.error('Error selecting duration', stackTrace: StackTrace.current);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error selecting duration')),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        final updatedTrail = TrailData(
          trailId: 0,
          trailName: widget.trailName,
          trailDescription: _descriptionController.text,
          trailDifficulty: _difficulty,
          trailNotice: _noticeController.text,
          trailImages: _images,
          trailDate: _selectedDate,
          trailLocation: _locationController.text,
          trailParticipantNumber: int.parse(_participantsController.text),
          trailDuration: _duration,
        );

       //await DatabaseService.instance.updateTrail(updatedTrail);
        final hivedb= await DatabaseService();
        await hivedb.updateTrail(widget.trailName,updatedTrail);

        // Call onUpdate callback if provided
        widget.onUpdate?.call(updatedTrail);

        AppLogger.info('Trail updated successfully: ${widget.trailName}');
      },
      onSuccess: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trail Updated Successfully!')),
        );
        Navigator.pop(context);
      },
      onError: (error) {
        AppLogger.error('Error updating trail', stackTrace: StackTrace.current);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating trail')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.trailName}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Trail Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter trail description';
                    }
                    return null;
                  },
                  maxLines: 3,
                ),
                const SizedBox(height: 16.0),

                DropdownButtonFormField<String>(
                  value: _difficulty,
                  items: ['Easy', 'Moderate', 'Hard']
                      .map((level) => DropdownMenuItem(
                      value: level, child: Text(level)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _difficulty = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Difficulty Level',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),

                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                TextFormField(
                  controller: _participantsController,
                  decoration: const InputDecoration(
                    labelText: 'Maximum Participants',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter maximum participants';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                TextFormField(
                  controller: _noticeController,
                  decoration: const InputDecoration(
                    labelText: 'Notice',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),

                ListTile(
                  title: const Text('Event Date'),
                  subtitle: Text(_selectedDate.toString().split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                ),

                ListTile(
                  title: const Text('Duration'),
                  subtitle: Text('${_duration.inHours}h ${_duration.inMinutes % 60}m'),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectDuration,
                ),

                const SizedBox(height: 16.0),
                const Text('Trail Images:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                if (_images.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Stack(
                            children: [
                              Image.file(
                                File(_images[index]),
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _images.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Image'),
                ),

                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noticeController.dispose();
    _locationController.dispose();
    _participantsController.dispose();
    super.dispose();
  }
}