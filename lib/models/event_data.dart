import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Factory constructor for Firestore data
  factory EventData.fromFirestore(Map<String, dynamic> data) {
    // Handle date conversions from Firestore Timestamp type
    DateTime? startDate;
    DateTime? endDate;
    Duration? duration;

    // Parse startDate
    if (data['startDate'] != null) {
      if (data['startDate'] is Timestamp) {
        startDate = (data['startDate'] as Timestamp).toDate();
      } else if (data['startDate'] is String) {
        try {
          startDate = DateTime.parse(data['startDate'] as String);
        } catch (_) {}
      }
    }

    // Parse endDate
    if (data['endDate'] != null) {
      if (data['endDate'] is Timestamp) {
        endDate = (data['endDate'] as Timestamp).toDate();
      } else if (data['endDate'] is String) {
        try {
          endDate = DateTime.parse(data['endDate'] as String);
        } catch (_) {}
      }
    }

    // Calculate duration if both dates are available
    if (startDate != null && endDate != null) {
      duration = endDate.difference(startDate);
    } else if (data['duration'] != null) {
      // Try to extract duration directly if available
      try {
        if (data['duration'] is int) {
          duration = Duration(minutes: data['duration'] as int);
        } else if (data['duration'] is String) {
          duration = Duration(minutes: int.tryParse(data['duration'] as String) ?? 0);
        }
      } catch (_) {}
    }

    // Extract and normalize title from different possible fields
    String title = 'Unnamed Event';
    if (data['title'] != null && data['title'] is String) {
      title = data['title'] as String;
    } else if (data['name'] != null) {
      if (data['name'] is String) {
        title = data['name'] as String;
      } else if (data['name'] is Map && data['name']['text'] != null) {
        title = data['name']['text'] as String;
      }
    } else if (data['eventName'] != null && data['eventName'] is String) {
      title = data['eventName'] as String;
    }

    // Extract and normalize description from different possible fields
    String? description;
    if (data['description'] != null) {
      if (data['description'] is String) {
        description = data['description'] as String;
      } else if (data['description'] is Map && data['description']['text'] != null) {
        description = data['description']['text'] as String;
      }
    } else if (data['eventDescription'] != null && data['eventDescription'] is String) {
      description = data['eventDescription'] as String;
    }

    // Extract location, handling different possible structures
    String? location;
    if (data['location'] != null && data['location'] is String) {
      location = data['location'] as String;
    } else if (data['eventLocation'] != null && data['eventLocation'] is String) {
      location = data['eventLocation'] as String;
    } else if (data['venue'] != null) {
      // Extract from venue object if available
      if (data['venue'] is String) {
        location = data['venue'] as String;
      } else if (data['venue'] is Map) {
        final venue = data['venue'] as Map;
        List<String> locationParts = [];

        if (venue['name'] != null) {
          locationParts.add(venue['name'] as String);
        }

        if (venue['address'] != null) {
          final address = venue['address'] as Map;
          if (address['address_1'] != null) {
            locationParts.add(address['address_1'] as String);
          }
          if (address['city'] != null) {
            locationParts.add(address['city'] as String);
          }
          if (address['region'] != null) {
            locationParts.add(address['region'] as String);
          }
        }

        if (locationParts.isNotEmpty) {
          location = locationParts.join(', ');
        }
      }
    }

    // Extract image URL
    String? imageUrl;
    if (data['imageUrl'] != null && data['imageUrl'] is String) {
      imageUrl = data['imageUrl'] as String;
    } else if (data['image'] != null && data['image'] is String) {
      imageUrl = data['image'] as String;
    } else if (data['logo'] != null) {
      if (data['logo'] is String) {
        imageUrl = data['logo'] as String;
      } else if (data['logo'] is Map && data['logo']['url'] != null) {
        imageUrl = data['logo']['url'] as String;
      }
    }

    // Extract organizer
    String? organizer;
    if (data['organizer'] != null) {
      if (data['organizer'] is String) {
        organizer = data['organizer'] as String;
      } else if (data['organizer'] is Map && data['organizer']['name'] != null) {
        organizer = data['organizer']['name'] as String;
      }
    } else if (data['organizerName'] != null && data['organizerName'] is String) {
      organizer = data['organizerName'] as String;
    }

    // Extract various other fields
    String? url = data['url'] as String?;
    bool? isFree = data['isFree'] as bool?;
    String? price = data['price'] as String?;
    int? capacity = _parseIntSafely(data['capacity']);
    int? participantLimit = _parseIntSafely(data['participantLimit'] ?? data['evenParticipantNumber']);
    String? status = data['status'] as String?;
    String? venueId = data['venueId'] as String?;
    String? organizerId = data['organizerId'] as String?;
    String? eventbriteId = data['eventbriteId'] as String?;

    // Use document ID if id field is missing
    String id = (data['id'] as String?) ?? '';

    return EventData(
      id: id,
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      location: location,
      imageUrl: imageUrl,
      organizer: organizer,
      url: url,
      isFree: isFree,
      price: price,
      capacity: capacity,
      status: status,
      venueId: venueId,
      organizerId: organizerId,
      eventbriteId: eventbriteId,
      participantLimit: participantLimit,
      duration: duration,
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

  // Helper method to safely parse integer values
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}