import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/event_data.dart';

class EventBriteService {
  static const String _baseUrl = 'https://www.eventbriteapi.com/v3';

  final String _publicToken;
  final String _privateToken;
  final http.Client _client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  EventBriteService({
    required String publicToken,
    required String privateToken,
    http.Client? client,
  }) :
        _publicToken = publicToken,
        _privateToken = privateToken,
        _client = client ?? http.Client();

  /// Determines which token to use based on the operation
  Future<String> _getToken({bool privileged = false}) async {
    try {
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

      _handleResponseErrors(response);

      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> events = data['events'] ?? [];

      developer.log(
          'Search returned ${events.length} hiking events',
          name: 'EventBriteService'
      );

      return events.map((eventJson) => EventData.fromEventBrite(eventJson)).toList();
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

  void dispose() {
    _client.close();
  }
}