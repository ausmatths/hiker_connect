import 'package:flutter/material.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:intl/intl.dart'; // For formatting the date

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
  late TextEditingController _participantsController;
  late TextEditingController _noticeController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _participantsController = TextEditingController(text: widget.event.participants.toString());
    _noticeController = TextEditingController(text: widget.event.notice);
    _selectedDate = widget.event.date;
  }

  void _saveChanges() {
    widget.onUpdate(
      TrailData(
        name: widget.event.name,
        description: widget.event.description, // Keep unchanged
        difficulty: widget.event.difficulty,
        notice: _noticeController.text,
        images: widget.event.images,
        date: _selectedDate ?? widget.event.date,
        location: widget.event.location, // Keep unchanged
        participants: int.tryParse(_participantsController.text) ?? widget.event.participants,
        duration: widget.event.duration,
      ),
    );
    Navigator.pop(context, widget.event);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)), // Default to tomorrow
      firstDate: DateTime.now().add(const Duration(days: 1)), // Allow only future dates
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => widget.onDelete(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              initialValue: widget.event.description,
              decoration: const InputDecoration(labelText: 'Event Description'),
              readOnly: true, // Prevent editing
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: widget.event.location,
              decoration: const InputDecoration(labelText: 'Event Location'),
              readOnly: true, // Prevent editing
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _participantsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Participants'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _noticeController,
              decoration: const InputDecoration(labelText: 'Notice'),
            ),
            const SizedBox(height: 20),
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
                      _selectedDate == null
                          ? 'Select Event Date'
                          : 'Event Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
