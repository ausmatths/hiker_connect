import 'package:flutter/material.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:provider/provider.dart';
import '../../services/databaseservice.dart';
import 'traileventform_screen.dart' as create_screen;
import 'event_edit_screen.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  TrailListScreenState createState() => TrailListScreenState();
}

class TrailListScreenState extends State<EventsListScreen> {
  List<TrailData> events = [];
  final Set<TrailData> joinedEvents = {};
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedTrailType = 'All'; // Variable to filter events
  late DatabaseService dbService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dbService = Provider.of<DatabaseService>(context, listen: false);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<TrailData> localTrails = await dbService.getTrails();

      // Filter based on selected trailType
      // if (_selectedTrailType != 'All') {
      //   localTrails = localTrails.where((event) => event.trailType == _selectedTrailType).toList();
      // }

      setState(() {
        events = localTrails;
        _isLoading = localTrails.isEmpty;
      });

      List<TrailData> cloudTrails = await dbService.getTrailsFromFirestore();

      if (cloudTrails.isNotEmpty) {
        setState(() {
          // Merge local and cloud trails
          final Map<int, TrailData> trailMap = {};

          // Add local trails to map
          for (var trail in localTrails) {
            trailMap[trail.trailId] = trail;
          }

          // Add or override with cloud trails
          for (var trail in cloudTrails) {
            trailMap[trail.trailId] = trail;
          }

          // Filter again based on selected trailType
          // events = trailMap.values
          //     .where((trail) => _selectedTrailType == 'All' || trail.trailType == _selectedTrailType)
          //     .toList();
          // _isLoading = false;
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

  // Method to handle changing the selected trailType
  void _onTrailTypeChanged(String? newType) {
    setState(() {
      _selectedTrailType = newType ?? 'All';
    });
    _loadEvents(); // Reload events based on the new trail type
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
      body: Column(
        children: [
          // Trail Type Filter Dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedTrailType,
              onChanged: _onTrailTypeChanged,
              items: <String>['All', 'Mountain', 'Forest', 'Coastal']
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
                    'No trails yet',
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
                        if (newEvent != null && newEvent.trailName.isNotEmpty) {
                          setState(() {
                            events.add(newEvent);
                          });
                        }
                      });
                    },
                    child: const Text('Create a Trail'),
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
        ],
      ),
    );
  }

  void _toggleJoinEvent(TrailData event) {
    setState(() {
      if (joinedEvents.contains(event)) {
        joinedEvents.remove(event);
      } else {
        joinedEvents.add(event);
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
              int index = events.indexWhere((e) => e.trailId == event.trailId);
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
}
