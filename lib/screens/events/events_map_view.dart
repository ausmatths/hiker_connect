import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/event_data.dart';
import '../../providers/events_provider.dart'; // Updated to use EventsProvider
import '../trails/event_detail_screen.dart';

class EventsMapView extends StatefulWidget {
  final List<EventData> events;
  // We can add these parameters for consistency, though they're not directly used in the map view
  final bool hasMoreEvents;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const EventsMapView({
    Key? key,
    required this.events,
    this.hasMoreEvents = false,
    this.isLoadingMore = false,
    this.onLoadMore = _defaultOnLoadMore,
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

  @override
  Widget build(BuildContext context) {
    // Filter events with valid coordinates
    final eventsWithCoordinates = widget.events.where((event) =>
    event.latitude != null && event.longitude != null).toList();

    // Default center (can be changed based on user's location)
    final LatLng defaultCenter = eventsWithCoordinates.isNotEmpty
        ? LatLng(eventsWithCoordinates.first.latitude!, eventsWithCoordinates.first.longitude!)
        : LatLng(37.7749, -122.4194); // San Francisco as fallback

    return Column(
      children: [
        if (eventsWithCoordinates.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No events with location data found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),

        // Loading indicator when more events are being loaded
        if (widget.isLoadingMore)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading more events...',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ],
            ),
          ),

        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: defaultCenter,
              zoom: 10.0,
              interactiveFlags: InteractiveFlag.all,
              onTap: (_, __) {
                // Clear selection when tapping on the map
                setState(() {
                  _selectedEvent = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.hiker_connect',
              ),
              // Event markers - optimize for large numbers
              MarkerLayer(
                markers: eventsWithCoordinates.map((event) {
                  final isSelected = _selectedEvent?.id == event.id;
                  return Marker(
                    point: LatLng(event.latitude!, event.longitude!),
                    width: 30,
                    height: 30,
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
                                      : Colors.red,
                                  size: 30,
                                ),
                                if (isSelected)
                                  const Positioned.fill(
                                    child: Icon(
                                      Icons.circle,
                                      color: Colors.white,
                                      size: 12,
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
                  children: [
                    Expanded(
                      child: Text(
                        _selectedEvent!.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
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
                const SizedBox(height: 8.0),
                Text(
                  _selectedEvent!.location ?? 'Unknown location', // Added null check
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedEvent!.attendees?.length ?? 0} attending',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // "Load More" button at the bottom when there are more events
        if (widget.hasMoreEvents && !widget.isLoadingMore)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: widget.onLoadMore,
              child: const Text('Load More Events'),
            ),
          ),
      ],
    );
  }
}