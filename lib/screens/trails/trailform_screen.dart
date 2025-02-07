import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TrailEditScreen extends StatefulWidget {
  final String trailName;
  final VoidCallback? onSave;

  const TrailEditScreen({super.key, required this.trailName, this.onSave});

  @override
  _TrailEditScreenState createState() => _TrailEditScreenState();
}

class _TrailEditScreenState extends State<TrailEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noticeController = TextEditingController();
  String _difficulty = 'Easy';
  List<File> _images = [];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Here, you would send data to backend
      widget.onSave?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trail Updated Successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.trailName}')),
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
                    labelText: 'Update Trail Condition',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter trail conditions';
                    }
                    return null;
                  },
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
                  controller: _noticeController,
                  decoration: const InputDecoration(
                    labelText: 'Add Notices (e.g., Washout Warning)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16.0),
                Wrap(
                  children: _images
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
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}