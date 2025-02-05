import 'package:flutter/material.dart';
import 'package:hiker_connect/screens/trails/trailform_screen.dart';
import 'package:hiker_connect/models/trail_model.dart';
import 'eventform_screen.dart';

class TrailListScreen extends StatefulWidget {
  const TrailListScreen({super.key});

  @override
  _TrailListScreenState createState() => _TrailListScreenState();
}

class _TrailListScreenState extends State<TrailListScreen> {
  List<Trail> trails = [
    Trail(
        name: 'Trail 1',
        description: 'Description for Trail 1',
        difficulty: 'Easy',
        notice: 'No notices',
        images: []),
    Trail(
        name: 'Trail 2',
        description: 'Description for Trail 2',
        difficulty: 'Moderate',
        notice: 'Washout warning',
        images: []),
    Trail(
        name: 'Trail 3',
        description: 'Description for Trail 3',
        difficulty: 'Hard',
        notice: 'Trail closed',
        images: []),
  ];

  void _navigateToEditScreen(String trailName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrailEditScreen(
          trailName: trailName,
          onSave: () {
            setState(() {}); // Refresh UI after saving
          },
        ),
      ),
    );
  }

  void _navigateToEventForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EventFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trails'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToEventForm, // Add event when pressed
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: trails.length,
        itemBuilder: (context, index) {
          final trail = trails[index];
          return ListTile(
            title: Text(trail.name),
            subtitle: Text(trail.description),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _navigateToEditScreen(trail.name);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEventForm, // Add event when pressed
        child: const Icon(Icons.add),
      ),
    );
  }
}
