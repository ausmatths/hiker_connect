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
  final DateTime eventDate; // Renamed from startDate for compatibility

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

  // New fields for Event Browsing
  @HiveField(18)
  final String? category;

  @HiveField(19)
  final int? difficulty;

  @HiveField(20)
  final double? latitude;

  @HiveField(21)
  final double? longitude;

  @HiveField(22)
  final List<String>? attendees;

  @HiveField(23)
  final String? createdBy;

  EventData({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
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
    this.category,
    this.difficulty,
    this.latitude,
    this.longitude,
    this.attendees,
    this.createdBy,
  });

  // Create a copy with some fields updated
  EventData copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? eventDate,
    String? location,
    int? participantLimit,
    Duration? duration,
    DateTime? endDate,
    String? imageUrl,
    String? organizer,
    String? url,
    bool? isFree,
    String? price,
    int? capacity,
    String? status,
    String? venueId,
    String? organizerId,
    String? eventbriteId,
    String? category,
    int? difficulty,
    double? latitude,
    double? longitude,
    List<String>? attendees,
    String? createdBy,
  }) {
    return EventData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      participantLimit: participantLimit ?? this.participantLimit,
      duration: duration ?? this.duration,
      endDate: endDate ?? this.endDate,
      imageUrl: imageUrl ?? this.imageUrl,
      organizer: organizer ?? this.organizer,
      url: url ?? this.url,
      isFree: isFree ?? this.isFree,
      price: price ?? this.price,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      venueId: venueId ?? this.venueId,
      organizerId: organizerId ?? this.organizerId,
      eventbriteId: eventbriteId ?? this.eventbriteId,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      attendees: attendees ?? this.attendees,
      createdBy: createdBy ?? this.createdBy,
    );
  }

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
      eventDate: eventDate,
      location: eventLocation,
      participantLimit: evenParticipantNumber,
      duration: eventDuration,
    );
  }

  // Custom factory constructor for EventBrite API data
  factory EventData.fromEventBrite(Map<String, dynamic> json) {
    try {
      // Extract and safely handle required fields
      String id = json['id']?.toString() ?? '';

      // Extract title from various potential paths
      String title;
      if (json['name'] != null) {
        if (json['name'] is Map) {
          title = json['name']['text'] ?? json['name']['html'] ?? 'Untitled Event';
        } else if (json['name'] is String) {
          title = json['name'];
        } else {
          title = 'Untitled Event';
        }
      } else {
        title = 'Untitled Event';
      }

      // Extract description from various potential paths
      String? description;
      if (json['description'] != null) {
        if (json['description'] is Map) {
          description = json['description']['text'] ?? json['description']['html'] ?? '';
        } else if (json['description'] is String) {
          description = json['description'];
        }
      }

      // Parse dates safely
      DateTime startDate;
      DateTime? endDate;

      // Extract start date from various potential paths
      if (json['start'] != null) {
        String? rawStartDate;
        if (json['start'] is Map) {
          rawStartDate = json['start']['utc'] ?? json['start']['local'] ?? json['start']['timezone'];
        } else if (json['start'] is String) {
          rawStartDate = json['start'];
        }

        if (rawStartDate != null) {
          try {
            startDate = DateTime.parse(rawStartDate);
          } catch (e) {
            // Fallback to current date if parsing fails
            startDate = DateTime.now();
          }
        } else {
          // Default to current date if no start date found
          startDate = DateTime.now();
        }
      } else if (json['start_date'] != null) {
        try {
          startDate = DateTime.parse(json['start_date'].toString());
        } catch (e) {
          startDate = DateTime.now();
        }
      } else {
        // Default to current date if no start date found
        startDate = DateTime.now();
      }

      // Extract end date from various potential paths
      if (json['end'] != null) {
        String? rawEndDate;
        if (json['end'] is Map) {
          rawEndDate = json['end']['utc'] ?? json['end']['local'] ?? json['end']['timezone'];
        } else if (json['end'] is String) {
          rawEndDate = json['end'];
        }

        if (rawEndDate != null) {
          try {
            endDate = DateTime.parse(rawEndDate);
          } catch (e) {
            // End date is optional, it's fine if it's null
          }
        }
      } else if (json['end_date'] != null) {
        try {
          endDate = DateTime.parse(json['end_date'].toString());
        } catch (e) {
          // End date is optional
        }
      }

      // Calculate duration if both dates are available
      Duration? duration;
      if (startDate != null && endDate != null) {
        duration = endDate.difference(startDate);
      }

      // Extract venue and location information
      String? location;
      String? venueId;
      double? latitude;
      double? longitude;

      if (json['venue'] != null) {
        // Try to extract venue ID
        venueId = json['venue'] is Map ? json['venue']['id']?.toString() : null;

        // Try to extract location from venue
        if (json['venue'] is Map) {
          var venue = json['venue'];
          List<String> locationParts = [];

          // Add venue name if available
          if (venue['name'] != null) {
            locationParts.add(venue['name'].toString());
          }

          // Add address components if available
          if (venue['address'] != null && venue['address'] is Map) {
            var address = venue['address'];

            // Try different address field naming patterns
            var addressLine = address['address_1'] ??
                address['line1'] ??
                address['street_address'] ??
                address['address'] ??
                address['localized_address_display'];

            if (addressLine != null) {
              locationParts.add(addressLine.toString());
            }

            // Add city if available
            var city = address['city'] ?? address['town'] ?? address['locality'];
            if (city != null) {
              locationParts.add(city.toString());
            }

            // Add region/state if available
            var region = address['region'] ?? address['state'] ?? address['administrative_area'];
            if (region != null) {
              locationParts.add(region.toString());
            }

            // Add postal code if available
            var postalCode = address['postal_code'] ?? address['zip'] ?? address['zip_code'];
            if (postalCode != null) {
              locationParts.add(postalCode.toString());
            }
          }

          // Extract latitude/longitude if available
          if (venue['latitude'] != null && venue['longitude'] != null) {
            try {
              latitude = double.parse(venue['latitude'].toString());
              longitude = double.parse(venue['longitude'].toString());
            } catch (e) {
              // Ignore if parsing fails
            }
          }

          // Compile location string if parts were found
          if (locationParts.isNotEmpty) {
            location = locationParts.join(', ');
          }
        } else if (json['venue'] is String) {
          // If venue is just a string, use that
          location = json['venue'].toString();
        }
      } else if (json['location'] != null) {
        // Direct location field
        if (json['location'] is Map) {
          var loc = json['location'];
          List<String> locationParts = [];

          var name = loc['name'] ?? loc['venue'];
          if (name != null) {
            locationParts.add(name.toString());
          }

          var address = loc['address'] ?? loc['display_address'];
          if (address != null) {
            if (address is String) {
              locationParts.add(address);
            } else if (address is Map) {
              // Handle address as a map
              var addressLine = address['address_1'] ?? address['line1'] ?? address['display'];
              if (addressLine != null) {
                locationParts.add(addressLine.toString());
              }
            }
          }

          // Extract latitude/longitude if available
          if (loc['latitude'] != null && loc['longitude'] != null) {
            try {
              latitude = double.parse(loc['latitude'].toString());
              longitude = double.parse(loc['longitude'].toString());
            } catch (e) {
              // Ignore if parsing fails
            }
          }

          if (locationParts.isNotEmpty) {
            location = locationParts.join(', ');
          }
        } else {
          // If location is just a string, use that
          location = json['location'].toString();
        }
      }

      // Extract category if available
      String? category;
      if (json['category'] != null) {
        if (json['category'] is Map) {
          category = json['category']['name']?.toString();
        } else {
          category = json['category'].toString();
        }
      } else if (json['categories'] != null && json['categories'] is List && (json['categories'] as List).isNotEmpty) {
        final categories = json['categories'] as List;
        if (categories[0] is Map) {
          category = categories[0]['name']?.toString();
        } else {
          category = categories[0].toString();
        }
      }

      // Extract organizer information
      String? organizer;
      String? organizerId;

      if (json['organizer'] != null) {
        if (json['organizer'] is Map) {
          organizerId = json['organizer']['id']?.toString();
          organizer = json['organizer']['name'] ?? json['organizer']['description'];
        } else if (json['organizer'] is String) {
          organizer = json['organizer'];
        }
      }

      // Extract pricing information
      bool isFree = json['is_free'] == true;
      String? price;

      if (!isFree) {
        // Try to get price from ticket_availability
        if (json['ticket_availability'] != null && json['ticket_availability'] is Map) {
          var ticketInfo = json['ticket_availability'];

          if (ticketInfo['minimum_ticket_price'] != null && ticketInfo['minimum_ticket_price'] is Map) {
            var priceInfo = ticketInfo['minimum_ticket_price'];
            var currency = priceInfo['currency'] ?? 'USD';
            var value = priceInfo['value'] ?? '0';
            price = '$currency $value';
          }
        }
        // Try to get price from cost field
        else if (json['cost'] != null) {
          if (json['cost'] is Map) {
            var priceInfo = json['cost'];
            var currency = priceInfo['currency'] ?? 'USD';
            var value = priceInfo['value'] ?? '0';
            price = '$currency $value';
          } else {
            price = json['cost'].toString();
          }
        }
        // Try to get price from price field
        else if (json['price'] != null) {
          price = json['price'].toString();
        }
      }

      // Extract image URL
      String? imageUrl;
      if (json['logo'] != null) {
        if (json['logo'] is Map) {
          // Try various image URL paths
          imageUrl = json['logo']['url'] ??
              json['logo']['original'] ??
              json['logo']['original']['url'];
        } else if (json['logo'] is String) {
          imageUrl = json['logo'];
        }
      } else if (json['image'] != null) {
        if (json['image'] is Map) {
          imageUrl = json['image']['url'] ?? json['image']['original'];
        } else if (json['image'] is String) {
          imageUrl = json['image'];
        }
      }

      // Extract participant limit/capacity
      int? capacity;
      int? participantLimit;

      if (json['capacity'] != null) {
        try {
          capacity = int.parse(json['capacity'].toString());
          participantLimit = capacity; // Use capacity for participantLimit as well
        } catch (e) {
          // Leave as null if parsing fails
        }
      }

      // Attempt to extract difficulty level (1-5)
      int? difficulty;
      if (json['difficulty'] != null) {
        try {
          difficulty = int.parse(json['difficulty'].toString());
          // Ensure it's in the valid range
          if (difficulty! < 1 || difficulty > 5) {
            difficulty = null;
          }
        } catch (e) {
          // Ignore if parsing fails
        }
      }

      // Extract status
      String? status = json['status']?.toString();

      // Extract URL
      String? url;
      if (json['url'] != null) {
        url = json['url'].toString();
      } else if (json['event_url'] != null) {
        url = json['event_url'].toString();
      }

      return EventData(
        id: id,
        eventbriteId: id, // Store the EventBrite ID as well
        title: title,
        description: description,
        eventDate: startDate,
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
        participantLimit: participantLimit,
        duration: duration,
        category: category,
        difficulty: difficulty,
        latitude: latitude,
        longitude: longitude,
        attendees: [], // Default empty attendees list
      );
    } catch (e) {
      // If there's any error parsing the event, return a fallback event
      return EventData(
        id: json['id']?.toString() ?? 'unknown',
        title: 'Event Data Error',
        description: 'There was an error parsing this event from EventBrite: $e',
        eventDate: DateTime.now(), // Use current date as fallback
      );
    }
  }

  // Convert to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'eventDate': eventDate,
      'location': location,
      'participantLimit': participantLimit,
      'duration': duration?.inMinutes,
      'endDate': endDate,
      'imageUrl': imageUrl,
      'organizer': organizer,
      'url': url,
      'isFree': isFree,
      'price': price,
      'capacity': capacity,
      'status': status,
      'venueId': venueId,
      'organizerId': organizerId,
      'eventbriteId': eventbriteId,
      'category': category,
      'difficulty': difficulty,
      'latitude': latitude,
      'longitude': longitude,
      'attendees': attendees,
      'createdBy': createdBy,
    };
  }

  // Factory constructor for Map data (from Firestore or local storage)
  factory EventData.fromMap(Map<String, dynamic> data) {
    // Handle date conversions from Firestore Timestamp type
    DateTime eventDate;
    DateTime? endDate;
    Duration? duration;

    // Parse eventDate (renamed from startDate)
    if (data['eventDate'] != null) {
      if (data['eventDate'] is Timestamp) {
        eventDate = (data['eventDate'] as Timestamp).toDate();
      } else if (data['eventDate'] is String) {
        try {
          eventDate = DateTime.parse(data['eventDate'] as String);
        } catch (_) {
          eventDate = DateTime.now(); // Fallback
        }
      } else if (data['eventDate'] is DateTime) {
        eventDate = data['eventDate'] as DateTime;
      } else {
        eventDate = DateTime.now(); // Default fallback
      }
    } else if (data['startDate'] != null) {
      // Try the old field name for backward compatibility
      if (data['startDate'] is Timestamp) {
        eventDate = (data['startDate'] as Timestamp).toDate();
      } else if (data['startDate'] is String) {
        try {
          eventDate = DateTime.parse(data['startDate'] as String);
        } catch (_) {
          eventDate = DateTime.now(); // Fallback
        }
      } else if (data['startDate'] is DateTime) {
        eventDate = data['startDate'] as DateTime;
      } else {
        eventDate = DateTime.now(); // Default fallback
      }
    } else {
      eventDate = DateTime.now(); // Default fallback
    }

    // Parse endDate
    if (data['endDate'] != null) {
      if (data['endDate'] is Timestamp) {
        endDate = (data['endDate'] as Timestamp).toDate();
      } else if (data['endDate'] is String) {
        try {
          endDate = DateTime.parse(data['endDate'] as String);
        } catch (_) {}
      } else if (data['endDate'] is DateTime) {
        endDate = data['endDate'] as DateTime;
      }
    }

    // Calculate duration if both dates are available
    if (eventDate != null && endDate != null) {
      duration = endDate.difference(eventDate);
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

    // Extract and normalize title
    String title = data['title'] as String? ?? 'Unnamed Event';

    // Extract category
    String? category = data['category'] as String?;

    // Extract difficulty
    int? difficulty = _parseIntSafely(data['difficulty']);

    // Extract coordinates
    double? latitude = _parseDoubleSafely(data['latitude']);
    double? longitude = _parseDoubleSafely(data['longitude']);

    // Extract attendees
    List<String>? attendees;
    if (data['attendees'] != null) {
      if (data['attendees'] is List) {
        attendees = List<String>.from(data['attendees'] as List);
      }
    }

    // Extract creator
    String? createdBy = data['createdBy'] as String?;

    // Use document ID if id field is missing
    String id = (data['id'] as String?) ?? '';

    return EventData(
      id: id,
      title: title,
      description: data['description'] as String?,
      eventDate: eventDate,
      endDate: endDate,
      location: data['location'] as String?,
      imageUrl: data['imageUrl'] as String?,
      organizer: data['organizer'] as String?,
      url: data['url'] as String?,
      isFree: data['isFree'] as bool?,
      price: data['price'] as String?,
      capacity: _parseIntSafely(data['capacity']),
      status: data['status'] as String?,
      venueId: data['venueId'] as String?,
      organizerId: data['organizerId'] as String?,
      eventbriteId: data['eventbriteId'] as String?,
      participantLimit: _parseIntSafely(data['participantLimit']),
      duration: duration,
      category: category,
      difficulty: difficulty,
      latitude: latitude,
      longitude: longitude,
      attendees: attendees,
      createdBy: createdBy,
    );
  }

  // Helper methods for formatting
  String getFormattedStartDate() {
    return DateFormat('MMM dd, yyyy • h:mm a').format(eventDate);
  }

  String getFormattedDateRange() {
    String start = DateFormat('MMM dd, yyyy • h:mm a').format(eventDate);

    if (endDate == null) return start;

    // If same day, just show time range
    if (eventDate.year == endDate!.year &&
        eventDate.month == endDate!.month &&
        eventDate.day == endDate!.day) {
      return '${DateFormat('MMM dd, yyyy').format(eventDate)} • ' +
          '${DateFormat('h:mm a').format(eventDate)} - ' +
          '${DateFormat('h:mm a').format(endDate!)}';
    } else {
      // Show full date range
      return '${DateFormat('MMM dd, yyyy • h:mm a').format(eventDate)} - ' +
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
        other.eventDate == eventDate &&
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
      eventDate,
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

  // Helper method to safely parse double values
  static double? _parseDoubleSafely(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}