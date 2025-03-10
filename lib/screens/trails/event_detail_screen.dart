import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:developer' as developer;
import '../../models/event_data.dart';
import '../../models/review_model.dart';
import '../../providers/events_provider.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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
  Future<void> _saveReview(Review review) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('reviews').add(review.toMap());
      developer.log('Review saved successfully', name: 'EventDetailScreen');
    } catch (e) {
      developer.log('Error saving review: $e', name: 'EventDetailScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save review. Please try again.')),
        );
      }
    }
  }
  double _calculateAverageRating(List<Review> reviews) {
    if (reviews.isEmpty) return 0.0;
    final totalRating = reviews.map((review) => review.rating).reduce((a, b) => a + b);
    return totalRating / reviews.length;
  }
  Future<List<Review>> _fetchReviews(String eventId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('reviews')
          .where('eventId', isEqualTo: eventId)
          .get();

      return querySnapshot.docs.map((doc) => Review.fromMap(doc.data())).toList();
    } catch (e) {
      developer.log('Error fetching reviews: $e', name: 'EventDetailScreen');
      return [];
    }
  }


  Future<void> _showReviewDialog(BuildContext context) async {
    final TextEditingController _reviewController = TextEditingController();
    double _rating = 0.0;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  hintText: 'Write your review here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 30,
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  _rating = rating;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_reviewController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please write a review')),
                  );
                  return;
                }

                final review = Review(
                  userId: FirebaseAuth.instance.currentUser!.uid,
                  eventId: widget.eventId,
                  trailId: '', // Assuming trailId is not used for events
                  username: FirebaseAuth.instance.currentUser!.displayName ?? 'Anonymous',
                  reviewText: _reviewController.text.trim(),
                  rating: _rating,
                  timestamp: DateTime.now(),
                );

                // Save the review to Firestore
                await _saveReview(review);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted successfully')),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
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
  void _showReviewsBottomSheet(BuildContext context, List<Review> reviews) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                RatingBarIndicator(
                                  rating: review.rating,
                                  itemCount: 5,
                                  itemSize: 16,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Posted on ${DateFormat('MMMM, d yyyy').format(review.timestamp)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review.reviewText,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'By User ${review.username}',// Display a portion of the user ID
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
    return FutureBuilder<List<Review>>(
        future: _fetchReviews(widget.eventId),
        builder: (context, snapshot) {
          final reviews = snapshot.data ?? [];
          final averageRating = _calculateAverageRating(reviews);
          final numberOfReviews = reviews.length;
          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                actions: [
                  // Keep existing actions
                ],
            flexibleSpace: FlexibleSpaceBar(
              background: _event!.imageUrl != null && _event!.imageUrl!.isNotEmpty
                  ? Image.network(
                _event!.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('Failed to load image: $error');
                  return Container(
                    color: theme.colorScheme.surfaceVariant,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50),
                    ),
                  );
                },
              )
                  : Container(
                color: theme.colorScheme.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.photo_library, size: 50),
                ),
              ),
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
                    Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8, // Space between title and ratings
                    children: [
                      Text(
                        _event!.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (numberOfReviews > 0) ...[
                        const SizedBox(width: 8),
                      GestureDetector(
                          onTap: () { _showReviewsBottomSheet(context, reviews);},
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RatingBarIndicator(
                              rating: averageRating,
                              itemCount: 5,
                              itemSize: 20,
                              itemBuilder: (context, _) =>
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                            ),
                            Text('(${numberOfReviews.toString()})',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                      ),
                        ),
              ],
                      ]
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
                        _event!.isFree == true ? 'Free' : (_event!.price ??
                            'Paid'),
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
                                    color: _event!.status!.toLowerCase() ==
                                        'live'
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
                      if (_event!.description != null &&
                          _event!.description!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            if (_event!.description!.contains('<') &&
                                _event!.description!.contains('>'))
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: screenWidth -
                                      32, // Account for padding
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
                                style: const TextStyle(
                                    fontSize: 16, height: 1.5),
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
                                  const SnackBar(
                                      content: Text('Adding to calendar...')),
                                );
                                developer.log('Add to calendar clicked',
                                    name: 'EventDetailScreen');
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Add to Calendar'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showReviewDialog(context),
                              icon: const Icon(
                                Icons.reviews,
                              ),
                              label: const Text('Write a Review'),
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
        },
    );
  }
}