import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/event_data.dart';

class EventBriteService {
  static const String _baseUrl = 'https://www.eventbriteapi.com/v3';

  // Using your correct tokens from your Eventbrite account
  final String _publicToken;
  final String _privateToken;
  final http.Client _client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Flag to track if we've already attempted with a fresh token
  bool _hasAttemptedWithFreshToken = false;

  EventBriteService({
    required String publicToken,
    required String privateToken,
    http.Client? client,
  }) :
        _publicToken = publicToken,
        _privateToken = privateToken,
        _client = client ?? http.Client() {
    // Log the tokens being used
    developer.log('EventBriteService initialized with tokens:\nPublic: $_publicToken\nPrivate: $_privateToken',
        name: 'EventBriteService');
  }

  /// Modify your validateToken method
  Future<bool> validateToken({bool privileged = false}) async {
    try {
      final token = await _getToken(privileged: privileged);

      if (token.isEmpty) {
        developer.log('Empty token, validation failed', name: 'EventBriteService');
        return false;
      }

      // Try both authentication methods
      // Method 1: Bearer token in header
      Uri url1 = Uri.parse('$_baseUrl/users/me/');
      developer.log('Trying header auth: ${url1.toString()}', name: 'EventBriteService');

      final response1 = await _client.get(
        url1,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Method 2: Token as query parameter
      Uri url2 = Uri.parse('$_baseUrl/users/me/?token=$token');
      developer.log('Trying query param auth: ${url2.toString()}', name: 'EventBriteService');

      final response2 = await _client.get(
        url2,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      developer.log('Auth method 1 status: ${response1.statusCode}', name: 'EventBriteService');
      developer.log('Auth method 2 status: ${response2.statusCode}', name: 'EventBriteService');

      // If either method works, return true
      if (response1.statusCode == 200 || response2.statusCode == 200) {
        developer.log('Token validated successfully', name: 'EventBriteService');
        return true;
      } else {
        // Log full response for debugging
        developer.log('Full response 1: ${response1.body}', name: 'EventBriteService');
        developer.log('Full response 2: ${response2.body}', name: 'EventBriteService');
        return false;
      }
    } catch (e) {
      developer.log('Error validating token: $e', name: 'EventBriteService');
      return false;
    }
  }

  /// Determines which token to use based on the operation
  Future<String> _getToken({bool privileged = false}) async {
    try {
      // For this specific app, it seems we should just use the tokens directly
      // since we're seeing errors with the stored tokens
      if (privileged) {
        return _privateToken; // Use "5D5NPXG5TIPXU6GLFNCF"
      } else {
        return _publicToken; // Use "V7IFGJ6CYWAWYOZAGN27"
      }

      // The code below is kept commented to simplify for now
      /*
      // Priority:
      // 1. Secure storage token
      // 2. Provided tokens
      // 3. Fallback to public token

      if (privileged) {
        // For privileged operations, try private token first
        final storedPrivateToken = await _secureStorage.read(key: 'eventbrite_private_token');
        if (storedPrivateToken != null && storedPrivateToken.isNotEmpty) {
          return storedPrivateToken;
        }
        return _privateToken;
      } else {
        // For read-only operations, use public token
        final storedPublicToken = await _secureStorage.read(key: 'eventbrite_public_token');
        if (storedPublicToken != null && storedPublicToken.isNotEmpty) {
          return storedPublicToken;
        }
        return _publicToken;
      }
      */
    } catch (e) {
      developer.log(
          'Error retrieving EventBrite token',
          name: 'EventBriteService',
          error: e
      );
      // Fallback to default tokens
      return privileged ? _privateToken : _publicToken;
    }
  }

  Future<List<EventData>> getEvents({
    int? page,
    int pageSize = 10,
    bool privileged = false,
  }) async {
    try {
      // Validate token first
      final isTokenValid = await validateToken(privileged: privileged);
      if (!isTokenValid) {
        developer.log('Token validation failed before fetching events', name: 'EventBriteService');
        throw Exception('Invalid EventBrite token');
      }

      final token = await _getToken(privileged: privileged);
      final Uri url = Uri.parse(
          '$_baseUrl/events/search/?expand=venue,organizer,ticket_availability&page=${page ?? 1}&page_size=$pageSize'
      );

      developer.log(
          'Fetching events from EventBrite API: ${url.toString()}',
          name: 'EventBriteService'
      );

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _handleResponseErrors(response);

      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> events = data['events'] ?? [];

      developer.log(
          'Successfully fetched ${events.length} events',
          name: 'EventBriteService'
      );

      // Reset the retry flag after successful request
      _hasAttemptedWithFreshToken = false;

      return events.map((eventJson) => EventData.fromEventBrite(eventJson)).toList();
    } catch (e) {
      developer.log(
          'Comprehensive error fetching events: $e',
          name: 'EventBriteService'
      );
      rethrow;
    }
  }

  Future<List<EventData>> searchHikingEvents({
    String? location,
    String? startDate,
    int page = 1,
    int pageSize = 20,
    bool privileged = false,
  }) async {
    try {
      // Validate token first
      final isTokenValid = await validateToken(privileged: privileged);
      if (!isTokenValid) {
        developer.log('Token validation failed before searching events', name: 'EventBriteService');
        throw Exception('Invalid EventBrite token');
      }

      final token = await _getToken(privileged: privileged);

      // Building the query parameters
      Map<String, String> queryParams = {
        'q': 'hiking OR trails OR outdoors OR nature',
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'expand': 'venue,organizer,ticket_availability',
      };

      // Add optional location and date filters
      if (location != null && location.isNotEmpty) {
        queryParams['location.address'] = location;
      }

      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date.range_start'] = startDate;
      }

      final Uri url = Uri.parse('$_baseUrl/events/search/').replace(
          queryParameters: queryParams
      );

      developer.log(
          'Searching hiking events: ${url.toString()}',
          name: 'EventBriteService'
      );

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      developer.log(
          'API Response status code: ${response.statusCode}',
          name: 'EventBriteService'
      );

      // Debug response body for more insight
      developer.log(
          'API Response first 200 chars: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}',
          name: 'EventBriteService'
      );

      try {
        _handleResponseErrors(response);

        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> events = data['events'] ?? [];

        developer.log(
            'Search returned ${events.length} hiking events',
            name: 'EventBriteService'
        );

        // Reset the retry flag after successful request
        _hasAttemptedWithFreshToken = false;

        return events.map((eventJson) => EventData.fromEventBrite(eventJson)).toList();
      } catch (e) {
        // Try one more time with a fresh token if not already attempted
        if (!_hasAttemptedWithFreshToken &&
            (e.toString().contains('401') || e.toString().contains('Unauthorized'))) {
          _hasAttemptedWithFreshToken = true;
          developer.log('Auth error, attempting again with fresh token', name: 'EventBriteService');

          // Clear any stored tokens
          await _secureStorage.delete(key: 'eventbrite_public_token');
          await _secureStorage.delete(key: 'eventbrite_private_token');

          // Retry the search with the same parameters
          return searchHikingEvents(
              location: location,
              startDate: startDate,
              page: page,
              pageSize: pageSize,
              privileged: privileged
          );
        }
        rethrow;
      }
    } catch (e) {
      developer.log(
          'Comprehensive error searching hiking events: $e',
          name: 'EventBriteService'
      );
      rethrow;
    }
  }

  Future<EventData> getEventDetails(
      String eventId,
      {bool privileged = false}
      ) async {
    try {
      // Validate token first
      final isTokenValid = await validateToken(privileged: privileged);
      if (!isTokenValid) {
        developer.log('Token validation failed before fetching event details', name: 'EventBriteService');
        throw Exception('Invalid EventBrite token');
      }

      final token = await _getToken(privileged: privileged);
      final Uri url = Uri.parse(
          '$_baseUrl/events/$eventId/?expand=venue,organizer,ticket_classes,ticket_availability'
      );

      developer.log(
          'Fetching event details for ID: $eventId',
          name: 'EventBriteService'
      );

      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      _handleResponseErrors(response);

      final Map<String, dynamic> data = json.decode(response.body);
      developer.log(
          'Successfully fetched event details for ID: $eventId',
          name: 'EventBriteService'
      );

      return EventData.fromEventBrite(data);
    } catch (e) {
      developer.log(
          'Comprehensive error fetching event details: $e',
          name: 'EventBriteService'
      );
      rethrow;
    }
  }

  // Helper method to handle HTTP response errors
  void _handleResponseErrors(http.Response response) {
    if (response.statusCode == 200) return;

    String errorMessage = 'Unknown error occurred';
    try {
      final Map<String, dynamic> errorBody = json.decode(response.body);
      errorMessage = errorBody['error_description'] ??
          errorBody['error'] ??
          errorMessage;
    } catch (_) {
      errorMessage = 'HTTP Error ${response.statusCode}: ${response.reasonPhrase}';
    }

    developer.log(
        'EventBrite API Error: $errorMessage',
        name: 'EventBriteService',
        error: {
          'statusCode': response.statusCode,
          'body': response.body
        }
    );

    throw Exception(errorMessage);
  }

  // Store a new token for future use
  Future<void> saveToken(String token, {bool isPrivate = false}) async {
    try {
      final key = isPrivate ? 'eventbrite_private_token' : 'eventbrite_public_token';
      await _secureStorage.write(key: key, value: token);
      developer.log('Saved new ${isPrivate ? 'private' : 'public'} token to secure storage',
          name: 'EventBriteService');
    } catch (e) {
      developer.log('Error saving token to secure storage: $e',
          name: 'EventBriteService');
    }
  }

  void dispose() {
    _client.close();
  }
}