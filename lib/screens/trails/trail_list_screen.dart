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

// Create an enum for trail view types similar to events
enum TrailViewType {
  list,
  grid,
  map,
}

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

  // Search and filter related variables
  final TextEditingController _searchController = TextEditingController();
  TrailViewType _currentViewType = TrailViewType.list;

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _handleSearchSubmit(String query) {
    if (!mounted) return;

    setState(() {
      if (query.isEmpty) {
        // If query is empty, reset to original filter
        _applyFilter();
      } else {
        // Apply search filter on top of difficulty filter
        filteredEvents = events
            .where((event) =>
        (_selectedDifficulty == 'All' || event.trailDifficulty == _selectedDifficulty) &&
            (event.trailName.toLowerCase().contains(query.toLowerCase()) ||
                event.trailDescription.toLowerCase().contains(query.toLowerCase()) ||
                event.trailLocation.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  Future<void> _openFilterScreen() async {
    // This would be implemented similar to events filter
    // For now, we'll just use a simple dialog

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Trails'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _difficultyOptions.map((difficulty) {
              return RadioListTile<String>(
                title: Text(
                  difficulty,
                  style: TextStyle(
                    color: _getColorForDifficulty(difficulty),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                value: difficulty,
                groupValue: _selectedDifficulty,
                onChanged: (value) {
                  Navigator.pop(context, value);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedDifficulty = result;
        _applyFilter();
      });
    }
  }

  void _applyFilter() {
    if (!mounted) return;

    setState(() {
      filteredEvents = _selectedDifficulty == 'All'
          ? List.from(events)
          : events.where((event) => event.trailDifficulty == _selectedDifficulty).toList();

      // If there's text in search, apply search filter too
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        filteredEvents = filteredEvents
            .where((event) =>
        event.trailName.toLowerCase().contains(query) ||
            event.trailDescription.toLowerCase().contains(query) ||
            event.trailLocation.toLowerCase().contains(query))
            .toList();
      }

      print("TRAIL SCREEN: After filtering, showing ${filteredEvents.length} trails");
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

  Widget _buildTrailList() {
    return RefreshIndicator(
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
    );
  }

  Widget _buildTrailGrid() {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
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
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.trailName.isNotEmpty ? event.trailName : "Untitled",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.blue, size: 18),
                          onPressed: () => _shareTrail(event),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Share Trail',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Location: ${event.trailLocation}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Difficulty: ${event.trailDifficulty}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getColorForDifficulty(event.trailDifficulty),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${event.trailDate.toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${event.trailParticipantNumber} participants',
                          style: const TextStyle(fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () => _toggleJoinEvent(event),
                          child: Text(
                            joinedEvents.contains(event) ? 'Unjoin' : 'Join',
                            style: TextStyle(
                              color: joinedEvents.contains(event) ? Colors.red : Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
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
    );
  }

  Widget _buildTrailMap() {
    // This would be a map view of trails
    // For now, just show a placeholder
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Map View Coming Soon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'re working on showing ${filteredEvents.length} trails on a map',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentViewType) {
      case TrailViewType.grid:
        return _buildTrailGrid();
      case TrailViewType.map:
        return _buildTrailMap();
      case TrailViewType.list:
      default:
        return _buildTrailList();
    }
  }

  Widget _buildFilterChip(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
        appBar: AppBar(
          // Centered title for a better appearance
          centerTitle: true,
          // Add join button on the left side of the app bar
          leading: IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Join Trail',
            onPressed: _showJoinDialog,
          ),
          title: const Text('Trails'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadEvents,
              tooltip: 'Refresh trails',
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
              children: [
          // Search bar and filter button
          Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search trails...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                  ),
                  onSubmitted: _handleSearchSubmit,
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _openFilterScreen,
                tooltip: 'Filter trails',
              ),
            ],
          ),
        ),

        // Trail count and view type toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${filteredEvents.length} trails found'),
              // View type toggle
              SegmentedButton<TrailViewType>(
                segments: const [
                  ButtonSegment<TrailViewType>(
                    value: TrailViewType.list,
                    icon: Icon(Icons.list),
                  ),
                  ButtonSegment<TrailViewType>(
                    value: TrailViewType.grid,
                    icon: Icon(Icons.grid_view),
                  ),
                  ButtonSegment<TrailViewType>(
                    value: TrailViewType.map,
                    icon: Icon(Icons.map),
                  ),
                ],
                selected: {_currentViewType},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _currentViewType = newSelection.first;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 8.0),

        // Active filters display
        if (_selectedDifficulty != 'All' || _searchController.text.isNotEmpty)
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
      children: [
      Expanded(
      child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_selectedDifficulty != 'All')
            _buildFilterChip(context, 'Difficulty: $_selectedDifficulty'),
          if (_searchController.text.isNotEmpty)
            _buildFilterChip(context, 'Search: ${_searchController.text}'),
        ],
      ),
    ),
    ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedDifficulty = 'All';
              _searchController.clear();
              _applyFilter();
            });
          },
          child: const Text('Clear All'),
        ),
      ],
      ),
    ),

                const Divider(),

                // Main content area
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
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _selectedDifficulty == 'All'
                              ? 'No trails found'
                              : 'No $_selectedDifficulty trails found',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try changing your search or filters',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          onPressed: _loadEvents,
                        ),
                      ],
                    ),
                  )
                      : _buildCurrentView(),
                ),
              ],
          ),
        ),
      // No floating action button - it's managed by HomeScreen
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