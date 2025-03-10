import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/event_data.dart';
import '../../providers/events_provider.dart';
import '../trails/event_detail_screen.dart';
import 'package:intl/intl.dart';

class EventsMapView extends StatefulWidget {
  final List<EventData> events;
  final bool hasMoreEvents;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final bool showTimeSince;

  const EventsMapView({
    Key? key,
    required this.events,
    this.hasMoreEvents = false,
    this.isLoadingMore = false,
    this.onLoadMore = _defaultOnLoadMore,
    this.showTimeSince = false,
  }) : super(key: key);

  // Default no-op function for onLoadMore
  static void _defaultOnLoadMore() {}

  @override
  State<EventsMapView> createState() => _EventsMapViewState();
}

class _EventsMapViewState extends State<EventsMapView> {
  final MapController _mapController = MapController();
  EventData? _selectedEvent;
  bool _mapInitialized = false;
  bool _clusterMarkers = true;
  double _currentZoom = 10.0;

  @override
  void initState() {
    super.initState();
    // Wait for the map to be properly initialized before manipulating it
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.events.isNotEmpty && mounted) {
        _centerMapOnEvents();
        _mapInitialized = true;
      }
    });
  }

  @override
  void didUpdateWidget(EventsMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If we get new events and the map is already initialized, update the view
    if (widget.events != oldWidget.events &&
        widget.events.isNotEmpty &&
        _mapInitialized &&
        mounted) {
      _centerMapOnEvents();
    }
  }

  @override
  void dispose() {
    _mapController.dispose(); // Properly dispose the controller
    super.dispose();
  }

  void _centerMapOnEvent(EventData event) {
    if (event.latitude != null && event.longitude != null) {
      _mapController.move(
        LatLng(event.latitude!, event.longitude!),
        12.0,
      );
    }
  }

  void _centerMapOnEvents() {
    // Filter events with valid coordinates
    final eventsWithCoordinates = widget.events.where((event) =>
    event.latitude != null && event.longitude != null).toList();

    if (eventsWithCoordinates.isEmpty) return;

    if (eventsWithCoordinates.length == 1) {
      _centerMapOnEvent(eventsWithCoordinates.first);
      return;
    }

    // Find bounds to fit all events on the map
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var event in eventsWithCoordinates) {
      if (event.latitude! < minLat) minLat = event.latitude!;
      if (event.latitude! > maxLat) maxLat = event.latitude!;
      if (event.longitude! < minLng) minLng = event.longitude!;
      if (event.longitude! > maxLng) maxLng = event.longitude!;
    }

    // Add some padding
    minLat -= 0.1;
    maxLat += 0.1;
    minLng -= 0.1;
    maxLng += 0.1;

    // Create bounds and fit map to them
    try {
      _mapController.fitBounds(
        LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        options: const FitBoundsOptions(
          padding: EdgeInsets.all(50.0),
        ),
      );
    } catch (e) {
      // If fitBounds fails, center on the first event
      if (eventsWithCoordinates.isNotEmpty) {
        _centerMapOnEvent(eventsWithCoordinates.first);
      }
    }
  }

  String _getTimeSinceText(DateTime eventDate) {
    final now = DateTime.now();

    // Calculate the difference manually
    final difference = eventDate.difference(now);

    if (difference.isNegative) {
      // Event is in the past
      if (difference.inDays < -365) {
        return '${(-difference.inDays / 365).floor()} years ago';
      } else if (difference.inDays < -30) {
        return '${(-difference.inDays / 30).floor()} months ago';
      } else if (difference.inDays < -1) {
        return '${-difference.inDays} days ago';
      } else if (difference.inHours < -1) {
        return '${-difference.inHours} hours ago';
      } else if (difference.inMinutes < -1) {
        return '${-difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } else {
      // Event is in the future
      if (difference.inDays > 365) {
        return 'In ${(difference.inDays / 365).floor()} years';
      } else if (difference.inDays > 30) {
        return 'In ${(difference.inDays / 30).floor()} months';
      } else if (difference.inDays > 0) {
        return 'In ${difference.inDays} days';
      } else if (difference.inHours > 0) {
        return 'In ${difference.inHours} hours';
      } else if (difference.inMinutes > 0) {
        return 'In ${difference.inMinutes} minutes';
      } else {
        return 'About to start';
      }
    }
  }

  // Get different marker colors based on event date
  Color _getMarkerColor(EventData event) {
    final now = DateTime.now();

    // Past events
    if (event.eventDate.isBefore(now)) {
      return Colors.grey;
    }

    // Events happening today
    if (event.eventDate.year == now.year &&
        event.eventDate.month == now.month &&
        event.eventDate.day == now.day) {
      return Colors.green;
    }

    // Events happening this week
    if (event.eventDate.difference(now).inDays <= 7) {
      return Colors.blue;
    }

    // Default for future events
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('E, MMM d, yyyy • h:mm a');

    // Filter events with valid coordinates
    final eventsWithCoordinates = widget.events.where((event) =>
    event.latitude != null && event.longitude != null).toList();

    // Default center (can be changed based on user's location)
    final LatLng defaultCenter = eventsWithCoordinates.isNotEmpty
        ? LatLng(eventsWithCoordinates.first.latitude!, eventsWithCoordinates.first.longitude!)
        : LatLng(37.7749, -122.4194); // San Francisco as fallback

    return Stack(
      children: [
        Column(
          children: [
            if (eventsWithCoordinates.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No events with location data found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters or adding locations to events',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: defaultCenter,
                    zoom: _currentZoom,
                    interactiveFlags: InteractiveFlag.all,
                    onTap: (_, __) {
                      setState(() {
                        _selectedEvent = null;
                      });
                    },
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture && position.zoom != null) {
                        setState(() {
                          _currentZoom = position.zoom ?? _currentZoom;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.hiker_connect',
                    ),
                    // Event markers
                    MarkerLayer(
                      markers: eventsWithCoordinates.map((event) {
                        final isSelected = _selectedEvent?.id == event.id;
                        return Marker(
                          point: LatLng(event.latitude!, event.longitude!),
                          width: 40,
                          height: 40,
                          builder: (ctx) => GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedEvent = event;
                              });
                              _centerMapOnEvent(event);
                            },
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: isSelected ? 0.8 : 1.0,
                                end: isSelected ? 1.2 : 1.0,
                              ),
                              duration: const Duration(milliseconds: 300),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Stack(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : _getMarkerColor(event),
                                        size: 40,
                                      ),
                                      if (isSelected)
                                        Positioned(
                                          top: 5,
                                          right: 0,
                                          left: 0,
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.primary,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            // Event info card for selected event
            if (_selectedEvent != null)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8.0,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event image if available
                        if (_selectedEvent!.imageUrl != null && _selectedEvent!.imageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              _selectedEvent!.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, error, _) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),

                        SizedBox(width: _selectedEvent!.imageUrl != null ? 12.0 : 0),

                        // Event details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row with favorite button
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedEvent!.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Consumer<EventsProvider>(
                                    builder: (ctx, provider, _) {
                                      final isFavorite = provider.isFavorite(_selectedEvent!.id);
                                      return IconButton(
                                        icon: Icon(
                                          isFavorite ? Icons.favorite : Icons.favorite_border,
                                          color: isFavorite ? Colors.red : null,
                                        ),
                                        onPressed: () => provider.toggleFavorite(_selectedEvent!.id),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              // Category badge if available
                              if (_selectedEvent!.category != null && _selectedEvent!.category!.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4, bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 2.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    _selectedEvent!.category!,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ),

                              // Event date and time
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14.0,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Expanded(
                                    child: Text(
                                      widget.showTimeSince
                                          ? _getTimeSinceText(_selectedEvent!.eventDate)
                                          : dateFormat.format(_selectedEvent!.eventDate),
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4.0),

                              // Event location
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14.0,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Expanded(
                                    child: Text(
                                      _selectedEvent!.location ?? 'Unknown location',
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12.0),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Attendees count
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 16.0),
                            const SizedBox(width: 4.0),
                            Text(
                              '${_selectedEvent!.attendees?.length ?? 0} attending',
                              style: const TextStyle(fontSize: 14.0),
                            ),
                          ],
                        ),

                        // View details button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => EventDetailScreen(
                                  eventId: _selectedEvent!.id,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('View Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),

        // Map controls overlay
        Positioned(
          right: 16,
          top: 16,
          child: Column(
            children: [
              // Zoom buttons
              Card(
                elevation: 4,
                child: Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        _mapController.move(
                          _mapController.center,
                          _mapController.zoom + 1,
                        );
                      },
                      tooltip: 'Zoom in',
                    ),
                    const Divider(height: 1),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        _mapController.move(
                          _mapController.center,
                          _mapController.zoom - 1,
                        );
                      },
                      tooltip: 'Zoom out',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Clustering toggle button
              Card(
                elevation: 4,
                child: IconButton(
                  icon: Icon(_clusterMarkers ? Icons.grid_view : Icons.pin_drop),
                  onPressed: () {
                    setState(() {
                      _clusterMarkers = !_clusterMarkers;
                    });
                  },
                  tooltip: _clusterMarkers ? 'Disable clustering' : 'Enable clustering',
                ),
              ),

              const SizedBox(height: 8),

              // Recenter map button
              Card(
                elevation: 4,
                child: IconButton(
                  icon: const Icon(Icons.center_focus_strong),
                  onPressed: _centerMapOnEvents,
                  tooltip: 'Center map on events',
                ),
              ),
            ],
          ),
        ),

        // Loading indicator
        if (widget.isLoadingMore)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Loading more events...',
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Load more button (only show when at bottom of map and has more events)
        if (widget.hasMoreEvents && !widget.isLoadingMore)
          Positioned(
            bottom: _selectedEvent != null ? 120 : 16, // Position above the event card if visible
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: widget.onLoadMore,
                icon: const Icon(Icons.refresh),
                label: const Text('Load More Events'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}