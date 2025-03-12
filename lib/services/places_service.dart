import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hiker_connect/utils/env_config.dart';
import 'package:hiker_connect/utils/logger.dart';

class PlacesService {
  final String _apiKey;
  final String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Singleton pattern
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;

  PlacesService._internal() : _apiKey = EnvConfig.googlePlacesApiKey {
    if (_apiKey.isEmpty) {
      AppLogger.error('Google Places API key not found in .env file');
    } else {
      AppLogger.info('Places API initialized successfully');
    }
  }

  // Search for nearby places
  Future<Map<String, dynamic>> searchNearby({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? type,
    String? keyword,
  }) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/nearbysearch/json?location=$latitude,$longitude&radius=$radius'
              '${type != null ? '&type=$type' : ''}'
              '${keyword != null ? '&keyword=$keyword' : ''}'
              '&key=$_apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['status'] == 'OK' || decodedResponse['status'] == 'ZERO_RESULTS') {
          return decodedResponse;
        } else {
          AppLogger.error('Places API error: ${decodedResponse['status']} - ${decodedResponse['error_message'] ?? 'Unknown error'}');
          return {'results': []};
        }
      } else {
        AppLogger.error('HTTP error: ${response.statusCode}');
        return {'results': []};
      }
    } catch (e) {
      AppLogger.error('Error searching nearby places', e);
      return {'results': []};
    }
  }

  // Autocomplete place search
  Future<Map<String, dynamic>> getAutocompleteSuggestions(
      String input, {
        double? latitude,
        double? longitude,
        int radius = 50000,
        String? language,
      }) async {
    try {
      String url = '$_baseUrl/autocomplete/json?input=${Uri.encodeComponent(input)}';

      if (latitude != null && longitude != null) {
        url += '&location=$latitude,$longitude&radius=$radius';
      }

      if (language != null) {
        url += '&language=$language';
      }

      url += '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['status'] == 'OK' || decodedResponse['status'] == 'ZERO_RESULTS') {
          return decodedResponse;
        } else {
          AppLogger.error('Places API error: ${decodedResponse['status']} - ${decodedResponse['error_message'] ?? 'Unknown error'}');
          return {'predictions': []};
        }
      } else {
        AppLogger.error('HTTP error: ${response.statusCode}');
        return {'predictions': []};
      }
    } catch (e) {
      AppLogger.error('Error getting autocomplete suggestions', e);
      return {'predictions': []};
    }
  }

  // Get place details
  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse('$_baseUrl/details/json?place_id=$placeId&key=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['status'] == 'OK') {
          return decodedResponse;
        } else {
          AppLogger.error('Places API error: ${decodedResponse['status']} - ${decodedResponse['error_message'] ?? 'Unknown error'}');
          return {'result': null};
        }
      } else {
        AppLogger.error('HTTP error: ${response.statusCode}');
        return {'result': null};
      }
    } catch (e) {
      AppLogger.error('Error getting place details', e);
      return {'result': null};
    }
  }

  // Search specifically for hiking trails nearby
  Future<Map<String, dynamic>> searchNearbyTrails({
    required double latitude,
    required double longitude,
    int radius = 10000,
  }) async {
    // Search for parks with keyword "hiking trail"
    return await searchNearby(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: 'park',
      keyword: 'hiking trail',
    );
  }
}