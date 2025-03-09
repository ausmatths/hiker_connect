import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/event_data.dart';
import '../../providers/events_provider.dart'; // Changed to use EventsProvider
import '../trails/event_detail_screen.dart';

class EventsListView extends StatelessWidget {
  final List<EventData> events;

  const EventsListView({
    Key? key,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('E, MMM d, yyyy • h:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: events.length,
      itemBuilder: (ctx, index) {
        final event = events[index];
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
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, error, _) => Container(
                      height: 120,
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
                                vertical: 2.0,
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
                                ),
                              ),
                            ),
                          const Spacer(),
                          // Difficulty indicator if available
                          if (event.difficulty != null)
                            _buildDifficultyIndicator(context, event.difficulty!),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      // Event title
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      // Event date and time
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16.0,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              dateFormat.format(event.eventDate),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 14.0,
                              ),
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
                            size: 16.0,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              event.location ?? 'No location specified', // Added null check
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
                        event.description ?? 'No description available', // Added null check
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12.0),
                      // Actions row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Attendees count
                          Row(
                            children: [
                              const Icon(Icons.people_outline, size: 16.0),
                              const SizedBox(width: 4.0),
                              Text(
                                '${event.attendees?.length ?? 0} attending',
                                style: const TextStyle(fontSize: 14.0),
                              ),
                            ],
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
                              );
                            },
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
      },
    );
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
            color: index < difficulty ? color : Colors.grey[300],
          ),
        ),
      ],
    );
  }
}