import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/event_data.dart';
import '../../providers/events_provider.dart';
import '../trails/event_detail_screen.dart';

class EventsListView extends StatelessWidget {
  final List<EventData> events;
  final bool showTimeSince;
  final bool showCompactView;

  const EventsListView({
    Key? key,
    required this.events,
    this.showTimeSince = false,
    this.showCompactView = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('E, MMM d, yyyy • h:mm a');

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: events.length,
      itemBuilder: (ctx, index) {
        final event = events[index];
        return showCompactView
            ? _buildCompactEventCard(context, event, dateFormat)
            : _buildFullEventCard(context, event, dateFormat);
      },
    );
  }

  Widget _buildFullEventCard(BuildContext context, EventData event, DateFormat dateFormat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => EventDetailScreen(eventId: event.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event banner/image if available
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              Image.network(
                event.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, _) => Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Event category badge
                      if (event.category != null && event.category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            event.category!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const Spacer(),
                      // Difficulty indicator if available
                      if (event.difficulty != null)
                        _buildDifficultyIndicator(context, event.difficulty!),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // Event title
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12.0),
                  // Event date and time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16.0,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: showTimeSince
                            ? Text(
                          _getTimeSinceText(event.eventDate),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14.0,
                          ),
                        )
                            : Text(
                          dateFormat.format(event.eventDate),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  // Event duration if available
                  if (event.endDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16.0,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          _formatDuration(event.eventDate, event.endDate!),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6.0),
                  // Event location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16.0,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          event.location ?? 'No location specified',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 14.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  // Event description preview
                  Text(
                    event.description ?? 'No description available',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16.0),
                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Attendees count
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 16.0),
                          const SizedBox(width: 8.0),
                          Text(
                            '${event.attendees?.length ?? 0} attending',
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ],
                      ),
                      // Action buttons
                      Row(
                        children: [
                          // Share button
                          IconButton(
                            icon: const Icon(Icons.share_outlined),
                            onPressed: () {
                              // Implement share functionality
                            },
                            tooltip: 'Share',
                            visualDensity: VisualDensity.compact,
                          ),
                          // Favorite button
                          Consumer<EventsProvider>(
                            builder: (ctx, provider, _) {
                              final isFavorite = provider.isFavorite(event.id);
                              return IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : null,
                                ),
                                onPressed: () => provider.toggleFavorite(event.id),
                                tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                        ],
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

  Widget _buildCompactEventCard(BuildContext context, EventData event, DateFormat dateFormat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => EventDetailScreen(eventId: event.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event image (thumbnail size in compact view)
              if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: Image.network(
                    event.imageUrl!,
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, _) => Container(
                      height: 70,
                      width: 70,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 24,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Icon(
                    Icons.event,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              const SizedBox(width: 12.0),

              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and favorite
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Consumer<EventsProvider>(
                          builder: (ctx, provider, _) {
                            final isFavorite = provider.isFavorite(event.id);
                            return IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : null,
                                size: 20,
                              ),
                              onPressed: () => provider.toggleFavorite(event.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),

                    // Category badge
                    if (event.category != null && event.category!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          event.category!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 10.0,
                          ),
                        ),
                      ),

                    // Date/time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12.0,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            showTimeSince
                                ? _getTimeSinceText(event.eventDate)
                                : dateFormat.format(event.eventDate),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12.0,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4.0),
                        Expanded(
                          child: Text(
                            event.location ?? 'No location specified',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6.0),

                    // Attendees & difficulty (in one row to save space)
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 12.0,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '${event.attendees?.length ?? 0}',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 12.0),

                        if (event.difficulty != null)
                          Row(
                            children: [
                              ...List.generate(
                                event.difficulty!,
                                    (index) => Icon(
                                  Icons.circle,
                                  size: 8.0,
                                  color: _getDifficultyColor(event.difficulty!),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  Widget _buildDifficultyIndicator(BuildContext context, int difficulty) {
    return Row(
      children: [
        Text(
          'Difficulty: ',
          style: TextStyle(
            fontSize: 12.0,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        ...List.generate(
          5,
              (index) => Icon(
            Icons.circle,
            size: 12.0,
            color: index < difficulty ? _getDifficultyColor(difficulty) : Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(int difficulty) {
    final List<Color> colors = [
      Colors.green,
      Colors.lightGreen,
      Colors.amber,
      Colors.orange,
      Colors.red,
    ];

    return difficulty >= 1 && difficulty <= 5
        ? colors[difficulty - 1]
        : Colors.grey;
  }
}