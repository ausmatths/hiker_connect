import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String userId;
  final String eventId;
  final String trailId;
  final String username;
  final String reviewText;
  final double rating;
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
      userId: data['userId'] ?? '',
      eventId: data['eventId'] ?? '',
      trailId: data['trailId'] ?? '',
      username: data['username'] ?? 'Anonymous',
      reviewText: data['reviewText'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is String
          ? DateTime.parse(data['timestamp'])
          : (data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now()))
          : DateTime.now(),
    );
  }
}