import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'event_data.g.dart';

// Use typeId 4 since that seems to be the reserved ID in your existing code
@HiveType(typeId: 4)
class EventData {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime? startDate;

  @HiveField(4)
  final String? location;

  @HiveField(5)
  final int? participantLimit;

  @HiveField(6)
  final Duration? duration;

  // New fields for EventBrite data
  @HiveField(7)
  final DateTime? endDate;

  @HiveField(8)
  final String? imageUrl;

  @HiveField(9)
  final String? organizer;

  @HiveField(10)
  final String? url;

  @HiveField(11)
  final bool? isFree;

  @HiveField(12)
  final String? price;

  @HiveField(13)
  final int? capacity;

  @HiveField(14)
  final String? status;

  @HiveField(15)
  final String? venueId;

  @HiveField(16)
  final String? organizerId;

  @HiveField(17)
  final String? eventbriteId;

  EventData({
    required this.id,
    required this.title,
    this.description,
    this.startDate,
    this.location,
    this.participantLimit,
    this.duration,
    this.endDate,
    this.imageUrl,
    this.organizer,
    this.url,
    this.isFree,
    this.price,
    this.capacity,
    this.status,
    this.venueId,
    this.organizerId,
    this.eventbriteId,
  });

  // Constructor for backward compatibility with your existing code
  factory EventData.legacy({
    required int eventId,
    required String eventName,
    required String eventDescription,
    required DateTime eventDate,
    required String eventLocation,
    required int evenParticipantNumber,
    required Duration eventDuration,
  }) {
    return EventData(
      id: eventId.toString(),
      title: eventName,
      description: eventDescription,
      startDate: eventDate,
      location: eventLocation,
      participantLimit: evenParticipantNumber,
      duration: eventDuration,
    );
  }

  // Custom factory constructor for EventBrite API data
  factory EventData.fromEventBrite(Map<String, dynamic> json) {
    // Extract start date
    DateTime? startDate;
    if (json['start'] != null && json['start']['utc'] != null) {
      startDate = DateTime.parse(json['start']['utc']);
    }

    // Extract end date
    DateTime? endDate;
    if (json['end'] != null && json['end']['utc'] != null) {
      endDate = DateTime.parse(json['end']['utc']);
    }

    // Calculate duration if both dates are available
    Duration? duration;
    if (startDate != null && endDate != null) {
      duration = endDate.difference(startDate);
    }

    // Extract venue information
    String? location;
    String? venueId;
    if (json['venue'] != null) {
      venueId = json['venue']['id'];

      final venue = json['venue'];
      final address = venue['address'];

      List<String> locationParts = [];

      if (address != null) {
        if (address['address_1'] != null && address['address_1'].isNotEmpty) {
          locationParts.add(address['address_1']);
        }

        if (address['city'] != null && address['city'].isNotEmpty) {
          locationParts.add(address['city']);
        }

        if (address['region'] != null && address['region'].isNotEmpty) {
          locationParts.add(address['region']);
        }

        if (address['postal_code'] != null && address['postal_code'].isNotEmpty) {
          locationParts.add(address['postal_code']);
        }
      }

      location = locationParts.join(', ');
    }

    // Extract organizer information
    String? organizer;
    String? organizerId;
    if (json['organizer'] != null) {
      organizerId = json['organizer']['id'];
      organizer = json['organizer']['name'];
    }

    // Extract price information
    bool isFree = json['is_free'] ?? false;
    String? price;

    if (!isFree && json['ticket_availability'] != null) {
      if (json['ticket_availability']['minimum_ticket_price'] != null) {
        final minPrice = json['ticket_availability']['minimum_ticket_price'];
        if (minPrice['value'] != null && minPrice['currency'] != null) {
          price = '${minPrice['currency']} ${minPrice['value']}';
        }
      }
    }

    // Extract image URL
    String? imageUrl;
    if (json['logo'] != null && json['logo']['url'] != null) {
      imageUrl = json['logo']['url'];
    }

    return EventData(
      id: json['id'] ?? '',
      eventbriteId: json['id'], // Store the EventBrite ID as well
      title: json['name']?['text'] ?? 'No Title',
      description: json['description']?['text'] ?? '',
      imageUrl: imageUrl,
      startDate: startDate,
      endDate: endDate,
      location: location,
      organizer: organizer,
      url: json['url'],
      isFree: isFree,
      price: price,
      capacity: json['capacity'],
      status: json['status'],
      venueId: venueId,
      organizerId: organizerId,
      duration: duration,
      // participantLimit can be set if needed from EventBrite data
    );
  }

  // Helper methods for formatting
  String getFormattedStartDate() {
    if (startDate == null) return 'Date not specified';
    return DateFormat('MMM dd, yyyy • h:mm a').format(startDate!);
  }

  String getFormattedDateRange() {
    if (startDate == null) return 'Date not specified';

    String start = DateFormat('MMM dd, yyyy • h:mm a').format(startDate!);

    if (endDate == null) return start;

    // If same day, just show time range
    if (startDate!.year == endDate!.year &&
        startDate!.month == endDate!.month &&
        startDate!.day == endDate!.day) {
      return '${DateFormat('MMM dd, yyyy').format(startDate!)} • ' +
          '${DateFormat('h:mm a').format(startDate!)} - ' +
          '${DateFormat('h:mm a').format(endDate!)}';
    } else {
      // Show full date range
      return '${DateFormat('MMM dd, yyyy • h:mm a').format(startDate!)} - ' +
          '${DateFormat('MMM dd, yyyy • h:mm a').format(endDate!)}';
    }
  }

  String getFormattedDuration() {
    if (duration == null) return '';

    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}${minutes > 0 ? ' $minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EventData &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.startDate == startDate &&
        other.location == location &&
        other.participantLimit == participantLimit &&
        other.duration == duration;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      startDate,
      location,
      participantLimit,
      duration,
    );
  }
}