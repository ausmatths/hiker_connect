import 'package:flutter/material.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:intl/intl.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _participantsController;
  late TextEditingController _noticeController;
  DateTime? _selectedDate;
  String? _selectedDifficulty;
  int _selectedHours = 0;
  int _selectedMinutes = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event.name.toString());
    _locationController = TextEditingController(text: widget.event.location.toString());
    _descriptionController = TextEditingController(text: widget.event.description.toString());
    _participantsController = TextEditingController(text: widget.event.participants.toString());
    _noticeController = TextEditingController(text: widget.event.notice);
    _selectedDate = widget.event.date;
    _selectedDifficulty = widget.event.difficulty;
    _selectedHours = widget.event.duration.inHours;
    _selectedMinutes = widget.event.duration.inMinutes % 60;
  }

  void _saveChanges() {
    widget.onUpdate(
      TrailData(
        name: _nameController.text.isNotEmpty ? _nameController.text : widget.event.name,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : widget.event.description,
        difficulty: _selectedDifficulty ?? widget.event.difficulty,
        notice: _noticeController.text,
        images: widget.event.images,
        date: _selectedDate ?? widget.event.date,
        location: _locationController.text.isNotEmpty ? _locationController.text : widget.event.location,
        participants: int.tryParse(_participantsController.text) ?? widget.event.participants,
        duration: Duration(hours: _selectedHours, minutes: _selectedMinutes),
      ),
    );
    Navigator.pop(context, widget.event);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
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
        title: const Text('Edit Trail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => widget.onDelete(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Trail Name'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Trail Description'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Trail Location'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _noticeController,
              decoration: const InputDecoration(labelText: 'Notice'),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _participantsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of Participants'),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              items: ['Easy', 'Moderate', 'Hard']
                  .map((level) => DropdownMenuItem(
                value: level,
                child: Text(level),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Difficulty Level',
                border: OutlineInputBorder(),
              ),
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
                          ? 'Select Trail Date'
                          : 'Trail Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

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
