class Trail {
  final String name;
  final String description;
  final String difficulty;
  final String notice;
  final List<String> images;  // Changed from List<File> to List<String>

  Trail({
    required this.name,
    required this.description,
    required this.difficulty,
    required this.notice,
    required this.images,
  });
}