import 'dart:io';

class Trail {
  final String name;
  final String description;
  final String difficulty;
  final String notice;
  final List<File> images;

  Trail({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.notice,
    required this.images,
  });
}