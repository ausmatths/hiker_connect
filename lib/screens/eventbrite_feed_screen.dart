import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../models/event_data.dart';
import '../providers/events_provider.dart';
import 'trails/event_detail_screen.dart';

class EventBriteFeedScreen extends StatefulWidget {
  const EventBriteFeedScreen({Key? key}) : super(key: key);

  @override
  State<EventBriteFeedScreen> createState() => _EventBriteFeedScreenState();
}

class _EventBriteFeedScreenState extends State<EventBriteFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isSearchExpanded = false;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    // Fetch events when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventsProvider = Provider.of<EventBriteProvider>(context, listen: false);
      eventsProvider.fetchEvents(refresh: true);
      developer.log('Initialized EventBriteFeedScreen and fetched events', name: 'EventBriteFeedScreen');
    });

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    developer.log('Disposed EventBriteFeedScreen', name: 'EventBriteFeedScreen');
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final eventsProvider = Provider.of<EventBriteProvider>(context, listen: false);
      if (!eventsProvider.isLoading && eventsProvider.hasMoreEvents) {
        eventsProvider.fetchEvents();
        developer.log('Triggered pagination load on scroll', name: 'EventBriteFeedScreen');
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
      developer.log('Selected date: ${_dateController.text}', name: 'EventBriteFeedScreen');
    }
  }

  void _submitSearch() {
    final eventsProvider = Provider.of<EventBriteProvider>(context, listen: false);

    String? location = _locationController.text.isEmpty ? null : _locationController.text;
    String? startDate = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;

    developer.log('Submitting search - location: $location, startDate: $startDate', name: 'EventBriteFeedScreen');
    eventsProvider.searchEvents(
      location: location,
      startDate: startDate,
    );

    // Collapse the search field after submission
    setState(() {
      _isSearchExpanded = false;
    });
  }

  void _resetSearch() {
    setState(() {
      _locationController.clear();
      _dateController.clear();
      _selectedDate = null;
    });

    developer.log('Reset search filters', name: 'EventBriteFeedScreen');
    final eventsProvider = Provider.of<EventBriteProvider>(context, listen: false);
    eventsProvider.fetchEvents(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outdoor & Hiking Events'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearchExpanded ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _resetSearch();
                }
              });
              developer.log('Toggled search panel: $_isSearchExpanded', name: 'EventBriteFeedScreen');
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search bar section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isSearchExpanded ? 150 : 0,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        hintText: 'City, State or Postal Code',
                        prefixIcon: const Icon(Icons.location_on),
                        border: const OutlineInputBorder(),
                        fillColor: theme.colorScheme.surface,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: InputDecoration(
                              labelText: 'Start Date',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: const OutlineInputBorder(),
                              fillColor: theme.colorScheme.surface,
                              filled: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _submitSearch,
                          child: const Text('Search'),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: _resetSearch,
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Welcome message
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Hiking Events',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Find outdoor adventures and connect with fellow hikers.',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),

          // Event list title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Events',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<EventBriteProvider>(
                  builder: (context, provider, _) {
                    return provider.isLoading && provider.events.isEmpty
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        provider.fetchEvents(refresh: true);
                        developer.log('Manually refreshed events list', name: 'EventBriteFeedScreen');
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Event list
          Expanded(
            child: Consumer<EventBriteProvider>(
              builder: (context, provider, _) {
                if (provider.error != null && provider.events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchEvents(refresh: true),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.events.isEmpty && !provider.isLoading) {
                  return const Center(
                    child: Text('No events found. Try adjusting your search.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchEvents(refresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: provider.events.length + (provider.isLoading && provider.events.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.events.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final event = provider.events[index];
                      return _buildEventCard(event, context, theme);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventData event, BuildContext context, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          developer.log('Tapped on event: ${event.id} - ${event.title}', name: 'EventBriteFeedScreen');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(eventId: event.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event image
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  event.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    developer.log('Error loading event image: $error', name: 'EventBriteFeedScreen');
                    return Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    );
                  },
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: Center(
                    child: Icon(
                      Icons.photo,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

            // Event details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.getFormattedStartDate(),
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    event.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location
                  if (event.location != null && event.location!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Organizer
                  if (event.organizer != null && event.organizer!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'By ${event.organizer}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Price & View button
                  Row(
                    children: [
                      // Fix for infinite width constraint - wrap Chip in a bounded width container
                      Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Chip(
                          backgroundColor: event.isFree == true
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.secondaryContainer,
                          label: Text(
                            event.isFree == true ? 'Free' : (event.price ?? 'Paid'),
                            style: TextStyle(
                              color: event.isFree == true
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSecondaryContainer,
                            ),
                            // Set overflow to ensure text doesn't cause layout issues
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Ensure the button has a bounded width
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 150),
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(eventId: event.id),
                              ),
                            );
                          },
                          icon: const Text('View'),
                          label: Icon(Icons.arrow_forward, size: 16, color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}