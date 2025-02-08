import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:core';

import '../../models/trail_data.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key});

  @override
  _EventFormScreenState createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
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
      if (_eventDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an trail date')),
        );
        return;
      }

      if (_selectedHours == 0 && _selectedMinutes == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid trail duration')),
        );
        return;
      }

      final newEvent = TrailData(
        name: _nameController.text ,
        description: _descriptionController.text,
        difficulty: _difficulty,
        notice: _noticeController.text,
        images: _eventImages.map((image) => image.path).toList(),
        date: _eventDate ?? DateTime.now(),
        location: _locationController.text,
        participants: int.tryParse(_participantsController.text) ?? 0,
        duration: Duration(hours: _selectedHours, minutes: _selectedMinutes),
      );

      Navigator.pop(context, newEvent);
    }
  }

  Future<void> _selectDate() async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today.add(const Duration(days: 1)),
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
      appBar: AppBar(title: const Text('Create Trail')),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Trail Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter Trail name' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Trail Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter Trail description' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter the Trail location' : null,
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
                        _eventDate == null
                            ? 'Select Trail Date'
                            : 'Trail Date: ${DateFormat('yyyy-MM-dd').format(_eventDate!)}',
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
                child: const Text('Save Trail'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
