import 'package:flutter/material.dart';
import '../../models/trail_data.dart';
import 'event_edit_screen.dart';
import 'eventform_screen.dart';

class TrailListScreen extends StatefulWidget {
  const TrailListScreen({super.key});

  @override
  _TrailListScreenState createState() => _TrailListScreenState();
}

class _TrailListScreenState extends State<TrailListScreen> {
  List<TrailData> events = []; // Store created events
  final Set<TrailData> joinedEvents = {}; // Store events that have been joined

  // Function to toggle joining and unjoining an event
  void _toggleJoinEvent(TrailData event) {
    setState(() {
      if (joinedEvents.contains(event)) {
        joinedEvents.remove(event);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have unjoined the event.')),
        );
      } else {
        joinedEvents.add(event);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have joined the event!')),
        );
      }
    });
  }

  // Navigate to Event Form screen
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

  // Navigate to Event Edit screen
  void _navigateToEventEdit(TrailData event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventEditScreen(
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
        children: events.map((event) {
          bool isJoined = joinedEvents.contains(event); // Check if event is joined
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  Text(event.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  // Event Description
                  Text(event.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  // Event Notice
                  Text('Notice: ${event.notice}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  // Event Location
                  Text('Location: ${event.location}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  // Event Difficulty
                  Text('Difficulty: ${event.difficulty}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  // Event Date
                  Text('Date: ${event.date.toString().split(' ')[0]}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  // Event Participants
                  Text('Participants: ${event.participants}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  // Event Duration
                  Text('Duration: ${event.duration.inHours}h ${event.duration.inMinutes % 60}m', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),

                  // Display Images if available
                  if (event.images.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: event.images.map((imagePath) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.network(imagePath, height: 80, width: 80, fit: BoxFit.cover),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Join and Edit Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Toggle Join/Unjoin Button (left side)
                      TextButton.icon(
                        onPressed: () => _toggleJoinEvent(event), // Toggle join/unjoin
                        icon: Icon(isJoined ? Icons.remove_circle : Icons.hiking, color: isJoined ? Colors.red : Colors.green),
                        label: Text(isJoined ? 'Unjoin' : 'Join'),
                      ),
                      // Edit Button (right side)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _navigateToEventEdit(event),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEventForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
