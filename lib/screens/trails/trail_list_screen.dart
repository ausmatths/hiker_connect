import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hiker_connect/models/trail_data.dart';
import '../../services/databaseservice.dart';
import 'event_edit_screen.dart';
import 'eventform_screen.dart' as create_screen;


class TrailListScreen extends StatefulWidget {
  const TrailListScreen({super.key});

  @override
  TrailListScreenState createState() => TrailListScreenState();
}

class TrailListScreenState extends State<TrailListScreen> {
  List<TrailData> events = [];
  final Set<TrailData> joinedEvents = {};

  void _toggleJoinEvent(TrailData event) {
    setState(() {
      if (joinedEvents.contains(event)) {
        joinedEvents.remove(event);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have unjoined the trail.')),
        );
      } else {
        joinedEvents.add(event);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have joined the trail!')),
        );
      }
    });
  }

  void _navigateToEventForm() {
    Navigator.push<TrailData>(
      context,
      MaterialPageRoute(
        builder: (context) => const create_screen.EventFormScreen(), // Use alias
      ),
    ).then((newEvent) {
      if (newEvent != null && newEvent.trailName.isNotEmpty) {
        setState(() {
          events.add(newEvent);
        });
      }
    });
  }

  void _navigateToEventEdit(TrailData event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventEditScreen(
          event: event,
          onUpdate: (updatedEvent) {
            setState(() {
              int index = events.indexWhere((e) => e.trailName == event.trailName);
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
  Future<void> _loadEvents() async {
    List<TrailData> trailList = await DatabaseService.instance.getTrails();
    setState(() {
      events = trailList;
    });
  }
  @override
  void initState() {
    super.initState();
    _loadEvents(); // Fetch events when the screen is loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trails')),
      body: events.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching events
          : ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: events.length, // Total number of items in the list
          itemBuilder: (context, index) {
            final event = events[index]; // Get event at current index
            bool isJoined = joinedEvents.contains(event);
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  Text(
                    event.trailName.isNotEmpty ? event.trailName : "Untitled Event",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),

                  // Event Description
                  if (event.trailDescription.isNotEmpty)
                    Text(event.trailDescription, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 5),

                  // Event Details
                  Text('Location: ${event.trailLocation}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  Text('Difficulty: ${event.trailDifficulty}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Text('Notice: ${event.trailNotice}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  Text('Date: ${event.trailDate.toString().split(' ')[0]}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  Text('Participants: ${event.trailParticipantNumber}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),
                  Text('Duration: ${event.trailDuration.inHours}h ${event.trailDuration.inMinutes % 60}m', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 5),

                  if (event.trailImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: event.trailImages.map((imagePath) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.file(
                              File(imagePath),  // Convert the path string to a File object
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 80,
                                  width: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Join/Unjoin Button
                      TextButton.icon(
                        onPressed: () => _toggleJoinEvent(event),
                        icon: Icon(isJoined ? Icons.remove_circle : Icons.hiking, color: isJoined ? Colors.red : Colors.green),
                        label: Text(isJoined ? 'Unjoin' : 'Join'),
                      ),
                      // Edit Button
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
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEventForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
