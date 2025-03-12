import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hiker_connect/utils/env_config.dart';
import 'package:hiker_connect/utils/logger.dart';

class GoogleMapsService {
  GoogleMapsService() {
    _validateApiKey();
  }

  void _validateApiKey() {
    final apiKey = EnvConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      AppLogger.error('Google Maps API key is not set in .env file');
    } else {
      AppLogger.info('Google Maps API key configured successfully');
    }
  }

  // Helper method to create markers from place results
  Set<Marker> createMarkersFromPlaces(List<dynamic> places, Function(String) onTap) {
    final markers = <Marker>{};

    for (var place in places) {
      if (place['geometry'] != null &&
          place['geometry']['location'] != null &&
          place['place_id'] != null) {
        final markerId = MarkerId(place['place_id']);
        final marker = Marker(
          markerId: markerId,
          position: LatLng(
            place['geometry']['location']['lat'],
            place['geometry']['location']['lng'],
          ),
          infoWindow: InfoWindow(
            title: place['name'],
            snippet: place['vicinity'],
          ),
          onTap: () {
            onTap(place['place_id']);
          },
        );
        markers.add(marker);
      }
    }

    return markers;
  }
}