import 'package:flutter/material.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:provider/provider.dart';
import '../../services/databaseservice.dart';
import 'traileventform_screen.dart' as create_screen;
import 'event_edit_screen.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  EventsListScreenState createState() => EventsListScreenState();
}

class EventsListScreenState extends State<EventsListScreen> {
  List<TrailData> events = [];
  final Set<TrailData> joinedEvents = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedEventType = 'All'; // Variable to filter events
  late DatabaseService dbService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dbService = Provider.of<DatabaseService>(context, listen: false);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    // Prevent setState if widget is not mounted
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First get all trails from local storage
      List<TrailData> allTrails = await dbService.getTrails();
      print("EVENTS SCREEN: Retrieved ${allTrails.length} total items from Hive");

      // Filter to only include items with trailType = 'Event'
      List<TrailData> eventTrails = allTrails.where((trail) =>
      trail.trailType == 'Event'
      ).toList();

      print("EVENTS SCREEN: After filtering, found ${eventTrails.length} Event items");

      // Safely update state if widget is still mounted
      if (mounted) {
        setState(() {
          events = eventTrails;
          _isLoading = false;
        });
      }

      // Then fetch from Firestore
      List<TrailData> cloudTrails = await dbService.getTrailsFromFirestore();
      print("EVENTS SCREEN: Retrieved ${cloudTrails.length} total items from Firestore");

      if (cloudTrails.isNotEmpty) {
        // Merge local and cloud trails
        final Map<int, TrailData> trailMap = {};

        // Add local event trails to map
        for (var trail in eventTrails) {
          trailMap[trail.trailId] = trail;
        }

        // Add or override with cloud trails, but only events
        int eventCount = 0;
        for (var trail in cloudTrails) {
          if (trail.trailType == 'Event') {
            trailMap[trail.trailId] = trail;
            eventCount++;
          }
        }
        print("EVENTS SCREEN: Found $eventCount Event items in Firestore");

        // Safely update state if widget is still mounted
        if (mounted) {
          setState(() {
            events = trailMap.values.toList();
            _isLoading = false;
          });
        }
      } else if (eventTrails.isEmpty) {
        // Safely update state if widget is still mounted
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No events found';
          });
        }
      }
    } catch (e) {
      print("EVENTS SCREEN ERROR: $e");
      // Safely update state if widget is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading events: $e';
        });
      }
    }
  }

  // Method to handle changing the selected event type
  void _onEventTypeChanged(String? newType) {
    // Safely update state if widget is still mounted
    if (mounted) {
      setState(() {
        _selectedEventType = newType ?? 'All';
      });
    }
    _loadEvents(); // Reload events based on the new type
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Refresh events',
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Type Filter Dropdown (optional)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedEventType,
              onChanged: _onEventTypeChanged,
              items: <String>['All', 'Concert', 'Meetup', 'Workshop']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),

          // Event List
          Expanded(
            child: _isLoading
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
                    'No events yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push<TrailData>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const create_screen.EventFormScreen(),
                        ),
                      ).then((newEvent) {
                        if (newEvent != null && newEvent.trailName.isNotEmpty && mounted) {
                          setState(() {
                            events.add(newEvent);
                          });
                        }
                      });
                    },
                    child: const Text('Create an Event'),
                  ),
                ],
              ),
            )
                : ListView.builder(
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
                        Text('Type: ${event.trailType}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text('Difficulty: ${event.trailDifficulty}', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 5),
                        Text('Notice: ${event.trailNotice}', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 5),
                        Text('Date: ${event.trailDate.toString().split(' ')[0]}', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 5),
                        Text('Participants: ${event.trailParticipantNumber}', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 5),
                        Text('Duration: ${event.trailDuration.inHours}h ${event.trailDuration.inMinutes % 60}m', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 5),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Join/Unjoin Button
                            Flexible(
                              child: ElevatedButton.icon(
                                onPressed: () => _toggleJoinEvent(event),
                                icon: Icon(
                                  isJoined ? Icons.remove_circle : Icons.event_available,
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
                              tooltip: 'Edit Event',
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const create_screen.EventFormScreen(),
            ),
          ).then((_) {
            if (mounted) {
              _loadEvents();
            }
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Add New Event',
      ),
    );
  }

  void _toggleJoinEvent(TrailData event) {
    // Safely update state if widget is still mounted
    if (mounted) {
      setState(() {
        if (joinedEvents.contains(event)) {
          joinedEvents.remove(event);
        } else {
          joinedEvents.add(event);
        }
      });
    }
  }

  void _navigateToEventEdit(TrailData event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventEditScreen(
          event: event,
          onUpdate: (updatedEvent) {
            // Safely update state if widget is still mounted
            if (mounted) {
              setState(() {
                int index = events.indexWhere((e) => e.trailId == event.trailId);
                if (index != -1) {
                  events[index] = updatedEvent;
                }
              });
            }
          },
          onDelete: () async {
            // Show a confirmation dialog first
            final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Event'),
                content: const Text('Are you sure you want to delete this event? This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ) ?? false;

            if (shouldDelete) {
              try {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleting event...')),
                );

                // Delete from both databases
                await dbService.deleteTrail(event.trailId);

                // Update UI state only if widget is still mounted
                if (mounted) {
                  setState(() {
                    events.remove(event);
                  });

                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event deleted successfully')),
                  );

                  // Navigate back
                  Navigator.pop(context);
                }
              } catch (e) {
                // Show error message only if widget is still mounted
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting event: ${e.toString()}')),
                  );
                }
              }
            }
          },
        ),
      ),
    );
  }
}