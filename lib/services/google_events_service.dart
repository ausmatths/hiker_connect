import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hiker_connect/models/event_data.dart';
import 'package:hiker_connect/utils/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for interacting with Google Calendar API to fetch hiking-related events
/// and Google Places API to find nearby points of interest
class GoogleEventsService {
  // Constants
  static const String _tokenKey = 'google_api_token';
  static const String _refreshTokenKey = 'google_refresh_token';
  static const String _apiKeyKey = 'google_api_key';
  static const String _userIdKey = 'google_user_id';

  // Client ID for OAuth using the provided configuration
  static const String _clientId = '967683373829-eoqa3g0hqfkbfciaapptjmgkncfo2bga.apps.googleusercontent.com';
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/calendar.readonly',
    'https://www.googleapis.com/auth/calendar.events.readonly',
  ];

  // Search keywords for hiking events
  static const List<String> _hikingKeywords = [
    'hiking', 'hike', 'trail', 'outdoor', 'mountain', 'trekking',
    'backpacking', 'camping', 'nature walk', 'trail running'
  ];

  // Storage for secure token management
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Google SignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
    // Using serverClientId instead of clientId to fix the warning
    serverClientId: _clientId,
  );

  // HTTP client for API requests
  http.Client? _client;

  // Authentication client
  calendar.CalendarApi? _calendarApi;

  // Status flags
  bool _isInitialized = false;
  bool _isAuthenticated = false;

  // User information
  String? _userId;

  // Constructor
  GoogleEventsService();

  /// Get the current user ID
  String? get currentUserId => _userId;

  /// Get the API key from environment variables
  String get apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Initialize the service
  Future<bool> initialize() async {
    try {
      AppLogger.info('Initializing Google Events Service');

      // Check if we already have tokens
      final token = await _secureStorage.read(key: _tokenKey);
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      // Load stored user ID if available
      _userId = await _secureStorage.read(key: _userIdKey);

      if (token != null && refreshToken != null) {
        // We have tokens, try to authenticate
        _isAuthenticated = await _authenticateWithToken(token, refreshToken);
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      AppLogger.error('Error initializing Google Events Service: $e');
      return false;
    }
  }

  /// Authenticate with stored token
  Future<bool> _authenticateWithToken(String token, String refreshToken) async {
    try {
      // Create credentials from tokens with proper UTC DateTime
      final credentials = AccessCredentials(
        AccessToken(
          'Bearer',
          token,
          DateTime.now().toUtc().add(Duration(hours: 1)), // Fix: add toUtc()
        ),
        refreshToken,
        _scopes,
      );

      // Create authenticated client
      _client = authenticatedClient(http.Client(), credentials);

      // Create Calendar API instance
      _calendarApi = calendar.CalendarApi(_client!);

      return true;
    } catch (e) {
      AppLogger.error('Failed to authenticate with token: $e');
      return false;
    }
  }

  // Add this to GoogleEventsService
  Future<bool> signInSilently() async {
    try {
      AppLogger.info('Attempting silent Google sign-in');

      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        AppLogger.warning('Silent sign-in failed');
        return false;
      }

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        AppLogger.warning('Failed to get access token from silent sign-in');
        return false;
      }

      _userId = account.id;
      await _secureStorage.write(key: _userIdKey, value: _userId);
      await _secureStorage.write(key: _tokenKey, value: auth.accessToken);

      // Check if refresh token is available
      if (auth.idToken != null) {
        // Using idToken as a temporary substitute when refreshToken isn't available
        await _secureStorage.write(key: _refreshTokenKey, value: auth.idToken);
      }

      // Try to authenticate with the token
      _isAuthenticated = await _authenticateWithToken(
        auth.accessToken!,
        auth.idToken ?? auth.accessToken!, // Using idToken as refreshToken if available
      );

      return _isAuthenticated;
    } catch (e) {
      AppLogger.error('Error during silent Google sign-in: $e');
      return false;
    }
  }

  Future<bool> signIn() async {
    try {
      AppLogger.info('Attempting Google sign-in');

      // Make sure we're not already signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Add a small delay before sign-in to ensure UI is ready
      await Future.delayed(Duration(milliseconds: 300));

      // Try interactive sign-in
      final account = await _googleSignIn.signIn();

      if (account == null) {
        AppLogger.warning('User canceled sign-in');
        return false;
      }

      // Get authentication data
      final auth = await account.authentication;

      if (auth.accessToken == null) {
        AppLogger.error('Failed to get access token');
        return false;
      }

      // Save user ID and tokens
      _userId = account.id;
      AppLogger.info('User successfully signed in: $_userId');

      await _secureStorage.write(key: _userIdKey, value: _userId);
      await _secureStorage.write(key: _tokenKey, value: auth.accessToken);

      // Store idToken if available (useful for some authentication flows)
      if (auth.idToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: auth.idToken);
      }

      // Try to authenticate with the token
      _isAuthenticated = await _authenticateWithToken(
        auth.accessToken!,
        auth.idToken ?? auth.accessToken!, // Using idToken as refreshToken if available
      );

      return _isAuthenticated;
    } catch (e) {
      AppLogger.error('Error during Google sign-in: $e');
      return false;
    }
  }

  // Add this to your GoogleEventsService
  Future<bool> debugSignInProcess() async {
    try {
      // Check Google Play Services availability (Android)
      if (Platform.isAndroid) {
        final googleSignIn = GoogleSignIn();
        final isAvailable = await googleSignIn.canAccessScopes(_scopes);
        developer.log('Google Play Services available: $isAvailable', name: 'GoogleSignIn');
      }

      // Check if already signed in
      final isSignedIn = await _googleSignIn.isSignedIn();
      developer.log('Already signed in: $isSignedIn', name: 'GoogleSignIn');

      // Test silent sign-in
      try {
        final account = await _googleSignIn.signInSilently();
        developer.log('Silent sign-in result: ${account != null}', name: 'GoogleSignIn');
      } catch (e) {
        developer.log('Silent sign-in error: $e', name: 'GoogleSignIn');
      }

      return true;
    } catch (e) {
      developer.log('Debug sign-in test failed: $e', name: 'GoogleSignIn');
      return false;
    }
  }

  /// Check if the service is authenticated
  Future<bool> isAuthenticated() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isAuthenticated;
  }

  /// Fetch hiking events from Google Calendar
  Future<List<EventData>> fetchEvents({int limit = 50}) async {
    try {
      if (!_isAuthenticated) {
        final success = await signIn();
        if (!success) {
          return getSampleEvents();
        }
      }

      // List to store all hiking events
      final List<EventData> events = [];

      // Get public calendars with hiking events
      for (final keyword in _hikingKeywords) {
        try {
          // Search for public events with this keyword
          final result = await _calendarApi!.events.list(
            'primary',
            q: keyword,
            maxResults: limit ~/ _hikingKeywords.length,
            timeMin: DateTime.now().toUtc(),
            timeMax: DateTime.now().add(Duration(days: 90)).toUtc(),
            singleEvents: true,
            orderBy: 'startTime',
          );

          if (result.items != null && result.items!.isNotEmpty) {
            // Convert each event to our EventData model
            for (final event in result.items!) {
              if (_isHikingEvent(event)) {
                events.add(_convertToEventData(event));
              }
            }
          }
        } catch (e) {
          AppLogger.warning('Error fetching events for keyword "$keyword": $e');
          // Continue with next keyword
        }
      }

      // Sort by date
      events.sort((a, b) => a.eventDate.compareTo(b.eventDate));

      // If no events found, return sample data
      if (events.isEmpty) {
        return getSampleEvents();
      }

      return events;
    } catch (e) {
      AppLogger.error('Error fetching events from Google: $e');
      return getSampleEvents();
    }
  }

  /// Check if an event is hiking-related
  bool _isHikingEvent(calendar.Event event) {
    // Check if any hiking keyword appears in the summary or description
    final summary = event.summary?.toLowerCase() ?? '';
    final description = event.description?.toLowerCase() ?? '';

    for (final keyword in _hikingKeywords) {
      if (summary.contains(keyword) || description.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Convert Google Calendar Event to EventData
  EventData _convertToEventData(calendar.Event event) {
    // Extract event ID
    final id = event.id ?? 'unknown';

    // Extract title
    final title = event.summary ?? 'Unnamed Event';

    // Extract description
    final description = event.description;

    // Extract start date and time
    final DateTime eventDate;
    if (event.start?.dateTime != null) {
      eventDate = event.start!.dateTime!.toLocal();
    } else if (event.start?.date != null) {
      // All-day event, use noon as the time
      final date = event.start!.date!;
      eventDate = DateTime(date.year, date.month, date.day, 12, 0);
    } else {
      eventDate = DateTime.now(); // Fallback
    }

    // Extract end date and time
    DateTime? endDate;
    if (event.end?.dateTime != null) {
      endDate = event.end!.dateTime!.toLocal();
    } else if (event.end?.date != null) {
      // All-day event
      final date = event.end!.date!;
      endDate = DateTime(date.year, date.month, date.day, 18, 0);
    }

    // Calculate duration
    Duration? duration;
    if (endDate != null) {
      duration = endDate.difference(eventDate);
    }

    // Extract location
    final location = event.location;

    // Extract coordinates from location if available
    double? latitude;
    double? longitude;

    // Try to extract coordinates from location field if available
    if (location != null && location.isNotEmpty) {
      final latLngRegex = RegExp(r'(\d+\.\d+),\s*(\d+\.\d+)');
      final match = latLngRegex.firstMatch(location);

      if (match != null && match.groupCount >= 2) {
        try {
          latitude = double.parse(match.group(1)!);
          longitude = double.parse(match.group(2)!);
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }

    // Determine event category (defaulting to Hiking)
    String category = 'Hiking';

    // Try to determine actual category based on event content
    final allText = '${title.toLowerCase()} ${description?.toLowerCase() ?? ''}'.toLowerCase();
    if (allText.contains('backpack') || allText.contains('camping')) {
      category = 'Backpacking';
    } else if (allText.contains('trail run') || allText.contains('marathon')) {
      category = 'Trail Running';
    } else if (allText.contains('photography') || allText.contains('photo')) {
      category = 'Photography';
    } else if (allText.contains('bird') || allText.contains('wildlife')) {
      category = 'Wildlife';
    } else if (allText.contains('cleanup') || allText.contains('volunteer')) {
      category = 'Volunteer';
    }

    // For hiking events, set a default difficulty of 3 (moderate)
    int difficulty = 3;

    // Try to determine difficulty from description if possible
    if (allText.contains('beginner') || allText.contains('easy')) {
      difficulty = 1;
    } else if (allText.contains('intermediate') || allText.contains('moderate')) {
      difficulty = 3;
    } else if (allText.contains('advanced') || allText.contains('difficult') ||
        allText.contains('challenging') || allText.contains('hard')) {
      difficulty = 5;
    }

    // Extract creator info
    final createdBy = event.creator?.email;

    // Extract attendees
    List<String>? attendees;
    if (event.attendees != null && event.attendees!.isNotEmpty) {
      attendees = event.attendees!
          .map((a) => a.email)
          .where((email) => email != null)
          .cast<String>()
          .toList();
    }

    return EventData(
      id: id,
      title: title,
      description: description,
      eventDate: eventDate,
      endDate: endDate,
      duration: duration,
      location: location,
      category: category,
      difficulty: difficulty,
      latitude: latitude,
      longitude: longitude,
      attendees: attendees,
      createdBy: createdBy,
      // Set Google-specific fields
      url: event.htmlLink,
      organizer: event.organizer?.displayName,
      status: event.status,
    );
  }

  /// Get nearby events/places from Google Places API
  Future<List<EventData>> getNearbyEvents({
    required double latitude,
    required double longitude,
    required double radiusInKm,
    String? keyword,
  }) async {
    final currentApiKey = apiKey;
    if (currentApiKey.isEmpty) {
      AppLogger.error('Google API key not available for Places API search');
      return getSampleEvents();
    }

    try {
      // Build the Google Places API URL
      final url = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/nearbysearch/json',
        {
          'location': '$latitude,$longitude',
          'radius': '${(radiusInKm * 1000).round()}', // Convert to meters
          'type': 'point_of_interest',
          'keyword': keyword ?? 'hiking trail nature outdoor',
          'key': currentApiKey,
        },
      );

      // Make the API request
      final client = http.Client();
      try {
        final response = await client.get(url);

        if (response.statusCode != 200) {
          AppLogger.error('Google Places API error: ${response.statusCode} ${response.body}');
          return getSampleEvents();
        }

        // Parse the response
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['status'] != 'OK') {
          AppLogger.error('Google Places API error: ${data['status']}');
          return getSampleEvents();
        }

        final results = data['results'] as List;
        List<EventData> events = [];

        for (var place in results) {
          try {
            // Get place details for more information
            final detailsResponse = await _getPlaceDetails(place['place_id'], currentApiKey);

            if (detailsResponse == null) continue;

            final now = DateTime.now();

            // Create an event from place data
            final event = EventData(
              id: 'google_${place['place_id']}',
              title: place['name'] as String,
              description: detailsResponse['formatted_address'] as String? ??
                  place['vicinity'] as String? ??
                  'No description available',
              eventDate: now, // Current date as placeholder
              endDate: now.add(const Duration(days: 7)), // One week as placeholder
              duration: const Duration(hours: 2), // Default duration
              location: place['vicinity'] as String? ?? '',
              category: _determineCategoryFromTypes(place['types'] as List? ?? []),
              difficulty: _determineDifficultyFromRating(place['rating'] as double? ?? 3.0),
              latitude: place['geometry']['location']['lat'] as double,
              longitude: place['geometry']['location']['lng'] as double,
              // Use photos if available
              imageUrl: _getPhotoUrlFromPlace(place, detailsResponse, currentApiKey),
              // Mark as external source
              createdBy: 'Google',
            );

            events.add(event);
          } catch (e) {
            AppLogger.error('Error processing Google Places result: $e');
          }
        }

        return events;
      } finally {
        client.close();
      }
    } catch (e) {
      AppLogger.error('Error fetching Google Places: $e');
      return getSampleEvents();
    }
  }

  /// Helper method to get place details
  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId, String apiKey) async {
    try {
      final detailsUrl = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        {
          'place_id': placeId,
          'fields': 'name,formatted_address,formatted_phone_number,website,photos,opening_hours,rating,reviews',
          'key': apiKey,
        },
      );

      final client = http.Client();
      try {
        final response = await client.get(detailsUrl);

        if (response.statusCode != 200) {
          return null;
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['status'] != 'OK') {
          return null;
        }

        return data['result'] as Map<String, dynamic>;
      } finally {
        client.close();
      }
    } catch (e) {
      AppLogger.error('Error getting place details: $e');
      return null;
    }
  }

  /// Helper method to determine category from place types
  String _determineCategoryFromTypes(List types) {
    if (types.contains('campground')) return 'Camping';
    if (types.contains('park')) return 'Park';
    if (types.contains('natural_feature')) return 'Nature';
    if (types.contains('point_of_interest')) return 'Point of Interest';
    return 'Outdoor';
  }

  /// Helper method to determine difficulty from rating
  int _determineDifficultyFromRating(double rating) {
    if (rating >= 4.5) return 4; // Challenging but rewarding
    if (rating >= 4.0) return 3; // Moderate
    if (rating >= 3.0) return 2; // Easy to moderate
    return 1; // Easy
  }

  /// Helper method to get photo URL from place data
  String _getPhotoUrlFromPlace(Map<String, dynamic> place, Map<String, dynamic>? details, String apiKey) {
    // Try to get photo reference from place or details
    String? photoReference;

    if (place.containsKey('photos') && place['photos'] is List && (place['photos'] as List).isNotEmpty) {
      photoReference = place['photos'][0]['photo_reference'] as String?;
    } else if (details != null && details.containsKey('photos') &&
        details['photos'] is List && (details['photos'] as List).isNotEmpty) {
      photoReference = details['photos'][0]['photo_reference'] as String?;
    }

    if (photoReference != null) {
      // Construct the photo URL
      return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$apiKey';
    }

    // Default image if no photo available
    return 'https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/generic_business-71.png';
  }

  List<EventData> getSampleEvents() {
    // Current time for reference
    final now = DateTime.now();

    return [
      EventData(
        id: 'sample1',
        title: 'Mountain Trail Hike',
        description: 'Join us for an early morning hike on the beautiful mountain trails. Perfect for beginners!',
        eventDate: DateTime(now.year, now.month, now.day + 3, 8, 0),
        endDate: DateTime(now.year, now.month, now.day + 3, 11, 0),
        duration: Duration(hours: 3),
        location: 'Mountain View Trail, Colorado',
        category: 'Hiking',
        difficulty: 2,
        latitude: 39.7392,
        longitude: -104.9903,
        attendees: ['hiker1@example.com', 'hiker2@example.com'],
        imageUrl: 'https://images.unsplash.com/photo-1551632811-561732d1e306',
      ),

      EventData(
        id: 'sample2',
        title: 'Advanced Alpine Climb',
        description: 'Challenge yourself with this advanced alpine climbing experience. Experienced hikers only.',
        eventDate: DateTime(now.year, now.month, now.day + 7, 7, 30),
        endDate: DateTime(now.year, now.month, now.day + 7, 16, 0),
        duration: Duration(hours: 8, minutes: 30),
        location: 'Alpine Ridge, Boulder, Colorado',
        category: 'Climbing',
        difficulty: 5,
        latitude: 40.0150,
        longitude: -105.2705,
        attendees: ['climber1@example.com', 'climber2@example.com', 'climber3@example.com'],
        imageUrl: 'https://images.unsplash.com/photo-1564769662533-4f00a87b4056',
      ),

      EventData(
        id: 'sample3',
        title: 'Family Nature Walk',
        description: 'A relaxed nature walk perfect for families with children. Learn about local flora and fauna.',
        eventDate: DateTime(now.year, now.month, now.day + 5, 10, 0),
        endDate: DateTime(now.year, now.month, now.day + 5, 12, 0),
        duration: Duration(hours: 2),
        location: 'City Park Nature Trail',
        category: 'Nature Walk',
        difficulty: 1,
        latitude: 39.7508,
        longitude: -104.9490,
        attendees: ['family1@example.com', 'family2@example.com'],
        imageUrl: 'https://images.unsplash.com/photo-1541807360-7b16088fcb28',
      ),

      EventData(
        id: 'sample4',
        title: 'Overnight Backpacking Adventure',
        description: 'Experience the wilderness with an overnight backpacking trip. Camping equipment required.',
        eventDate: DateTime(now.year, now.month, now.day + 14, 9, 0),
        endDate: DateTime(now.year, now.month, now.day + 15, 16, 0),
        duration: Duration(hours: 31),
        location: 'Rocky Mountain National Park',
        category: 'Backpacking',
        difficulty: 4,
        latitude: 40.3428,
        longitude: -105.6836,
        attendees: ['backpacker1@example.com', 'backpacker2@example.com'],
        imageUrl: 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4',
      ),

      EventData(
        id: 'sample5',
        title: 'Trail Running Workshop',
        description: 'Learn proper trail running techniques and safety tips from experienced instructors.',
        eventDate: DateTime(now.year, now.month, now.day + 10, 7, 0),
        endDate: DateTime(now.year, now.month, now.day + 10, 9, 0),
        duration: Duration(hours: 2),
        location: 'Foothills Trail System',
        category: 'Trail Running',
        difficulty: 3,
        latitude: 39.6645,
        longitude: -105.2059,
        attendees: ['runner1@example.com', 'runner2@example.com'],
        imageUrl: 'https://images.unsplash.com/photo-1541252260730-0412e8e2108e',
      ),
    ];
  }

  /// Search for events by keyword
  Future<List<EventData>> searchEvents(String query) async {
    try {
      if (!_isAuthenticated) {
        final success = await signIn();
        if (!success) {
          // Return filtered sample events if authentication fails
          return getSampleEvents()
              .where((event) =>
          event.title.toLowerCase().contains(query.toLowerCase()) ||
              (event.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
              .toList();
        }
      }

      // Search Google Calendar for events matching the query
      final result = await _calendarApi!.events.list(
        'primary',
        q: query,
        maxResults: 20,
        timeMin: DateTime.now().toUtc(),
        timeMax: DateTime.now().add(Duration(days: 90)).toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      // Convert results to EventData objects
      final List<EventData> events = [];

      if (result.items != null && result.items!.isNotEmpty) {
        for (final event in result.items!) {
          events.add(_convertToEventData(event));
        }
      }

      return events;
    } catch (e) {
      AppLogger.error('Error searching Google Calendar events: $e');

      // Return filtered sample events on error
      return getSampleEvents()
          .where((event) =>
      event.title.toLowerCase().contains(query.toLowerCase()) ||
          (event.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    }
  }

  /// Sign out of Google account
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userIdKey);
      _userId = null;
      _isAuthenticated = false;
      _client?.close();
      _client = null;
      _calendarApi = null;
    } catch (e) {
      AppLogger.error('Error signing out of Google: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _client?.close();
  }
}