import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/event_data.dart';
import '../../providers/events_provider.dart';
import '../trails/event_detail_screen.dart';
import '../../utils/transitions.dart';

class EventsGridView extends StatelessWidget {
  final List<EventData> events;
  final bool hasMoreEvents;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  const EventsGridView({
    Key? key,
    required this.events,
    this.hasMoreEvents = false,
    this.isLoadingMore = false,
    required this.onLoadMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate number of columns based on screen width
    final int crossAxisCount = screenWidth > 600 ? 3 : 2;

    // Adjust aspect ratio slightly to provide more space for content
    final double aspectRatio = 0.8;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9) {
          if (hasMoreEvents && !isLoadingMore) {
            // Call onLoadMore to fetch additional events
            onLoadMore();
          }
        }
        return true;
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: events.length + (hasMoreEvents ? 1 : 0),
        itemBuilder: (ctx, index) {
          // Show loading indicator at the end if loading more
          if (index == events.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final event = events[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  FadePageRoute(
                    page: EventDetailScreen(eventId: event.id),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event image with Hero animation
                  Stack(
                    children: [
                      Hero(
                        tag: 'event-image-${event.id}',
                        child: SizedBox(
                          height: 110, // Slightly reduced height
                          width: double.infinity,
                          child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                              ? Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, error, _) => Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          )
                              : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.landscape,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      // Category badge
                      if (event.category != null && event.category!.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
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
                        ),
                      // Favorite button
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Consumer<EventsProvider>(
                          builder: (ctx, provider, _) {
                            final isFavorite = provider.isFavorite(event.id);
                            return IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                                size: 20, // Slightly smaller icon
                              ),
                              padding: EdgeInsets.zero, // Reduce padding
                              constraints: const BoxConstraints(), // Remove constraints
                              onPressed: () => provider.toggleFavorite(event.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event title with Hero animation
                          Hero(
                            tag: 'event-title-${event.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                event.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 14, // Smaller font size
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          // Event date
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
                                  dateFormat.format(event.eventDate),
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
                          // Event location - Fixed overflowing issue
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12.0,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: Hero(
                                  tag: 'event-location-${event.id}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      _truncateLocation(event.location ?? 'No location specified'),
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          // Display difficulty if available
                          if (event.difficulty != null)
                            _buildDifficultyIndicator(context, event.difficulty!),

                          const Spacer(),
                          // Attendees count
                          Row(
                            children: [
                              const Icon(Icons.people_outline, size: 12.0), // Smaller icon
                              const SizedBox(width: 4.0),
                              Text(
                                '${event.attendees?.length ?? 0} attending',
                                style: const TextStyle(fontSize: 12.0),
                              ),
                              if (event.isFree != null && event.isFree!)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'FREE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper to truncate location text to prevent overflow
  String _truncateLocation(String location) {
    if (location.length > 30) {
      return location.substring(0, 28) + '...';
    }
    return location;
  }

  Widget _buildDifficultyIndicator(BuildContext context, int difficulty) {
    final List<Color> colors = [
      Colors.green,
      Colors.lightGreen,
      Colors.amber,
      Colors.orange,
      Colors.red,
    ];

    final color = difficulty >= 1 && difficulty <= 5
        ? colors[difficulty - 1]
        : Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min, // Take only needed space
      children: [
        Text(
          'Difficulty: ',
          style: TextStyle(
            fontSize: 10.0,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        ...List.generate(
          5,
              (index) => Icon(
            Icons.circle,
            size: 6.0, // Smaller circles
            color: index < difficulty ? color : Colors.grey[300],
          ),
        ),
      ],
    );
  }
}