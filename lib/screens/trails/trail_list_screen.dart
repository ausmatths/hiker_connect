import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hiker_connect/models/trail_data.dart';
import '../../services/databaseservice.dart';
import 'event_edit_screen.dart';
import 'eventform_screen.dart' as create_screen;
import 'package:provider/provider.dart';

class TrailListScreen extends StatefulWidget {
  const TrailListScreen({super.key});

  @override
  TrailListScreenState createState() => TrailListScreenState();
}

class TrailListScreenState extends State<TrailListScreen> {
  List<TrailData> events = [];
  final Set<TrailData> joinedEvents = {};
  bool _isLoading = true;
  String _errorMessage = '';
  late DatabaseService dbService;

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
        builder: (context) => const create_screen.EventFormScreen(),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dbService = Provider.of<DatabaseService>(context, listen: false);
    _loadEvents(); // Fetch events when the screen is loaded
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First try to load trails from local storage
      List<TrailData> localTrails = await dbService.getTrails();

      setState(() {
        events = localTrails;
        // If we have local data, show it immediately while we fetch from cloud
        _isLoading = localTrails.isEmpty;
      });

      // Then fetch from Firestore to ensure we have the latest data
      List<TrailData> cloudTrails = await dbService.getTrailsFromFirestore();

      if (cloudTrails.isNotEmpty) {
        setState(() {
          // Merge local and cloud trails, preferring cloud versions if there are duplicates
          final Map<int, TrailData> trailMap = {};

          // Add local trails to map
          for (var trail in localTrails) {
            trailMap[trail.trailId] = trail;
          }

          // Add or override with cloud trails
          for (var trail in cloudTrails) {
            trailMap[trail.trailId] = trail;
          }

          events = trailMap.values.toList();
          _isLoading = false;
        });
      } else if (localTrails.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No trails found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading trails: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trails'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh trails',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty && events.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: const Text('Try Again'),
            ),
          ],
        ),
      )
          : events.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No trails yet',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToEventForm,
              child: const Text('Create a Trail'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
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
                      event.trailName.isNotEmpty ? event.trailName : "Untitled Trail",
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
                    Text('Difficulty: ${event.trailDifficulty}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: event.trailDifficulty == 'Easy'
                              ? Colors.green
                              : event.trailDifficulty == 'Hard'
                              ? Colors.red
                              : Colors.orange
                      ),
                    ),
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(imagePath),
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
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
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: () => _toggleJoinEvent(event),
                            icon: Icon(
                              isJoined ? Icons.remove_circle : Icons.hiking,
                              color: isJoined ? Colors.red : Colors.green,
                            ),
                            label: Text(isJoined ? 'Unjoin' : 'Join'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isJoined ? Colors.red[50] : Colors.green[50],
                              foregroundColor: isJoined ? Colors.red : Colors.green,
                            ),
                          ),
                        ),
                        // Edit Button
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToEventEdit(event),
                          tooltip: 'Edit Trail',
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToEventForm,
        child: const Icon(Icons.add),
        tooltip: 'Create New Trail',
      ),
    );
  }
}