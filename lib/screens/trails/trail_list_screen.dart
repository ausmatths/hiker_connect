import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:share_plus/share_plus.dart';
import '../../services/databaseservice.dart';
import 'event_edit_screen.dart';
import 'traileventform_screen.dart' as create_screen;
import 'package:provider/provider.dart';

class TrailListScreen extends StatefulWidget {
  const TrailListScreen({super.key});

  @override
  TrailListScreenState createState() => TrailListScreenState();
}

class TrailListScreenState extends State<TrailListScreen> with AutomaticKeepAliveClientMixin {
  List<TrailData> events = [];
  List<TrailData> filteredEvents = [];
  final Set<TrailData> joinedEvents = {};
  bool _isLoading = true;
  String _errorMessage = '';
  late DatabaseService dbService;

  // Filter related variables
  String _selectedDifficulty = 'All';
  final List<String> _difficultyOptions = ['All', 'Easy', 'Moderate', 'Hard'];

  // Calendar-related variables
  late DeviceCalendarPlugin _calendarPlugin;
  List<Calendar>? _availableCalendars;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _calendarPlugin = DeviceCalendarPlugin();
    _checkAndRequestCalendarPermissions();
    _getAvailableCalendars();
  }

  Future<void> _checkAndRequestCalendarPermissions() async {
    final permissionsResult = await _calendarPlugin.hasPermissions();
    print('Initial calendar permission status: ${permissionsResult.data}');

    if (permissionsResult.data == null || permissionsResult.data == false) {
      final requestResult = await _calendarPlugin.requestPermissions();
      print('Calendar permission request result: ${requestResult.data}');
    } else {
      print('Calendar permission already granted');
    }

    // Check permissions again to verify
    final finalPermissionsResult = await _calendarPlugin.hasPermissions();
    print('Final calendar permission status: ${finalPermissionsResult.data}');
  }

  Future<void> _getAvailableCalendars() async {
    try {
      final permissionsResult = await _calendarPlugin.hasPermissions();

      if (permissionsResult.data == null || permissionsResult.data == false) {
        final requestResult = await _calendarPlugin.requestPermissions();

        if (requestResult.data == null || requestResult.data == false) {
          print('Calendar permission denied after request');
          if (mounted) {
            setState(() {
              _availableCalendars = [];
            });
          }
          return;
        }
      }

      final calendarsResult = await _calendarPlugin.retrieveCalendars();

      if (calendarsResult.isSuccess && calendarsResult.data != null && calendarsResult.data!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _availableCalendars = calendarsResult.data;
          });
        }

        // Debug available calendars
        for (var calendar in _availableCalendars ?? []) {
          print('Calendar found: ${calendar.id}, ${calendar.name}, Account: ${calendar.accountName}, Type: ${calendar.accountType}');
        }
        return;
      } else {
        print('Failed to get calendars or no calendars available: ${calendarsResult.errors}');

        // Enhanced error information
        if (calendarsResult.errors != null && calendarsResult.errors!.isNotEmpty) {
          for (var error in calendarsResult.errors!) {
            print('Calendar retrieval error: ${error.errorMessage}');
          }
        }
      }

      // If no calendars loaded, set to empty list instead of null
      if (mounted) {
        setState(() {
          _availableCalendars = [];
        });
      }
    } catch (e) {
      print('Exception in _getAvailableCalendars: ${e.toString()}');
      if (mounted) {
        setState(() {
          _availableCalendars = [];
        });
      }
    }
  }

  void _applyFilter() {
    if (!mounted) return;

    setState(() {
      filteredEvents = _selectedDifficulty == 'All'
          ? List.from(events)
          : events.where((event) => event.trailDifficulty == _selectedDifficulty).toList();

      print("TRAIL SCREEN: After difficulty filtering, showing ${filteredEvents.length} trails");
    });
  }

  String _generateTrailUrl(TrailData event) {
    return 'https://hikerconnect.app/trail/${event.trailId}';
  }

  void _shareTrail(TrailData event) {
    final trailUrl = _generateTrailUrl(event);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Share Trail'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this unique URL with friends:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        trailUrl,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: trailUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('URL copied to clipboard')),
                        );
                      },
                      tooltip: 'Copy URL',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Share.share(
                  'Join me on this trail! ${event.trailName}\n${event.trailDescription}\nLocation: ${event.trailLocation}\nDate: ${event.trailDate.toString().split(' ')[0]}\n\n$trailUrl',
                );
                Navigator.of(context).pop();
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  void _showJoinDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Join Trail'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paste the trail URL here to join. Find the URL in the share button of the trail'),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Trail URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final url = urlController.text.trim();
                if (url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid URL')),
                  );
                  return;
                }

                // Extract trail ID from URL
                final urlPattern = RegExp(r'trail/(\d+)');
                final match = urlPattern.firstMatch(url);

                if (match != null) {
                  final trailId = int.tryParse(match.group(1) ?? '');
                  if (trailId != null) {
                    // Find the trail by ID
                    final trail = events.firstWhere(
                          (event) => event.trailId == trailId,
                      orElse: () => TrailData(
                        trailId: 0,
                        trailName: '',
                        trailDescription: '',
                        trailDifficulty: '',
                        trailNotice: '',
                        trailImages: [],
                        trailDate: DateTime.now(),
                        trailLocation: '',
                        trailParticipantNumber: 0,
                        trailDuration: const Duration(),
                        trailType: '',
                      ),
                    );

                    if (trail.trailId != 0) {  // Not the empty trail
                      Navigator.of(context).pop();
                      _toggleJoinEvent(trail);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trail not found. Please check the URL and try again.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid trail URL format')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid trail URL format')),
                  );
                }
              },
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }

  void _toggleJoinEvent(TrailData event) {
    if (!mounted) return;

    setState(() {
      if (joinedEvents.contains(event)) {
        joinedEvents.remove(event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have unjoined the trail "${event.trailName}".')),
        );
      } else {
        joinedEvents.add(event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You have joined the trail "${event.trailName}"!')),
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
      if (newEvent != null && newEvent.trailName.isNotEmpty && mounted) {
        setState(() {
          events.add(newEvent);
          _applyFilter();
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
            if (mounted) {
              setState(() {
                int index = events.indexWhere((e) => e.trailId == event.trailId);
                if (index != -1) {
                  events[index] = updatedEvent;
                  _applyFilter();
                }
              });
            }
          },
          onDelete: () async {
            final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Trail'),
                content: const Text('Are you sure you want to delete this trail? This cannot be undone.'),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleting trail...')),
                );

                await dbService.deleteTrail(event.trailId);

                if (mounted) {
                  setState(() {
                    events.remove(event);
                    _applyFilter();
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trail deleted successfully')),
                  );

                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting trail: ${e.toString()}')),
                  );
                }
              }
            }
          },
        ),
      ),
    );
  }

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
      // First get local trails
      List<TrailData> allTrails = await dbService.getTrails();
      print("TRAILS SCREEN: Retrieved ${allTrails.length} total items from Hive");

      // Filter to only show trails (not events)
      List<TrailData> localTrails = allTrails.where((trail) =>
      trail.trailType == 'Trail'
      ).toList();

      print("TRAILS SCREEN: After filtering, found ${localTrails.length} Trail items");

      // Prevent setState if widget is not mounted
      if (!mounted) return;

      // Update state with local trails immediately for better UX
      if (localTrails.isNotEmpty) {
        setState(() {
          events = localTrails;
          _applyFilter();
        });
      }

      // Then get cloud trails
      List<TrailData> cloudTrails = await dbService.getTrailsFromFirestore();
      print("TRAILS SCREEN: Retrieved ${cloudTrails.length} total items from Firestore");

      // Prevent setState if widget is not mounted
      if (!mounted) return;

      // Create a map to combine trails, with cloud trails taking precedence
      final Map<int, TrailData> trailMap = {};

      // Add local trails first
      for (var trail in localTrails) {
        trailMap[trail.trailId] = trail;
      }

      // Then override with cloud trails (if any), but only Trail type
      int trailCount = 0;
      for (var trail in cloudTrails) {
        if (trail.trailType == 'Trail') {
          trailMap[trail.trailId] = trail;
          trailCount++;
        }
      }
      print("TRAILS SCREEN: Found $trailCount Trail items in Firestore");

      // Prevent setState if widget is not mounted
      if (!mounted) return;

      // Update state with combined data
      setState(() {
        events = trailMap.values.toList();
        _applyFilter();
        _isLoading = false;
      });

      // If we had no trails at all, show error message
      if (events.isEmpty && mounted) {
        setState(() {
          _errorMessage = 'No trails found';
        });
      }
    } catch (e) {
      print('Error in _loadEvents: $e');

      // Prevent setState if widget is not mounted
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading trails: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
          // Difficulty dropdown filter
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Text(
                      'Filter by Difficulty: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedDifficulty,
                          isExpanded: true,
                          underline: Container(), // Remove the default underline
                          icon: const Icon(Icons.arrow_drop_down),
                          elevation: 16,
                          style: TextStyle(
                            color: _getColorForDifficulty(_selectedDifficulty),
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null && mounted) {
                              setState(() {
                                _selectedDifficulty = newValue;
                                _applyFilter();
                              });
                            }
                          },
                          items: _difficultyOptions
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(
                                  color: _getColorForDifficulty(value),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Trail list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage, style: const TextStyle(fontSize: 16)))
                : filteredEvents.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      _selectedDifficulty == 'All'
                          ? 'No trails yet'
                          : 'No $_selectedDifficulty trails found',
                      style: const TextStyle(fontSize: 18)
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadEvents,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadEvents,
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: filteredEvents.length,
                itemBuilder: (context, index) {
                  final event = filteredEvents[index];
                  return GestureDetector(
                    onTap: () => _navigateToEventEdit(event),
                    child: Card(
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    event.trailName.isNotEmpty ? event.trailName : "Untitled Trail",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share, color: Colors.blue),
                                  onPressed: () => _shareTrail(event),
                                  tooltip: 'Share Trail',
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            if (event.trailDescription.isNotEmpty)
                              Text(event.trailDescription, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 5),
                            Text('Location: ${event.trailLocation}', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 5),
                            Text('Type: ${event.trailType}', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 5),
                            Text(
                              'Difficulty: ${event.trailDifficulty}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _getColorForDifficulty(event.trailDifficulty),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text('Notice: ${event.trailNotice}', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 5),
                            Text('Date: ${event.trailDate.toString().split(' ')[0]}', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 5),
                            Text('Participants: ${event.trailParticipantNumber}', style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 5),
                            Text('Duration: ${event.trailDuration.inHours}h ${event.trailDuration.inMinutes % 60}m',
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 5),
                            // Add Join/Unjoin button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _toggleJoinEvent(event),
                                  child: Text(
                                    joinedEvents.contains(event) ? 'Unjoin' : 'Join',
                                    style: TextStyle(
                                      color: joinedEvents.contains(event) ? Colors.red : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
            ),
          ),
        ],
      ),
      // Two floating action buttons: Add and Join
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Join button
          FloatingActionButton(
            heroTag: 'joinBtn',
            onPressed: _showJoinDialog,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.group_add),
            tooltip: 'Join a Trail with URL',
          ),
          const SizedBox(height: 16),
          // Add button
          FloatingActionButton(
            heroTag: 'addBtn',
            onPressed: _navigateToEventForm,
            child: const Icon(Icons.add),
            tooltip: 'Create New Trail',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Helper method to get color based on difficulty
  Color _getColorForDifficulty(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Moderate':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.blue; // Default color for 'All'
    }
  }
}