class Review {
  final String userId;
  final String eventId;
  final String trailId;
  final String username;
  final String reviewText;
  final double rating; // Add a rating field
  final DateTime timestamp;

  Review({
    required this.userId,
    required this.eventId,
    required this.trailId,
    required this.username,
    required this.reviewText,
    required this.rating,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'trailId': trailId,
      'username': username,
      'reviewText': reviewText,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      userId: data['userId'],
      eventId: data['eventId'],
      trailId: data['trailId'],
      username: data['username'],
      reviewText: data['reviewText'],
      rating: data['rating'],
      timestamp: DateTime.parse(data['timestamp']),
    );
  }
}
//adding comments