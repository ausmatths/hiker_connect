import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/trail_data.dart';
import 'package:hiker_connect/utils/async_context_handler.dart';
import 'package:hiker_connect/utils/logger.dart';

class EventEditScreen extends StatefulWidget {
  final TrailData event;
  final Function(TrailData) onUpdate;
  final VoidCallback onDelete;

  const EventEditScreen({
    super.key,
    required this.event,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  _EventEditScreenState createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _noticeController;
  late TextEditingController _locationController;
  late TextEditingController _participantsController;
  late String _difficulty;
  late DateTime _eventDate;
  late List<String> _eventImages;
  late int _selectedHours;
  late int _selectedMinutes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.trailName);
    _descriptionController = TextEditingController(text: widget.event.trailDescription);
    _noticeController = TextEditingController(text: widget.event.trailNotice);
    _locationController = TextEditingController(text: widget.event.trailLocation);
    _participantsController = TextEditingController(text: widget.event.trailParticipantNumber.toString());
    _difficulty = widget.event.trailDifficulty;
    _eventDate = widget.event.trailDate;
    _eventImages = List.from(widget.event.trailImages);
    _selectedHours = widget.event.trailDuration.inHours;
    _selectedMinutes = widget.event.trailDuration.inMinutes % 60;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _noticeController.dispose();
    _locationController.dispose();
    _participantsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Check image limit
    if (_eventImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }

    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        // Set loading state
        setState(() => _isLoading = true);

        // Pick image with specific constraints
        final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );

        // Add image if picked
        if (pickedFile != null) {
          setState(() {
            _eventImages.add(pickedFile.path);
          });
        }
      },
      onSuccess: () {
        // Ensure loading state is reset
        setState(() => _isLoading = false);
      },
      onError: (error) {
        // Log and show error
        AppLogger.error('Error picking image: ${error.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $error')),
        );

        // Reset loading state
        setState(() => _isLoading = false);
      },
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final updatedEvent = TrailData(
        trailId: widget.event.trailId,
        trailName: _nameController.text,
        trailDescription: _descriptionController.text,
        trailDifficulty: _difficulty,
        trailNotice: _noticeController.text,
        trailImages: _eventImages,
        trailDate: _eventDate,
        trailLocation: _locationController.text,
        trailParticipantNumber: int.tryParse(_participantsController.text) ?? 0,
        trailDuration: Duration(hours: _selectedHours, minutes: _selectedMinutes),
      );

      widget.onUpdate(updatedEvent);
      Navigator.pop(context);
    }
  }

  Future<void> _selectDate() async {
    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _eventDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );

        if (picked != null && picked != _eventDate) {
          setState(() {
            _eventDate = picked;
          });
        }
      },
      onError: (error) {
        AppLogger.error('Error selecting date: ${error.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting date: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Trail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: widget.onDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Trail Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter trail name' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter description' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter location' : null,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _difficulty,
                items: ['Easy', 'Moderate', 'Hard']
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _difficulty = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Difficulty Level',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _noticeController,
                decoration: const InputDecoration(
                  labelText: 'Notice',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _participantsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Number of Participants',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter number of participants' : null,
              ),
              const SizedBox(height: 16.0),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd').format(_eventDate),
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedHours,
                      items: List.generate(24, (index) => index)
                          .map((hour) => DropdownMenuItem(value: hour, child: Text('$hour hrs')))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedHours = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMinutes,
                      items: List.generate(60, (index) => index)
                          .map((minute) => DropdownMenuItem(value: minute, child: Text('$minute min')))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedMinutes = value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Trail Images',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        ..._eventImages.map((imagePath) => Stack(
                          children: [
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _eventImages.remove(imagePath);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )),
                        if (_eventImages.length < 5)
                          GestureDetector(
                            onTap: _isLoading ? null : _pickImage,
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : const Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.grey,
                                size: 32,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('Update Trail'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}