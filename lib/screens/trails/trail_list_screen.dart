import 'package:flutter/material.dart';
import 'package:hiker_connect/screens/trails/trailform_screen.dart';
import 'package:hiker_connect/models/trail_model.dart';
import '../../models/trail_data.dart';
import 'event_edit_screen.dart';
import 'eventform_screen.dart';

class TrailListScreen extends StatefulWidget {
  const TrailListScreen({super.key});

  @override
  TrailListScreenState createState() => TrailListScreenState();
}

class TrailListScreenState extends State<TrailListScreen> {

  List<TrailData> events = []; // Store created events

  void _navigateToEventForm() {
    Navigator.push<TrailData>(
      context,
      MaterialPageRoute(
        builder: (context) => const EventFormScreen(),
      ),
    ).then((newEvent) {
      if (newEvent != null) {
        setState(() {
          events.add(newEvent); // Add the event to the list
        });
      }
    });
  }

  void _navigateToEventEdit(TrailData event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EventEditScreen(
              event: event,
              onUpdate: (updatedEvent) {
                setState(() {
                  int index = events.indexWhere((e) => e.name == event.name);
                  if (index != -1) {
                    events[index] = updatedEvent;
                  }
                });
              },
              onDelete: () {
                setState(() {
                  events.remove(event);
                });
                Navigator.pop(context);
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trails'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: events.map((event) =>
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Use description instead of name
                    Text(event.description, style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text('Difficulty: ${event.difficulty}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Text('Location: ${event.location}',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 5),
                    Text('Date: ${event.date.toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 5),
                    Text('Participants: ${event.participants}',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 5),
                    Text('Duration: ${event.duration.inHours}h ${event.duration
                        .inMinutes % 60}m',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 5),

                    // Display Images if available
                    if (event.images.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: event.images.map((imagePath) =>
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.network(imagePath, height: 80,
                                    width: 80,
                                    fit: BoxFit.cover),
                              )).toList(),
                        ),
                      ),

                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _navigateToEventEdit(event),
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEventForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}