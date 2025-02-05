import 'dart:io';

class TrailData {
  final String name;
  final String description;
  final String difficulty;
  final String notice;
  final List<File> images;
  final DateTime date;           // Added date field
  final String location;         // Added location field
  final int participants;        // Added participants field
  final String duration;         // Added duration field

  TrailData({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.notice,
    required this.images,
    required this.date,
    required this.location,
    required this.participants,
    required this.duration,
  });
}
