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

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'notice': notice,
      'images': images,
      'date': date.toIso8601String(),
      'location': location,
      'participants': participants,
      'duration': duration.inMinutes,  // Store duration as minutes
    };
  }

  // Create from Map for retrieval
  factory TrailData.fromMap(Map<String, dynamic> map) {
    return TrailData(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      difficulty: map['difficulty'] ?? '',
      notice: map['notice'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      date: DateTime.parse(map['date']),
      location: map['location'] ?? '',
      participants: map['participants'] ?? 0,
      duration: Duration(minutes: map['duration'] ?? 0),
    );
  }
}