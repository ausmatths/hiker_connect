import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:developer' as developer;
import '../../models/event_data.dart';
import '../../providers/events_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _isLoading = true;
  EventData? _event;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
    developer.log('Initializing EventDetailScreen for event ID: ${widget.eventId}', name: 'EventDetailScreen');
  }

  Future<void> _loadEventDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
      final event = await eventsProvider.getEventDetails(widget.eventId);

      setState(() {
        _event = event;
        _isLoading = false;
      });

      developer.log('Successfully loaded event details: ${event?.title}', name: 'EventDetailScreen');
    } catch (e) {
      developer.log('Error loading event details: $e', name: 'EventDetailScreen');
      setState(() {
        _error = 'Failed to load event details. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event URL not available')),
      );
      return;
    }

    final Uri uri = Uri.parse(url);
    try {
      developer.log('Launching URL: $url', name: 'EventDetailScreen');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        developer.log('Could not launch URL: $url', name: 'EventDetailScreen');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the event page')),
        );
      }
    } catch (e) {
      developer.log('Error launching URL: $e', name: 'EventDetailScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open the event page')),
      );
    }
  }

  void _shareEvent() {
    if (_event == null) return;

    final String eventTitle = _event!.title;
    final String eventDate = _event!.getFormattedDateRange();
    final String? eventUrl = _event!.url;

    String shareText = 'Check out this hiking event: $eventTitle';
    if (eventDate.isNotEmpty) {
      shareText += '\nDate: $eventDate';
    }
    if (_event!.location != null && _event!.location!.isNotEmpty) {
      shareText += '\nLocation: ${_event!.location}';
    }
    if (eventUrl != null && eventUrl.isNotEmpty) {
      shareText += '\n\n$eventUrl';
    }

    developer.log('Sharing event: $eventTitle', name: 'EventDetailScreen');
    Share.share(shareText);
  }

  Widget _buildEventInfo(String title, String? value, IconData icon, ThemeData theme) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEventDetails,
              child: const Text('Try Again'),
            ),
          ],
        ),
      )
          : _event == null
          ? const Center(child: Text('Event not found'))
          : _buildEventDetails(theme, screenWidth),
    );
  }

  Widget _buildEventDetails(ThemeData theme, double screenWidth) {
    return CustomScrollView(
      slivers: [
        // App Bar with Image
        SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareEvent,
              tooltip: 'Share Event',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _event!.imageUrl != null && _event!.imageUrl!.isNotEmpty
                ? Image.network(
              _event!.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                developer.log('Error loading image: $error', name: 'EventDetailScreen');
                return Container(color: theme.colorScheme.surfaceVariant);
              },
            )
                : Container(color: theme.colorScheme.surfaceVariant),
          ),
        ),

        // Event Details
        SliverToBoxAdapter(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: screenWidth,
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  _event!.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Date & Time
                _buildEventInfo(
                  'Date & Time',
                  _event!.getFormattedDateRange(),
                  Icons.calendar_today,
                  theme,
                ),

                // Duration if available
                if (_event!.duration != null)
                  _buildEventInfo(
                    'Duration',
                    _event!.getFormattedDuration(),
                    Icons.timer,
                    theme,
                  ),

                // Location
                _buildEventInfo(
                  'Location',
                  _event!.location,
                  Icons.location_on,
                  theme,
                ),

                // Organizer
                _buildEventInfo(
                  'Organizer',
                  _event!.organizer,
                  Icons.people,
                  theme,
                ),

                // Price
                _buildEventInfo(
                  'Price',
                  _event!.isFree == true ? 'Free' : (_event!.price ?? 'Paid'),
                  Icons.attach_money,
                  theme,
                ),

                // Participant Limit if available
                if (_event!.participantLimit != null)
                  _buildEventInfo(
                    'Participant Limit',
                    _event!.participantLimit.toString(),
                    Icons.groups,
                    theme,
                  ),

                // Status
                if (_event!.status != null && _event!.status!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Icon(
                          _event!.status!.toLowerCase() == 'live'
                              ? Icons.check_circle
                              : Icons.info,
                          color: _event!.status!.toLowerCase() == 'live'
                              ? Colors.green
                              : Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status: ${_event!.status}',
                            style: TextStyle(
                              color: _event!.status!.toLowerCase() == 'live'
                                  ? Colors.green
                                  : Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 32),

                // Description
                if (_event!.description != null && _event!.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (_event!.description!.contains('<') && _event!.description!.contains('>'))
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth - 32, // Account for padding
                          ),
                          child: Html(
                            data: _event!.description!,
                            style: {
                              'body': Style(
                                fontSize: FontSize(16.0),
                                lineHeight: LineHeight(1.5),
                                maxLines: 100,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                              'table': Style(
                                width: Width(screenWidth - 32),
                              ),
                              'img': Style(
                                width: Width(screenWidth - 32),
                              ),
                            },
                          ),
                        )
                      else
                        Text(
                          _event!.description!,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),

                // CTA Buttons
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: screenWidth - 32),
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(_event!.url),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View Event Details'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Add to calendar functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Adding to calendar...')),
                          );
                          developer.log('Add to calendar clicked', name: 'EventDetailScreen');
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Add to Calendar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareEvent,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}