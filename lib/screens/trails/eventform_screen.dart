import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/trail_data.dart';
import '../../services/databaseservice.dart';
import 'package:hiker_connect/utils/async_context_handler.dart';
import 'package:hiker_connect/utils/logger.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key});

  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DatabaseService dbService;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noticeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  String _difficulty = 'Easy';
  DateTime? _eventDate;
  final List<File> _eventImages = [];
  int _selectedHours = 0;
  int _selectedMinutes = 0;
  bool _isLoading = false;
  String _selectedType = 'Trail';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get DatabaseService from provider
    dbService = Provider.of<DatabaseService>(context, listen: false);
  }

  Future<void> _pickImage() async {
    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        setState(() {
          _isLoading = true;
        });

        final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          setState(() {
            _eventImages.add(File(pickedFile.path));
          });
        }
        return Future.value();
      },
      onSuccess: () {
        setState(() {
          _isLoading = false;
        });
      },
      onError: (error) {
        AppLogger.error('Error picking image: ${error.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting image: $error')),
        );
        setState(() {
          _isLoading = false;
        });
        return Future.value();
      },
    );
  }

  Future<void> _submitForm() async {
    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        if (!_formKey.currentState!.validate()) {
          return Future.value();
        }

        if (_eventDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a trail date')),
          );
          return Future.value();
        }

        if (_selectedHours == 0 && _selectedMinutes == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a valid trail duration')),
          );
          return Future.value();
        }

        setState(() {
          _isLoading = true;
        });

        final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
        final int uniqueId = DateTime.now().millisecondsSinceEpoch;

        final newEvent = TrailData(
          trailId: uniqueId,
          trailName: _nameController.text,
          trailDescription: _descriptionController.text,
          trailDifficulty: _difficulty,
          trailNotice: _noticeController.text,
          trailImages: _eventImages.map((image) => image.path).toList(),
          trailDate: _eventDate ?? DateTime.now(),
          trailLocation: _locationController.text,
          trailParticipantNumber: int.tryParse(_participantsController.text) ?? 0,
          trailDuration: Duration(hours: _selectedHours, minutes: _selectedMinutes),
        );

        // Use DatabaseService to insert the event - both locally and to cloud
        await dbService.insertTrails(newEvent);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trail saved successfully to local and cloud storage')),
        );

        Navigator.pop(context, newEvent);
        return Future.value();
      },
      onSuccess: () {
        setState(() {
          _isLoading = false;
        });
      },
      onError: (error) {
        AppLogger.error('Error submitting trail: ${error.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving trail: $error')),
        );
        setState(() {
          _isLoading = false;
        });
        return Future.value();
      },
    );
  }

  Future<void> _selectDate() async {
    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        final DateTime today = DateTime.now();
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: today.add(const Duration(days: 1)), // Default to tomorrow
          firstDate: today.add(const Duration(days: 1)), // Restrict past dates
          lastDate: DateTime(2101),
        );

        if (picked != null && picked != _eventDate) {
          setState(() {
            _eventDate = picked;
          });
        }
        return Future.value();
      },
      onError: (error) {
        AppLogger.error('Error selecting date: ${error.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting date: $error')),
        );
        return Future.value();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Trail/Event')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: ['Trail', 'Event']
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _selectedType == 'Trail' ? 'Trail Name' : 'Event Name',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter ${_selectedType == 'Trail' ? 'Trail' : 'Event'} name'
                    : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: _selectedType == 'Trail' ? 'Trail Description' : 'Event Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter ${_selectedType == 'Trail' ? 'Trail' : 'Event'} description'
                    : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter ${_selectedType == 'Trail' ? 'Trail' : 'Event'} Location'
                    : null,
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _difficulty,
                items: ['Easy', 'Moderate', 'Hard']
                    .map((level) => DropdownMenuItem(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) => setState(() => _difficulty = value!),
                decoration: const InputDecoration(
                  labelText: 'Difficulty Level',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _noticeController,
                decoration: const InputDecoration(
                  labelText: 'Notice (e.g., special instructions)',
                  border: OutlineInputBorder(),
                ),
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
                validator: (value) => value == null || value.isEmpty || int.tryParse(value) == null
                    ? 'Please enter a valid number of participants'
                    : null,
              ),
              const SizedBox(height: 16.0),

              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _eventDate ==null
                            ? 'Select ${_selectedType == 'Trail' ? 'Trail' : 'Event'} Date'
                            : '${_selectedType == 'Trail' ? 'Trail Date:' : 'Event Date:'}  ${DateFormat('yyyy-MM-dd').format(_eventDate!)}',
                        // _eventDate == null
                        //     ? 'Select Trail Date'
                        //     : 'Trail Date: ${DateFormat('yyyy-MM-dd').format(_eventDate!)}',
                        // style: const TextStyle(fontSize: 16.0),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Duration Picker (Hours & Minutes)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedHours,
                      items: List.generate(24, (index) => index)
                          .map((hour) => DropdownMenuItem(value: hour, child: Text('$hour hrs')))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedHours = value!),
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMinutes,
                      items: List.generate(60, (index) => index)
                          .map((minute) => DropdownMenuItem(value: minute, child: Text('$minute min')))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedMinutes = value!),
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Image Upload
              Wrap(
                children: _eventImages
                    .map((image) => Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                    children: [
                      Image.file(image, height: 100, width: 100),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _eventImages.remove(image);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.red, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
                    .toList(),
              ),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Upload Image'),
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(_selectedType == 'Trail' ? 'Save Trail' : 'Save Event'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all text editing controllers
    _nameController.dispose();
    _descriptionController.dispose();
    _noticeController.dispose();
    _locationController.dispose();
    _participantsController.dispose();
    super.dispose();
  }
}