
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

class TrailListScreenState extends State<TrailListScreen> {
  List<TrailData> events = [];
  List<TrailData> filteredEvents = []; // Store filtered events
  final Set<TrailData> joinedEvents = {};
  bool _isLoading = true;
  String _errorMessage = '';
  late DatabaseService dbService;

  // Filter related variables
  String _selectedDifficulty = 'All'; // Default filter is 'All'
  final List<String> _difficultyOptions = ['All', 'Easy', 'Moderate', 'Hard'];

  // Calendar-related variables
  late DeviceCalendarPlugin _calendarPlugin;
  List<Calendar>? _availableCalendars;

  @override
  void initState() {
    super.initState();
    // Initialize timezone data
    tz_data.initializeTimeZones();
    _calendarPlugin = DeviceCalendarPlugin();
    _checkAndRequestCalendarPermissions(); // Check and request calendar permissions
    _getAvailableCalendars(); // Load calendars
  }

  // Apply filter based on selected difficulty
  void _applyFilter() {
    setState(() {
      if (_selectedDifficulty == 'All') {
        filteredEvents = List.from(events);
      } else {
        filteredEvents = events
            .where((event) => event.trailDifficulty == _selectedDifficulty)
            .toList();
      }
    });
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
      // Check if we have permissions using device_calendar's methods
      final permissionsResult = await _calendarPlugin.hasPermissions();
      print('Initial calendar permission status: ${permissionsResult.data}');

      if (permissionsResult.data == null || permissionsResult.data == false) {
        // Request permissions if needed
        final requestResult = await _calendarPlugin.requestPermissions();
        print('Calendar permission request result: ${requestResult.data}');

        if (requestResult.data == null || requestResult.data == false) {
          print('Calendar permission denied after request');
          setState(() {
            _availableCalendars = [];
          });
          return;
        }
      }

      // Permissions should be granted now, try to retrieve calendars
      print('Retrieving calendars...');
      final calendarsResult = await _calendarPlugin.retrieveCalendars();
      print('Calendar retrieval result: ${calendarsResult.isSuccess}');

      if (calendarsResult.isSuccess && calendarsResult.data != null && calendarsResult.data!.isNotEmpty) {
        setState(() {
          _availableCalendars = calendarsResult.data;
        });

        // Debug available calendars
        for (var calendar in _availableCalendars!) {
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
      setState(() {
        _availableCalendars = [];
      });
    } catch (e) {
      print('Exception in _getAvailableCalendars: ${e.toString()}');
      setState(() {
        _availableCalendars = [];
      });
    }
  }

  // Method to generate a unique URL for each trail
  String _generateTrailUrl(TrailData event) {
    // Generate a unique URL for the trail using trailId
    return 'https://hikerconnect.app/trail/${event.trailId}';
  }

  // Method to show the share dialog for a trail
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Share.share(
                  'Join me on this trail! ${event.trailName}\n${event.trailDescription}\nLocation: ${event.trailLocation}\nDate: ${event.trailDate.toString().split(' ')[0]}\n\n$trailUrl',
                );
              },
              child: const Text('Share'),
            ),
          ],
        );
      },
    );
  }

  // Method to show join dialog with URL field
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
              onPressed: () {
                Navigator.of(context).pop();
              },
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
                      //orElse: () => TrailData,
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
    if (joinedEvents.contains(event)) {
      _unjoinEvent(event);
    } else {
      _joinEvent(event);
    }
  }

  void _unjoinEvent(TrailData event) {
    setState(() {
      joinedEvents.remove(event);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have unjoined the trail "${event.trailName}".')),
      );
    });
  }

  void _joinEvent(TrailData event) {
    setState(() {
      joinedEvents.add(event);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have joined the trail "${event.trailName}"!')),
      );
    });
  }

  void _showCalendarSelectionDialog(TrailData event) {
    // We'll refresh the calendar list just before showing the dialog to ensure we have the latest
    _getAvailableCalendars().then((_) {
      if (_availableCalendars == null || _availableCalendars!.isEmpty) {
        // Enhanced error handling with options to fix
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('No Calendars Available'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No calendars were found on your device. This could be due to:'),
                  const SizedBox(height: 8),
                  const Text('1. Calendar permissions not granted'),
                  const Text('2. No calendar app is installed or configured'),
                  const Text('3. Your device uses a different calendar system'),
                  const SizedBox(height: 16),
                  const Text('Would you like to try again?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _checkAndRequestCalendarPermissions().then((_) => _getAvailableCalendars());
                  },
                  child: const Text('Request Permissions Again'),
                ),
              ],
            );
          },
        );
        return;
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Calendar'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: _availableCalendars!.length,
                itemBuilder: (context, index) {
                  final calendar = _availableCalendars![index];
                  final isGoogleCalendar = calendar.accountType?.toLowerCase().contains('google') ?? false;
                  final icon = isGoogleCalendar
                      ? const Icon(Icons.calendar_month, color: Colors.blue)
                      : const Icon(Icons.calendar_today);

                  return ListTile(
                    leading: icon,
                    title: Text(calendar.name ?? 'Unknown Calendar'),
                    subtitle: Text(calendar.accountName ?? 'Unknown Account'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _addEventToCalendar(event, calendar);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _addEventToCalendar(TrailData event, Calendar calendar) async {
    try {
      final location = tz.local;

      final eventStart = tz.TZDateTime(
        location,
        event.trailDate.year,
        event.trailDate.month,
        event.trailDate.day,
        event.trailDate.hour,
        event.trailDate.minute,
      );

      final eventEnd = tz.TZDateTime(
        location,
        event.trailDate.year,
        event.trailDate.month,
        event.trailDate.day,
        event.trailDate.hour,
        event.trailDate.minute,
      ).add(event.trailDuration);

      // Create event
      final eventToCreate = Event(
        calendar.id,
        title: event.trailName,
        description: "Hiking trail: ${event.trailDescription}\nDifficulty: ${event.trailDifficulty}\nNotice: ${event.trailNotice}",
        start: eventStart,
        end: eventEnd,
        location: event.trailLocation,
      );

      print('Creating event in calendar: ${calendar.name} (${calendar.id})');
      print('Event details: ${eventToCreate.title}, ${eventToCreate.start}, ${eventToCreate.end}');

      final createResult = await _calendarPlugin.createOrUpdateEvent(eventToCreate);

      if (createResult != null) {
        print('Create result success: ${createResult.isSuccess}');
        if (!createResult.isSuccess) {
          print('Error messages: ${createResult.errors?.map((e) => e.errorMessage).join(", ")}');
        } else if (createResult.data != null) {
          print('Created event ID: ${createResult.data}');
        }
      }

      if (createResult != null && createResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trail added to ${calendar.name} successfully!')),
        );
      } else {
        String errorMsg = 'Unknown error';
        if (createResult?.errors != null && createResult!.errors!.isNotEmpty) {
          errorMsg = createResult.errors!.map((e) => e.errorMessage).join(", ");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add trail to calendar: $errorMsg')),
        );
      }
    } catch (e) {
      print('Calendar error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calendar error: ${e.toString()}')),
      );
    }
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
          _applyFilter(); // Apply filter to update filteredEvents
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
                _applyFilter(); // Apply filter to update filteredEvents
              }
            });
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
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Deleting trail...')),
                );

                // Delete from both databases
                await dbService.deleteTrail(event.trailId);

                // Update UI state
                setState(() {
                  events.remove(event);
                  _applyFilter(); // Apply filter to update filteredEvents
                });

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trail deleted successfully')),
                );

                // Navigate back
                Navigator.pop(context);
              } catch (e) {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting trail: ${e.toString()}')),
                );
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

  // FIXED VERSION: Simplified to avoid conflicts and race conditions
  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // First get local trails
      List<TrailData> localTrails = await dbService.getTrails();

      // Update state with local trails immediately for better UX
      if (localTrails.isNotEmpty) {
        setState(() {
          events = localTrails;
          _applyFilter(); // Apply filter to update filteredEvents
        });
      }

      // Then get cloud trails
      List<TrailData> cloudTrails = await dbService.getTrailsFromFirestore();

      // Create a map to combine trails, with cloud trails taking precedence
      final Map<int, TrailData> trailMap = {};

      // Add local trails first
      for (var trail in localTrails) {
        trailMap[trail.trailId] = trail;
      }

      // Then override with cloud trails (if any)
      for (var trail in cloudTrails) {
        trailMap[trail.trailId] = trail;
      }

      // Update state with combined data
      setState(() {
        events = trailMap.values.toList();
        _applyFilter(); // Apply filter to update filteredEvents
        _isLoading = false;
      });

      // If we had no trails at all, show error message
      if (events.isEmpty) {
        setState(() {
          _errorMessage = 'No trails found';
        });
      }
    } catch (e) {
      print('Error in _loadEvents: $e');
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
    if (newValue != null) {
    setState(() {
    _selectedDifficulty = _selectedDifficulty = newValue;
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

      // Trail list - FIXED: Removed FutureBuilder to avoid race conditions
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
                        Text('Trail Type: ${event.trailType}', style: const TextStyle(fontSize: 14)),
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
                            TextButton(
                              onPressed: () => _showCalendarSelectionDialog(event),
                              child: const Text(
                                'Add to Calendar',
                                style: TextStyle(fontWeight: FontWeight.bold),
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