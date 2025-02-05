import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hiker_connect/models/trail_model.dart';
import '../../models/trail_data.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key});

  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noticeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  String _difficulty = 'Easy';
  DateTime? _eventDate;
  List<File> _eventImages = [];
  int _selectedHours = 0;
  int _selectedMinutes = 0;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _eventImages.add(File(pickedFile.path));
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      String durationString = '$_selectedHours hrs $_selectedMinutes min';

      TrailData newEvent = TrailData(
        name: 'New Event',
        description: _descriptionController.text,
        difficulty: _difficulty,
        notice: _noticeController.text,
        images: _eventImages,
        date: _eventDate ?? DateTime.now(),
        location: _locationController.text,
        participants: int.parse(_participantsController.text),
        duration: durationString,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event Created Successfully!')),
      );

      Navigator.pop(context, newEvent);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Event Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter event description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: _difficulty,
                  items: ['Easy', 'Moderate', 'Hard']
                      .map((level) => DropdownMenuItem(value: level, child: Text(level)))
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
                  controller: _noticeController,
                  decoration: const InputDecoration(
                    labelText: 'Notice (e.g., special instructions)',
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
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _participantsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Number of Participants',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the number of participants';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),

                // Date Picker
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
                          _eventDate == null
                              ? 'Select Event Date'
                              : 'Event Date: ${_eventDate!.toLocal()}'.split(' ')[0],
                          style: TextStyle(fontSize: 16.0),
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
                        onChanged: (value) {
                          setState(() {
                            _selectedHours = value!;
                          });
                        },
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
                        onChanged: (value) {
                          setState(() {
                            _selectedMinutes = value!;
                          });
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

                // Image Upload
                Wrap(
                  children: _eventImages
                      .map((image) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.file(image, height: 100, width: 100),
                  ))
                      .toList(),
                ),
                TextButton(
                  onPressed: _pickImage,
                  child: const Text('Upload Image'),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Save Event'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
