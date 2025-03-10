import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationPicker extends StatefulWidget {
  final gmaps.LatLng? initialLocation;
  final double initialRadius;

  const LocationPicker({
    Key? key,
    this.initialLocation,
    this.initialRadius = 10.0,
  }) : super(key: key);

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  late double _radius;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Convert from Google Maps LatLng to latlong2 LatLng if provided
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
    } else {
      // Default to a central location if none provided
      _selectedLocation = LatLng(40.7128, -74.0060); // NYC
    }

    _radius = widget.initialRadius;

    // Get user location if no initial location provided
    if (widget.initialLocation == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Location permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Location permission permanently denied';
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _mapController.move(_selectedLocation, 13.0);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to get current location';
        });
      }
    }
  }

  void _selectLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          TextButton(
            onPressed: () {
              // Convert from latlong2 LatLng to Google Maps LatLng when returning
              final gmapsLatLng = gmaps.LatLng(
                _selectedLocation.latitude,
                _selectedLocation.longitude,
              );

              Navigator.pop(
                context,
                {
                  'location': gmapsLatLng,
                  'radius': _radius,
                },
              );
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _selectedLocation,
                    zoom: 13.0,
                    onTap: (tapPosition, point) {
                      _selectLocation(point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _selectedLocation,
                          radius: _radius * 1000, // Convert to meters
                          color: Colors.blue.withOpacity(0.2),
                          borderColor: Colors.blue,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 40,
                          height: 40,
                          builder: (ctx) => const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Loading indicator
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),

                // Error message
                if (_errorMessage != null)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Radius: ${_radius.toStringAsFixed(1)} km',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Slider(
                  value: _radius,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  label: '${_radius.toStringAsFixed(1)} km',
                  onChanged: (value) {
                    setState(() {
                      _radius = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}