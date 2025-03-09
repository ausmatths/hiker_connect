import 'package:flutter/material.dart';
import 'package:hiker_connect/models/event_data.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:provider/provider.dart';
import '../../services/databaseservice.dart';
import '../../providers/events_provider.dart';
import 'traileventform_screen.dart' as create_screen;
import 'event_edit_screen.dart';
import 'event_detail_screen.dart';
import 'package:hiker_connect/screens/events/events_browsing_screen.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  EventsListScreenState createState() => EventsListScreenState();
}

class EventsListScreenState extends State<EventsListScreen> {
  List<TrailData> localEvents = [];
  final Set<String> joinedEventIds = {};
  bool _isLoadingLocal = true;
  String _errorMessage = '';
  String _selectedEventType = 'All'; // Variable to filter events
  late DatabaseService dbService;
  late EventsProvider eventsProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Don't call provider methods in initState
    _isInitialized = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      dbService = Provider.of<DatabaseService>(context, listen: false);
      eventsProvider = Provider.of<EventsProvider>(context, listen: false);

      // Initialize the events provider if not already initialized
      if (!eventsProvider.initialized) {
        eventsProvider.initialize();
      }

      // Load local events without triggering a build during initialization
      Future.microtask(() => _loadLocalEvents());
    }
  }

  Future<void> _loadLocalEvents() async {
    // Prevent setState if widget is not mounted
    if (!mounted) return;

    setState(() {
      _isLoadingLocal = true;
      _errorMessage = '';
    });

    try {
      // First get all trails from local storage
      List<TrailData> allTrails = await dbService.getTrails();
      print(
          "EVENTS SCREEN: Retrieved ${allTrails.length} total items from Hive");

      // Filter to only include items with trailType = 'Event'
      List<TrailData> eventTrails = allTrails.where((trail) =>
      trail.trailType == 'Event'
      ).toList();

      print("EVENTS SCREEN: After filtering, found ${eventTrails
          .length} Event items");

      // Safely update state if widget is still mounted
      if (mounted) {
        setState(() {
          localEvents = eventTrails;
          _isLoadingLocal = false;
        });
      }

      // Then fetch from Firestore
      List<TrailData> cloudTrails = await dbService.getTrailsFromFirestore();
      print("EVENTS SCREEN: Retrieved ${cloudTrails
          .length} total items from Firestore");

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
            localEvents = trailMap.values.toList();
            _isLoadingLocal = false;
          });
        }
      } else if (eventTrails.isEmpty) {
        // Safely update state if widget is still mounted
        if (mounted) {
          setState(() {
            _isLoadingLocal = false;
            _errorMessage = 'No local events found';
          });
        }
      }
    } catch (e) {
      print("EVENTS SCREEN ERROR: $e");
      // Safely update state if widget is still mounted
      if (mounted) {
        setState(() {
          _isLoadingLocal = false;
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
    _loadLocalEvents(); // Reload events based on the new type
  }

  void _refreshAll() {
    _loadLocalEvents();
    eventsProvider.refresh(); // Use the refresh method of the new provider
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Events'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshAll,
              tooltip: 'Refresh events',
            ),
            // Add sign-in button if not authenticated
            if (!eventsProvider.isAuthenticated)
              IconButton(
                icon: const Icon(Icons.login),
                onPressed: () async {
                  await eventsProvider.signIn();
                  if (mounted) setState(() {});
                },
                tooltip: 'Sign in with Google',
              ),
            // Add sign-out button if authenticated
            if (eventsProvider.isAuthenticated)
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await eventsProvider.signOut();
                  if (mounted) setState(() {});
                },
                tooltip: 'Sign out',
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Hiking Events'),
              Tab(text: 'My Events'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // External events from Google Events API
            _buildGoogleEventsTab(),

            // Local events tab
            _buildLocalEventsTab(),
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
                _loadLocalEvents();
              }
            });
          },
          child: const Icon(Icons.add),
          tooltip: 'Add New Event',
        ),
      ),
    );
  }

  Widget _buildGoogleEventsTab() {
    // Here, we'll use our new events browsing screen instead of the previous Eventbrite tab
    return Consumer<EventsProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  provider.isUsingLocalData ? Icons.wifi_off : Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(provider.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.refresh(),
                  child: const Text('Try Again'),
                ),
                if (!provider.isAuthenticated)
                  ElevatedButton.icon(
                    onPressed: () => provider.signIn(),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with Google'),
                  ),
              ],
            ),
          );
        }

        if (provider.events.isEmpty) {
          return const Center(
            child: Text('No events found'),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            // Check if we're near the bottom of the list (90% scrolled)
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9) {
              // Check if we have more events and aren't already loading
              if (provider.hasMoreEvents && !provider.isLoadingMore) {
                // Load more events
                provider.fetchEvents(loadMore: true);
              }
            }
            return true;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            // Add 1 to the item count if we have more events to show a loading indicator
            itemCount: provider.events.length + (provider.hasMoreEvents ? 1 : 0),
            itemBuilder: (context, index) {
              // If we're at the end of the list and have more events, show a loading indicator
              if (index == provider.events.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final event = provider.events[index];
              final isJoined = provider.isRegisteredForEvent(event.id);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(eventId: event.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Image if available
                        if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              event.imageUrl!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 120,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 40),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 10),

                        // Event Name
                        Text(
                          event.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),

                        // Event Date
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${event.eventDate.year}-${event.eventDate.month.toString().padLeft(2, '0')}-${event.eventDate.day.toString().padLeft(2, '0')} at ${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Event Location
                        if (event.location != null && event.location!.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location!,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 10),

                        // Join/Unjoin Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Category and Difficulty
                            Row(
                              children: [
                                if (event.category != null)
                                  Chip(
                                    label: Text(event.category!),
                                    backgroundColor: Colors.blue[50],
                                    labelStyle: TextStyle(color: Colors.blue[800]),
                                  ),
                                const SizedBox(width: 8),
                                if (event.difficulty != null)
                                  Chip(
                                    label: Text('Difficulty: ${event.difficulty}'),
                                    backgroundColor: Colors.orange[50],
                                    labelStyle: TextStyle(color: Colors.orange[800]),
                                  ),
                              ],
                            ),

                            // Favorite button
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    provider.isFavorite(event.id)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => provider.toggleFavorite(event.id),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => isJoined
                                      ? provider.unregisterFromEvent(event.id)
                                      : provider.registerForEvent(event.id),
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
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLocalEventsTab() {
    return Column(
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
          child: _isLoadingLocal
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty && localEvents.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadLocalEvents,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          )
              : localEvents.isEmpty
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
                    Future.microtask(() {
                      Navigator.push<TrailData>(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const create_screen.EventFormScreen(),
                        ),
                      ).then((newEvent) {
                        if (newEvent != null && newEvent.trailName.isNotEmpty &&
                            mounted) {
                          setState(() {
                            localEvents.add(newEvent);
                          });
                        }
                      });
                    });
                  },
                  child: const Text('Create an Event'),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: localEvents.length,
            itemBuilder: (context, index) {
              final event = localEvents[index];
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
                        event.trailName.isNotEmpty
                            ? event.trailName
                            : "Untitled Event",
                        style: const TextStyle(fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),

                      // Event Description
                      if (event.trailDescription.isNotEmpty)
                        Text(event.trailDescription, style: const TextStyle(
                            fontSize: 16)),
                      const SizedBox(height: 5),

                      // Event Details
                      Text('Location: ${event.trailLocation}',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),
                      Text('Type: ${event.trailType}', style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('Difficulty: ${event.trailDifficulty}',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),
                      Text('Notice: ${event.trailNotice}',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),
                      Text('Date: ${event.trailDate.toString().split(' ')[0]}',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),
                      Text('Participants: ${event.trailParticipantNumber}',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),
                      Text('Duration: ${event.trailDuration.inHours}h ${event
                          .trailDuration.inMinutes % 60}m',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 5),

                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
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
    );
  }

  void _toggleJoinEvent(String eventId) {
    // Safely update state if widget is still mounted
    if (mounted) {
      setState(() {
        if (joinedEventIds.contains(eventId)) {
          joinedEventIds.remove(eventId);
        } else {
          joinedEventIds.add(eventId);
        }
      });
    }
  }

  void _navigateToEventEdit(TrailData event) {
    // Use Future.microtask to avoid build-time issues
    Future.microtask(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EventEditScreen(
                event: event,
                onUpdate: (updatedEvent) {
                  // Safely update state if widget is still mounted
                  if (mounted) {
                    setState(() {
                      int index = localEvents.indexWhere((e) =>
                      e.trailId == event.trailId);
                      if (index != -1) {
                        localEvents[index] = updatedEvent;
                      }
                    });
                  }
                },
                onDelete: () async {
                  // Show a confirmation dialog first
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) =>
                        AlertDialog(
                          title: const Text('Delete Event'),
                          content: const Text(
                              'Are you sure you want to delete this event? This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red)),
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
                          localEvents.remove(event);
                        });

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Event deleted successfully')),
                        );

                        // Navigate back
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      // Show error message only if widget is still mounted
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting event: ${e
                              .toString()}')),
                        );
                      }
                    }
                  }
                },
              ),
        ),
      );
    });
  }
}