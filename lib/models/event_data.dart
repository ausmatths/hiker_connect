import 'package:hive/hive.dart';

part 'event_data.g.dart';

@HiveType(typeId: 0)
class EventData {
  @HiveField(0)
  final int eventId;
  @HiveField(1)
  final String eventName;
  @HiveField(2)
  final String eventDescription;
  @HiveField(6)
  final DateTime eventDate;
  @HiveField(7)
  final String eventLocation;
  @HiveField(8)
  final int evenParticipantNumber;
  @HiveField(9)
  final Duration eventDuration;

  EventData({
    required this.eventId,
    required this.eventName,
    required this.eventDescription,
    required this.eventDate,
    required this.eventLocation,
    required this.evenParticipantNumber,
    required this.eventDuration
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventData &&
        other.eventId == eventId &&
        other.eventName == eventName &&
        other.eventDescription == eventDescription &&
        other.eventDate == eventDate &&
        other.eventLocation == eventLocation &&
        other.evenParticipantNumber == evenParticipantNumber &&
        other.eventDuration == eventDuration;
  }

  @override
  int get hashCode {
    return Object.hash(
      eventId,
      eventName,
      eventDescription,
      eventDate,
      eventLocation,
      evenParticipantNumber,
      eventDuration,
    );
  }

}