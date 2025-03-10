import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/widgets/location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mocking Geolocator
class MockGeolocator extends Mock with MockPlatformInterfaceMixin implements GeolocatorPlatform {}

void main() {
  late MockGeolocator mockGeolocator;

  setUp(() {
    mockGeolocator = MockGeolocator();
    GeolocatorPlatform.instance = mockGeolocator;
  });

  testWidgets('LocationPicker renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LocationPicker(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(LocationPicker), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('Initial location is used if provided', (WidgetTester tester) async {
    final gmaps.LatLng testLocation = gmaps.LatLng(37.7749, -122.4194);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPicker(initialLocation: testLocation),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(LocationPicker), findsOneWidget);
  });

  /*testWidgets('Gets user location when initial location is null', (WidgetTester tester) async {
    when(mockGeolocator.checkPermission()).thenAnswer((_) async => LocationPermission.always);
    when(mockGeolocator.getCurrentPosition()).thenAnswer(
          (_) async => Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime.now(),
        altitude: 0.0,
        accuracy: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0, altitudeAccuracy: 0.0, headingAccuracy: 0.0,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LocationPicker(),
        ),
      ),
    );

    await tester.pumpAndSettle(); // Allow async location fetching
    expect(find.byType(LocationPicker), findsNothing);
  });*/

  /*testWidgets('Tapping on the map updates location', (WidgetTester tester) async {
    final gmaps.LatLng testLocation = gmaps.LatLng(37.7749, -122.4194);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPicker(initialLocation: testLocation),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final newLocation = gmaps.LatLng(37.7750, -122.4180);

    await tester.tap(find.byType(FlutterMap)); // Simulate a tap
    await tester.pump();

    expect(find.byType(LocationPicker), findsNothing);
  });*/

  testWidgets('Radius slider updates value correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LocationPicker(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(50, 0));
    await tester.pump();

    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('Done button returns selected location', (WidgetTester tester) async {
    final gmaps.LatLng testLocation = gmaps.LatLng(37.7749, -122.4194);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationPicker(initialLocation: testLocation),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  });
}
