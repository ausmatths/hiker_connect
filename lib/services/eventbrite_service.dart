import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/event_data.dart';

class EventBriteService {
  static const String _baseUrl = 'https://www.eventbriteapi.com/v3';

  // Storage keys for secure storage
  static const String _privateTokenKey = 'eventbrite_private_token';
  static const String _clientSecretKey = 'eventbrite_client_secret';

  String? _privateToken;
  String? _clientSecret;
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;

  EventBriteService({
    String? privateToken,
    String? clientSecret,
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  }) :
        _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage() {

    // Store credentials securely if provided
    if (privateToken != null) {
      _storeTokenSecurely(_privateTokenKey, privateToken);
      _privateToken = privateToken;
    }

    if (clientSecret != null) {
      _storeTokenSecurely(_clientSecretKey, clientSecret);
      _clientSecret = clientSecret;
    }

    // Log that service was initialized (without revealing tokens)
    developer.log(
        'EventBriteService initialized. Will load tokens from secure storage when needed.',
        name: 'EventBriteService'
    );
  }

  // Store token in secure storage
  Future<void> _storeTokenSecurely(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      developer.log('Stored token securely: $key', name: 'EventBriteService');
    } catch (e) {
      developer.log('Error storing token securely: $e', name: 'EventBriteService');
    }
  }

  // Get private token - from memory or secure storage
  Future<String?> get privateToken async {
    if (_privateToken != null) return _privateToken;

    try {
      _privateToken = await _secureStorage.read(key: _privateTokenKey);
      return _privateToken;
    } catch (e) {
      developer.log('Error reading private token from secure storage: $e', name: 'EventBriteService');
      return null;
    }
  }

  // Get client secret - from memory or secure storage
  Future<String?> get clientSecret async {
    if (_clientSecret != null) return _clientSecret;

    try {
      _clientSecret = await _secureStorage.read(key: _clientSecretKey);
      return _clientSecret;
    } catch (e) {
      developer.log('Error reading client secret from secure storage: $e', name: 'EventBriteService');
      return null;
    }
  }

  /// Try to validate the token, but allow continuing even if validation fails
  Future<bool> validateToken() async {
    try {
      // Try different auth methods
      final methods = [
        _validateWithPrivateToken,
        _validateWithClientSecret,
        _validateWithTokenParam
      ];

      for (var method in methods) {
        try {
          final result = await method();
          if (result) {
            return true;
          }
        } catch (e) {
          developer.log('Auth method failed: $e', name: 'EventBriteService');
          // Continue to next method
        }
      }

      // If we get here, all validation methods failed
      developer.log('All token validation methods failed', name: 'EventBriteService');
      return false;
    } catch (e) {
      developer.log('Error in validateToken: $e', name: 'EventBriteService');
      return false;
    }
  }

  Future<bool> _validateWithPrivateToken() async {
    final token = await privateToken;
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/users/me/');
    developer.log('Validating with private token', name: 'EventBriteService');

    final response = await _client.get(
      url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-API-Version': '3'
        }
    );

    developer.log('Private token validation response: ${response.statusCode}', name: 'EventBriteService');
    return response.statusCode == 200;
  }

  Future<bool> _validateWithClientSecret() async {
    final secret = await clientSecret;
    if (secret == null) return false;

    final url = Uri.parse('$_baseUrl/users/me/');
    developer.log('Validating with client secret', name: 'EventBriteService');

    final response = await _client.get(
      url,
      headers: {
        'Authorization': 'Bearer $secret',
        'Content-Type': 'application/json',
      },
    );

    developer.log('Client secret validation response: ${response.statusCode}', name: 'EventBriteService');
    return response.statusCode == 200;
  }

  Future<bool> _validateWithTokenParam() async {
    final token = await privateToken;
    if (token == null) return false;

    final url = Uri.parse('$_baseUrl/users/me/?token=$token');
    developer.log('Validating with token param', name: 'EventBriteService');

    final response = await _client.get(url);

    developer.log('Token param validation response: ${response.statusCode}', name: 'EventBriteService');
    return response.statusCode == 200;
  }

  Future<List<EventData>> getEvents({int? page, int pageSize = 10}) async {
    try {
      // Try to validate token, but continue even if it fails
      final isTokenValid = await validateToken();
      developer.log('Token validation result: $isTokenValid', name: 'EventBriteService');

      // If token is valid, try to fetch real events
      if (isTokenValid) {
        try {
          final token = await privateToken;
          if (token == null) throw Exception('No private token available');

          final url = Uri.parse('$_baseUrl/events/search/')
              .replace(queryParameters: {
            'expand': 'venue,organizer,ticket_availability',
            'page': (page ?? 1).toString(),
            'page_size': pageSize.toString(),
            'token': token,
          });

          developer.log('Fetching events from API', name: 'EventBriteService');

          final response = await _client.get(url);

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            final List<dynamic> events = data['events'] ?? [];

            developer.log('Successfully fetched ${events.length} events from API', name: 'EventBriteService');
            return events.map((eventJson) => EventData.fromEventBrite(eventJson)).toList();
          } else {
            developer.log('API error: ${response.statusCode}', name: 'EventBriteService');
            throw Exception('API returned status code ${response.statusCode}');
          }
        } catch (e) {
          developer.log('Error fetching events from API: $e', name: 'EventBriteService');
          throw Exception('Error fetching from API: $e');
        }
      }

      // If we get here, either token validation failed or API request failed
      throw Exception('Using sample data');
    } catch (e) {
      // Use fallback data
      developer.log('Falling back to sample events', name: 'EventBriteService');
      return _getSampleEvents();
    }
  }



  // Replace your existing EventBriteService searchHikingEvents method with this
// improved version that handles multiple API change scenarios

  Future<List<EventData>> searchHikingEvents({
    String? location,
    String? startDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Try to validate token, but continue even if it fails
      final isTokenValid = await validateToken();
      developer.log('Token validation result: $isTokenValid', name: 'EventBriteService');

      // If token is valid, try to fetch real events
      if (isTokenValid) {
        try {
          final token = await privateToken;
          if (token == null) throw Exception('No private token available');

          // First attempt: Try organization events (most reliable approach)
          try {
            return await getUpcomingEvents(page: page, pageSize: pageSize);
          } catch (e) {
            developer.log('Organization events approach failed: $e', name: 'EventBriteService');
            // Continue to next approach
          }

          // Second attempt: Try direct search with minimal parameters
          try {
            final searchUrl = Uri.parse('$_baseUrl/events/search')
                .replace(queryParameters: {
              'token': token,
              'q': 'hiking',
              'page': page.toString(),
              'page_size': pageSize.toString(),
            });

            developer.log('Trying direct search: ${searchUrl.toString().replaceAll(token, '[TOKEN]')}',
                name: 'EventBriteService');

            final searchResponse = await _client.get(searchUrl);

            if (searchResponse.statusCode == 200) {
              final searchData = json.decode(searchResponse.body);
              final events = searchData['events'] as List?;

              if (events != null && events.isNotEmpty) {
                developer.log('Direct search succeeded with ${events.length} events', name: 'EventBriteService');
                return events.map((eventJson) => EventData.fromEventBrite(eventJson)).toList();
              }
            }

            developer.log('Direct search failed or returned no events: ${searchResponse.statusCode}',
                name: 'EventBriteService');
          } catch (e) {
            developer.log('Direct search failed: $e', name: 'EventBriteService');
          }

          // Third attempt: Try featured events endpoint
          try {
            final featuredUrl = Uri.parse('$_baseUrl/events')
                .replace(queryParameters: {
              'token': token,
              'page': page.toString(),
              'page_size': pageSize.toString(),
            });

            developer.log('Trying featured events: ${featuredUrl.toString().replaceAll(token, '[TOKEN]')}',
                name: 'EventBriteService');

            final featuredResponse = await _client.get(featuredUrl);

            if (featuredResponse.statusCode == 200) {
              final featuredData = json.decode(featuredResponse.body);
              final events = featuredData['events'] as List?;

              if (events != null && events.isNotEmpty) {
                developer.log('Featured events succeeded with ${events.length} events', name: 'EventBriteService');
                return events.map((eventJson) => EventData.fromEventBrite(eventJson)).toList();
              }
            }

            developer.log('Featured events failed or returned no events: ${featuredResponse.statusCode}',
                name: 'EventBriteService');
          } catch (e) {
            developer.log('Featured events failed: $e', name: 'EventBriteService');
          }

          // All approaches failed
          throw Exception('All API approaches failed');
        } catch (e) {
          developer.log('Error searching events from API: $e', name: 'EventBriteService');
          throw Exception('Error searching from API: $e');
        }
      }

      // If we get here, either token validation failed or API request failed
      throw Exception('Using sample data');
    } catch (e) {
      // Use fallback data
      developer.log('Falling back to sample events for search', name: 'EventBriteService');
      return _getSampleEvents();
    }
  }

// Alternative search approach using categories instead of keyword search
  Future<List<EventData>> _searchEventsByCategory(
      String token,
      String? location,
      String? startDate,
      int page,
      int pageSize,
      ) async {
    try {
      // Use category-based search instead of keyword search
      Map<String, String> queryParams = {
        'token': token,
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'categories': '108', // Sports & Fitness
        'expand': 'venue,organizer,ticket_availability',
      };

      // Add location filter if provided
      if (location != null && location.isNotEmpty) {
        queryParams['location.address'] = location;
      }

      // Add date filter if provided
      if (startDate != null && startDate.isNotEmpty) {
        try {
          final DateTime date = DateTime.parse(startDate);
          final String formattedDate = "${date.toIso8601String().split('T')[0]}T00:00:00Z";
          queryParams['start_date.range_start'] = formattedDate;
        } catch (e) {
          developer.log('Invalid date format: $startDate', name: 'EventBriteService');
        }
      }

      final url = Uri.parse('$_baseUrl/events/search/').replace(queryParameters: queryParams);
      developer.log('Trying alternative search: ${url.toString()}', name: 'EventBriteService');

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> events = data['events'] ?? [];

        developer.log('Alternative search found ${events.length} events', name: 'EventBriteService');
        return events.map((eventJson) => EventData.fromEventBrite(eventJson)).toList();
      } else {
        developer.log('Alternative search also failed: ${response.statusCode}', name: 'EventBriteService');
        throw Exception('API returned status code ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error in alternative search: $e', name: 'EventBriteService');
      throw e; // Let the caller handle this
    }
  }

  Future<EventData> getEventDetails(String eventId) async {
    try {
      // Check if this is one of our sample events
      if (eventId.startsWith('sample-')) {
        final sampleEvents = _getSampleEvents();
        for (var event in sampleEvents) {
          if (event.id == eventId) {
            return event;
          }
        }
      }

      // Try to validate token, but continue even if it fails
      final isTokenValid = await validateToken();
      developer.log('Token validation result for event details: $isTokenValid', name: 'EventBriteService');

      // If token is valid, try to fetch real event details
      if (isTokenValid) {
        try {
          final token = await privateToken;
          if (token == null) throw Exception('No private token available');

          final url = Uri.parse('$_baseUrl/events/$eventId/')
              .replace(queryParameters: {
            'expand': 'venue,organizer,ticket_classes,ticket_availability',
            'token': token,
          });

          developer.log('Fetching event details for ID: $eventId', name: 'EventBriteService');

          final response = await _client.get(url);

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            developer.log('Successfully fetched event details for ID: $eventId', name: 'EventBriteService');
            return EventData.fromEventBrite(data);
          } else {
            developer.log('API error fetching event details: ${response.statusCode}', name: 'EventBriteService');
            throw Exception('API returned status code ${response.statusCode}');
          }
        } catch (e) {
          developer.log('Error fetching event details from API: $e', name: 'EventBriteService');
          throw Exception('Error fetching event details: $e');
        }
      }

      // If we get here, either token validation failed or API request failed
      throw Exception('Unable to find event, using generic fallback');
    } catch (e) {
      // Return a generic event as fallback
      developer.log('Returning generic event details as fallback', name: 'EventBriteService');
      return EventData(
        id: eventId,
        title: 'Event information unavailable',
        description: 'We were unable to load the details for this event. Please check your internet connection and try again later.',
        startDate: DateTime.now(), // Ensure we provide a non-null DateTime for startDate
      );
    }
  }

  // Add this method to your EventBriteService class as an alternative
// to fetch events if the primary search method fails

  Future<List<EventData>> getUpcomingEvents({int page = 1, int pageSize = 20}) async {
    try {
      final token = await privateToken;
      if (token == null) throw Exception('No private token available');

      // Try to use organizations endpoint to get events (more reliable)
      // First get the organization ID
      final orgUrl = Uri.parse('$_baseUrl/users/me/organizations')
          .replace(queryParameters: {'token': token});

      developer.log('Fetching user organizations: ${orgUrl.toString().replaceAll(token, '[TOKEN]')}',
          name: 'EventBriteService');

      final orgResponse = await _client.get(orgUrl);

      if (orgResponse.statusCode != 200) {
        throw Exception('Failed to get organizations: ${orgResponse.statusCode}');
      }

      final orgData = json.decode(orgResponse.body);
      final organizations = orgData['organizations'] as List?;

      if (organizations == null || organizations.isEmpty) {
        throw Exception('No organizations found');
      }

      // Use the first organization to get events
      final orgId = organizations[0]['id'];

      // Get organization events
      final eventsUrl = Uri.parse('$_baseUrl/organizations/$orgId/events')
          .replace(queryParameters: {
        'token': token,
        'status': 'live',
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'expand': 'venue,ticket_availability'
      });

      developer.log('Fetching organization events: ${eventsUrl.toString().replaceAll(token, '[TOKEN]')}',
          name: 'EventBriteService');

      final eventsResponse = await _client.get(eventsUrl);

      if (eventsResponse.statusCode != 200) {
        throw Exception('Failed to get organization events: ${eventsResponse.statusCode}');
      }

      final eventsData = json.decode(eventsResponse.body);
      final events = eventsData['events'] as List?;

      if (events == null || events.isEmpty) {
        throw Exception('No events found for organization');
      }

      return events.map((eventJson) => EventData.fromEventBrite(eventJson)).toList();
    } catch (e) {
      developer.log('Error in getUpcomingEvents: $e', name: 'EventBriteService');
      return _getSampleEvents();
    }
  }

  // Sample event data to use when API calls fail
  List<EventData> _getSampleEvents() {
    developer.log('Creating sample events', name: 'EventBriteService');
    final now = DateTime.now();

    return [
      EventData(
        id: 'sample-1',
        title: 'Mountain Trail Adventure',
        description: 'Join us for an exciting day hiking the scenic mountain trails. '
            'This event is perfect for nature lovers and photography enthusiasts. '
            'Experienced guides will lead the way and share interesting facts about the local ecosystem.',
        startDate: now.add(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 5, hours: 4)),
        location: 'Blue Mountain Trail, Boulder, CO',
        participantLimit: 20,
        duration: const Duration(hours: 4),
        imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306',
        organizer: 'Mountain Trekkers Club',
        isFree: false,
        price: 'USD 25.00',
        status: 'live',
      ),
      EventData(
        id: 'sample-2',
        title: 'Nature Photography Hike',
        description: 'Bring your camera and capture the beauty of spring wildflowers. '
            'Our photography guide will provide tips on capturing the best nature shots. '
            'This is a beginner-friendly event open to all skill levels.',
        startDate: now.add(const Duration(days: 12)),
        endDate: now.add(const Duration(days: 12, hours: 3)),
        location: 'Wildflower Ridge Trail, Portland, OR',
        participantLimit: 15,
        duration: const Duration(hours: 3),
        imageUrl: 'https://images.unsplash.com/photo-1542202229-7d93c33f5d07',
        organizer: 'Photography Explorers',
        isFree: true,
        status: 'live',
      ),
      EventData(
        id: 'sample-3',
        title: 'Sunset Hiking Adventure',
        description: 'Experience the magic of sunset from a scenic mountain viewpoint. '
            'This evening hike offers breathtaking views and great photo opportunities. '
            'We\'ll end the hike under the stars for a truly memorable experience.',
        startDate: now.add(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 7, hours: 2, minutes: 30)),
        location: 'Sunset Peak, Malibu, CA',
        participantLimit: 12,
        duration: const Duration(hours: 2, minutes: 30),
        imageUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071',
        organizer: 'Outdoor Adventures Group',
        isFree: false,
        price: 'USD 15.00',
        status: 'live',
      ),
      EventData(
        id: 'sample-4',
        title: 'Family-Friendly Nature Walk',
        description: 'A gentle walk suitable for families with children of all ages. '
            'Learn about local plants and wildlife while enjoying beautiful surroundings. '
            'Includes interactive activities for kids along the trail.',
        startDate: now.add(const Duration(days: 3)),
        endDate: now.add(const Duration(days: 3, hours: 2)),
        location: 'Green Valley Park, Seattle, WA',
        participantLimit: 25,
        duration: const Duration(hours: 2),
        imageUrl: 'https://images.unsplash.com/photo-1501555088652-021faa106b9b',
        organizer: 'Family Outdoor Club',
        isFree: true,
        status: 'live',
      ),
      EventData(
        id: 'sample-5',
        title: 'Waterfall Hiking Tour',
        description: 'Explore multiple stunning waterfalls on this guided hiking tour. '
            'The trail features moderate difficulty with some steep sections. '
            'Be prepared to get sprayed as we get close to these magnificent natural wonders!',
        startDate: now.add(const Duration(days: 14)),
        endDate: now.add(const Duration(days: 14, hours: 5)),
        location: 'Silver Falls Trail, Eugene, OR',
        participantLimit: 18,
        duration: const Duration(hours: 5),
        imageUrl: 'https://images.unsplash.com/photo-1432405972618-c60b0225b8f9',
        organizer: 'Waterfall Chasers',
        isFree: false,
        price: 'USD 30.00',
        status: 'live',
      ),
    ];
  }

  void dispose() {
    _client.close();
  }
}