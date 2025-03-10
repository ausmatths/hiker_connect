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
  final bool showTimeSince;

  const EventsGridView({
    Key? key,
    required this.events,
    this.hasMoreEvents = false,
    this.isLoadingMore = false,
    required this.onLoadMore,
    this.showTimeSince = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate number of columns based on screen width
    final int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    // Adjust aspect ratio slightly to provide more space for content
    final double aspectRatio = 0.8;

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
                      // Time badge for upcoming events
                      if (event.eventDate.isAfter(DateTime.now()) &&
                          event.eventDate.difference(DateTime.now()).inDays <= 7)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              _getShortTimeSinceText(event.eventDate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.0,
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
                      padding: const EdgeInsets.all(8.0), // Reduced padding
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Use LayoutBuilder to ensure content fits available space
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Event title with Hero animation
                              Hero(
                                tag: 'event-title-${event.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    event.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: 13, // Smaller font size
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2.0), // Reduced spacing
                              // Event date
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 10.0, // Smaller icon
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 2.0), // Reduced spacing
                                  Expanded(
                                    child: Text(
                                      showTimeSince
                                          ? _getTimeSinceText(event.eventDate)
                                          : dateFormat.format(event.eventDate),
                                      style: TextStyle(
                                        fontSize: 10.0, // Smaller text
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2.0), // Reduced spacing
                              // Event location
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 10.0, // Smaller icon
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 2.0), // Reduced spacing
                                  Expanded(
                                    child: Hero(
                                      tag: 'event-location-${event.id}',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: Text(
                                          _truncateLocation(event.location ?? 'No location specified'),
                                          style: TextStyle(
                                            fontSize: 10.0, // Smaller text
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
                              if (event.difficulty != null) ...[
                                const SizedBox(height: 2.0), // Reduced spacing
                                _buildDifficultyIndicator(context, event.difficulty!),
                              ],

                              const Spacer(flex: 1), // Use flexible spacer

                              // Bottom row with attendees count and price indicator
                              Row(
                                mainAxisSize: MainAxisSize.max, // Take full width
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Attendees count
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.people_outline, size: 10.0), // Smaller icon
                                      const SizedBox(width: 2.0), // Reduced spacing
                                      Text(
                                        '${event.attendees?.length ?? 0}',
                                        style: const TextStyle(fontSize: 10.0), // Smaller text
                                      ),
                                    ],
                                  ),

                                  // Free badge or price
                                  if (event.isFree == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'FREE',
                                        style: TextStyle(
                                          fontSize: 8, // Even smaller text
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else if (event.price != null)
                                    Text(
                                      _formatPrice(event.price),
                                      style: TextStyle(
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
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

  // Helper to format price correctly regardless of type
  String _formatPrice(dynamic price) {
    if (price == null) return '';

    // Handle different types of price data
    if (price is int) {
      return '\$${price.toString()}';
    } else if (price is double) {
      return '\$${price.toStringAsFixed(2)}';
    } else if (price is String) {
      // Try to parse the string as a number
      double? parsedPrice = double.tryParse(price);
      if (parsedPrice != null) {
        return '\$${parsedPrice.toStringAsFixed(2)}';
      } else {
        // If it's not a parseable number, just return the string with $ prefix
        return price.startsWith('\$') ? price : '\$$price';
      }
    }

    // Fallback for any other type
    return '\$$price';
  }

  // Helper to truncate location text to prevent overflow
  String _truncateLocation(String location) {
    if (location.length > 25) {
      // Reduced character limit
      return location.substring(0, 22) + '...';
    }
    return location;
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

  String _getShortTimeSinceText(DateTime eventDate) {
    final now = DateTime.now();
    final difference = eventDate.difference(now);

    if (difference.inDays > 0) {
      return 'In ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes}m';
    } else {
      return 'Now';
    }
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
          'Diff:',  // Shortened text
          style: TextStyle(
            fontSize: 9.0, // Smaller text
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        ...List.generate(
          5,
              (index) => Icon(
            Icons.circle,
            size: 5.0, // Even smaller circles
            color: index < difficulty ? color : Colors.grey[300],
          ),
        ),
      ],
    );
  }
}