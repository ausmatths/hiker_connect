import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../models/event_data.dart';
import '../../models/event_filter.dart';
import '../../models/events_view_type.dart';
import '../../providers/events_provider.dart';
import '../../utils/logger.dart';
import '../trails/event_detail_screen.dart';
import 'events_filter_screen.dart';
import 'events_grid_view.dart';
import 'events_list_view.dart';
import 'events_map_view.dart';
import 'package:location/location.dart';
import 'dart:math' as math;

class EventsBrowsingScreen extends StatefulWidget {
  static const routeName = '/events-browsing';

  final bool showAppBar;
  final EventsViewType initialViewType;
  final bool showFAB;
  final bool inHomeContext;

  const EventsBrowsingScreen({
    Key? key,
    this.showAppBar = true,
    this.initialViewType = EventsViewType.list,
    this.showFAB = true,
    this.inHomeContext = false,
  }) : super(key: key);

  @override
  State<EventsBrowsingScreen> createState() => _EventsBrowsingScreenState();
}

class _EventsBrowsingScreenState extends State<EventsBrowsingScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late EventsViewType _currentViewType;
  late TabController _tabController;
  final Location _location = Location();
  bool _isLocationRequested = false;

  @override
  void initState() {
    super.initState();
    _currentViewType = widget.initialViewType;
    _tabController = TabController(length: 3, vsync: this);

    // Refresh events when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EventsProvider>(context, listen: false);
      if (!provider.initialized) {
        provider.initialize();
      } else {
        provider.refresh();
      }

      // Set initial view type
      provider.setViewType(_currentViewType);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleSearchSubmit(BuildContext context) {
    final provider = Provider.of<EventsProvider>(context, listen: false);
    provider.searchEvents(_searchController.text);
  }

  Future<void> _openFilterScreen(BuildContext context) async {
    final provider = Provider.of<EventsProvider>(context, listen: false);

    final result = await Navigator.of(context).push<EventFilter>(
      MaterialPageRoute(
        builder: (ctx) => EventsFilterScreen(
          initialFilter: provider.activeFilter ?? EventFilter(),
        ),
      ),
    );

    if (result != null) {
      provider.applyFilter(result);
    }
  }

  Future<void> _getNearbyEvents() async {
    try {
      // Check if we already have permission, if not, request it
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are required to find nearby events')),
          );
          return;
        }
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        if (!_isLocationRequested) {
          _isLocationRequested = true;
          permission = await _location.requestPermission();
        }
        if (permission == PermissionStatus.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required to find nearby events')),
          );
          return;
        }
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Finding nearby events...'),
            ],
          ),
        ),
      );

      // Get current location
      final locationData = await _location.getLocation();

      // Set radius based on slider or default to 10km
      final radius = 10.0;

      // Close the loading dialog
      Navigator.of(context).pop();

      // Ask for confirmation with distance
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Find Nearby Events'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Search for events within ${radius.toStringAsFixed(1)} km of your current location?'),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      Image.network(
                        'https://maps.googleapis.com/maps/api/staticmap?center=${locationData.latitude},${locationData.longitude}&zoom=13&size=400x400&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.map, size: 64, color: Colors.grey),
                          );
                        },
                      ),
                      Center(
                        child: Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Search'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Use provider to fetch nearby events
        final provider = Provider.of<EventsProvider>(context, listen: false);
        await provider.fetchNearbyEvents(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
          radiusInKm: radius,
        );
      }
    } catch (e) {
      AppLogger.error('Error getting location: $e');

      // Close any open dialogs first
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: ${e.toString()}')),
      );
    }
  }

  void _showJoinEventDialog(BuildContext context) {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste the event URL here to join. Find the URL in the share button of the event'),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'Event URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Handle joining event with URL
              if (urlController.text.isNotEmpty) {
                // Process the URL
                // You'd implement your join logic here
              }
              Navigator.pop(context);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventView(BuildContext context, EventsViewType viewType, List<EventData> events) {
    final provider = Provider.of<EventsProvider>(context, listen: false);

    // Function to handle loading more events
    void loadMoreEvents() {
      if (provider.hasMoreEvents && !provider.isLoadingMore) {
        provider.fetchEvents(loadMore: true);
      }
    }

    switch (viewType) {
      case EventsViewType.grid:
        return EventsGridView(
          events: events,
          hasMoreEvents: provider.hasMoreEvents,
          isLoadingMore: provider.isLoadingMore,
          onLoadMore: loadMoreEvents,
        );
      case EventsViewType.map:
        return EventsMapView(events: events);
      case EventsViewType.list:
      default:
      // Use NotificationListener for EventsListView since it doesn't have pagination parameters
        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9) {
              loadMoreEvents();
            }
            return true;
          },
          child: EventsListView(events: events),
        );
    }
  }

  Widget _buildShimmerLoading(BuildContext context) {
    // Show a simple loading spinner instead of shimmer for now
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildTimeFilterChips(BuildContext context, EventsProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Upcoming'),
            selected: provider.activeFilter?.includeFutureEvents == true &&
                provider.activeFilter?.includePastEvents != true &&
                provider.activeFilter?.includeCurrentEvents != true,
            onSelected: (selected) {
              if (selected) {
                provider.fetchEventsByTimePeriod(false, false, true);
              } else {
                provider.clearFilters();
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Ongoing'),
            selected: provider.activeFilter?.includeCurrentEvents == true &&
                provider.activeFilter?.includePastEvents != true &&
                provider.activeFilter?.includeFutureEvents != true,
            onSelected: (selected) {
              if (selected) {
                provider.fetchEventsByTimePeriod(false, true, false);
              } else {
                provider.clearFilters();
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Past'),
            selected: provider.activeFilter?.includePastEvents == true &&
                provider.activeFilter?.includeCurrentEvents != true &&
                provider.activeFilter?.includeFutureEvents != true,
            onSelected: (selected) {
              if (selected) {
                provider.fetchEventsByTimePeriod(true, false, false);
              } else {
                provider.clearFilters();
              }
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('All'),
            selected: provider.activeFilter?.includePastEvents == true &&
                provider.activeFilter?.includeCurrentEvents == true &&
                provider.activeFilter?.includeFutureEvents == true,
            onSelected: (selected) {
              if (selected) {
                provider.fetchEventsByTimePeriod(true, true, true);
              } else {
                provider.clearFilters();
              }
            },
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.near_me, size: 18),
            label: const Text('Nearby'),
            onPressed: () => _getNearbyEvents(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine if in HomeScreen context (based on initialViewType and showAppBar)
    final bool isInHomeScreen = widget.inHomeContext ||
        (widget.initialViewType == EventsViewType.grid && !widget.showAppBar);

    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        centerTitle: true, // Center the title
        leading: IconButton(
          icon: const Icon(Icons.add_link),
          tooltip: 'Join Event',
          onPressed: () => _showJoinEventDialog(context),
        ),
        title: const Text('Browse Events'),
        actions: [
          // Add this consumer to show the sign-in button
          Consumer<EventsProvider>(
            builder: (ctx, provider, _) => IconButton(
              icon: Icon(provider.isAuthenticated ? Icons.logout : Icons.login),
              tooltip: provider.isAuthenticated ? 'Sign out' : 'Sign in with Google',
              onPressed: () => provider.isAuthenticated ? provider.signOut() : provider.signIn(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<EventsProvider>(context, listen: false).refresh(),
          ),
        ],
      ) : null,
      body: SafeArea(  // Added SafeArea to fix the top overflow issue
        child: Column(
          children: [
            // Add sign-in banner when showing sample data and not authenticated
            Consumer<EventsProvider>(
              builder: (ctx, provider, _) {
                if (provider.isUsingLocalData && !provider.isAuthenticated) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            'Using sample data. Sign in with Google to see real events.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.login, size: 18),
                          label: const Text('Sign in'),
                          onPressed: () => provider.signIn(),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Search bar and filter button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                      ),
                      onSubmitted: (_) => _handleSearchSubmit(context),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _openFilterScreen(context),
                    tooltip: 'Filter events',
                  ),
                ],
              ),
            ),

            // Time period filter chips
            Consumer<EventsProvider>(
              builder: (ctx, provider, _) => _buildTimeFilterChips(context, provider),
            ),

            // View type selector and event count
            Consumer<EventsProvider>(
              builder: (ctx, provider, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${provider.events.length} events found'),
                      // View type toggle
                      SegmentedButton<EventsViewType>(
                        segments: const [
                          ButtonSegment<EventsViewType>(
                            value: EventsViewType.list,
                            icon: Icon(Icons.list),
                          ),
                          ButtonSegment<EventsViewType>(
                            value: EventsViewType.grid,
                            icon: Icon(Icons.grid_view),
                          ),
                          ButtonSegment<EventsViewType>(
                            value: EventsViewType.map,
                            icon: Icon(Icons.map),
                          ),
                        ],
                        selected: {provider.currentViewType},
                        onSelectionChanged: (newSelection) {
                          provider.setViewType(newSelection.first);
                          setState(() {
                            _currentViewType = newSelection.first;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),

            // Active filters display
            Consumer<EventsProvider>(
              builder: (ctx, provider, _) {
                final filter = provider.activeFilter;
                final hasActiveFilters = filter != null && (
                    filter.searchQuery != null ||
                        filter.startDate != null ||
                        filter.endDate != null ||
                        filter.category != null ||
                        filter.showOnlyFavorites ||
                        filter.difficultyLevel != null);

                return hasActiveFilters
                    ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (filter != null && filter.searchQuery != null && filter.searchQuery!.isNotEmpty)
                                _buildFilterChip(context, 'Search: ${filter.searchQuery}'),
                              if (filter != null && filter.startDate != null)
                                _buildFilterChip(context, 'From: ${_formatDate(filter.startDate!)}'),
                              if (filter != null && filter.endDate != null)
                                _buildFilterChip(context, 'To: ${_formatDate(filter.endDate!)}'),
                              if (filter != null && filter.category != null)
                                _buildFilterChip(context, 'Category: ${filter.category}'),
                              if (filter != null && filter.showOnlyFavorites)
                                _buildFilterChip(context, 'Favorites only'),
                              if (filter != null && filter.difficultyLevel != null)
                                _buildFilterChip(context, 'Difficulty: ${filter.difficultyLevel}'),
                              if (filter != null && filter.userLatitude != null && filter.userLongitude != null && filter.maxDistance != null)
                                _buildFilterChip(context, 'Within: ${filter.maxDistance!.toStringAsFixed(1)} km'),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => provider.clearFilters(),
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink();
              },
            ),

            const Divider(),

            // Tab bar for time-based filtering (alternative approach)
            if (!isInHomeScreen)
              Consumer<EventsProvider>(
                builder: (ctx, provider, _) {
                  return TabBar(
                    controller: _tabController,
                    onTap: (index) {
                      // Apply time filter based on tab index
                      if (index == 0) {
                        provider.fetchEventsByTimePeriod(false, false, true);
                      } else if (index == 1) {
                        provider.fetchEventsByTimePeriod(false, true, false);
                      } else if (index == 2) {
                        provider.fetchEventsByTimePeriod(true, false, false);
                      }
                    },
                    tabs: const [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Ongoing'),
                      Tab(text: 'Past'),
                    ],
                  );
                },
              ),

            // Main content with loading indicator
            Expanded(
              child: Consumer<EventsProvider>(
                builder: (ctx, provider, _) {
                  if (provider.isLoading) {
                    return _buildShimmerLoading(context);
                  }

                  if (provider.error != null && !provider.isAuthenticated) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (provider.error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'Error: ${provider.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),

                          const SizedBox(height: 20),

                          const Icon(Icons.hiking, size: 64, color: Colors.green),

                          const SizedBox(height: 20),

                          const Text(
                            'Sign in to access hiking events',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 8),

                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Connect with your Google account to discover hiking events and trails near you',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),

                          const SizedBox(height: 24),

                          ElevatedButton.icon(
                            icon: const Icon(Icons.login),
                            label: const Text('Sign in with Google'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            onPressed: () => provider.signIn(),
                          ),

                          const SizedBox(height: 16),

                          TextButton(
                            onPressed: () => provider.refresh(),
                            child: const Text('Use sample data instead'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No events found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            onPressed: () => provider.refresh(),
                          ),
                        ],
                      ),
                    );
                  }

                  // Build the main event view based on tab selection or filter
                  if (!isInHomeScreen && _tabController.index == 0 &&
                      provider.activeFilter?.includeFutureEvents == true) {
                    return _buildEventView(context, provider.currentViewType, provider.futureEvents);
                  } else if (!isInHomeScreen && _tabController.index == 1 &&
                      provider.activeFilter?.includeCurrentEvents == true) {
                    return _buildEventView(context, provider.currentViewType, provider.currentEvents);
                  } else if (!isInHomeScreen && _tabController.index == 2 &&
                      provider.activeFilter?.includePastEvents == true) {
                    return _buildEventView(context, provider.currentViewType, provider.pastEvents);
                  } else {
                    // Default view or when not using tabs
                    return _buildEventView(context, provider.currentViewType, provider.events);
                  }
                },
              ),
            ),
          ],
        ),
      ),

      // Only show FAB when specified
      floatingActionButton: widget.showFAB ? FloatingActionButton(
        onPressed: () {
          // Navigate to event creation screen
          Navigator.of(context).pushNamed('/event-form');
        },
        child: const Icon(Icons.add),
      ) : null,
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}