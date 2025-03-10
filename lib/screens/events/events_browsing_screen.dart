import 'package:flutter/material.dart';
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

class EventsBrowsingScreen extends StatefulWidget {
  static const routeName = '/events-browsing';

  final bool showAppBar;
  final EventsViewType initialViewType;
  final bool showFAB; // Parameter to control FAB visibility

  const EventsBrowsingScreen({
    Key? key,
    this.showAppBar = true,
    this.initialViewType = EventsViewType.list,
    this.showFAB = true, // Default to showing FAB
  }) : super(key: key);

  @override
  State<EventsBrowsingScreen> createState() => _EventsBrowsingScreenState();
}

class _EventsBrowsingScreenState extends State<EventsBrowsingScreen> {
  final TextEditingController _searchController = TextEditingController();
  late EventsViewType _currentViewType;

  @override
  void initState() {
    super.initState();
    _currentViewType = widget.initialViewType;

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

  @override
  Widget build(BuildContext context) {
    // Determine if in HomeScreen context (based on initialViewType and showAppBar)
    final bool isInHomeScreen = widget.initialViewType == EventsViewType.grid && !widget.showAppBar;

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
                            'Sign in with Google to see more events near you.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondaryContainer,
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
            Consumer<EventsProvider>(
              builder: (ctx, provider, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            const SizedBox(height: 8.0),
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

                  // Build the main event view
                  return Column(
                    children: [
                      // Main content (events view)
                      Expanded(
                        child: _buildEventView(
                          context,
                          provider.currentViewType,
                          provider.events,
                        ),
                      ),

                      // Loading indicator at the bottom when loading more
                      if (provider.isLoadingMore)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Loading more events...'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // IMPORTANT: Never show FAB in this screen
      floatingActionButton: null,
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