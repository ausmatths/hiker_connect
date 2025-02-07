class TrailData {
  final String name;
  final String description;
  final String difficulty;
  final String notice;
  final List<String> images;
  final DateTime date;
  final String location;
  final int participants;
  final Duration duration;

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