import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/screens/trails/trail_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:hiker_connect/services/databaseservice.dart';
import 'package:flutter/material.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'trail_list_screen_test.mocks.dart';

// Generate mocks
@GenerateMocks([DatabaseService])
void main() {
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Provider<DatabaseService>.value(
        value: mockDatabaseService,
        child: const TrailListScreen(),
      ),
      // Wrap all screens with the provider to fix navigation issues
      builder: (context, child) {
        return Provider<DatabaseService>.value(
          value: mockDatabaseService,
          child: child!,
        );
      },
    );
  }

  group('TrailListScreen Basic Tests', () {
    testWidgets('displays loading indicator while loading events', (WidgetTester tester) async {
      when(mockDatabaseService.getTrails()).thenAnswer((_) async => []);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());

      // Verify loading indicator appears immediately
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for loading to complete
      await tester.pumpAndSettle();
    });

    testWidgets('displays error message when loading events fails', (WidgetTester tester) async {
      when(mockDatabaseService.getTrails()).thenThrow(Exception('Failed to load'));
      when(mockDatabaseService.getTrailsFromFirestore()).thenThrow(Exception('Failed to load'));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Error loading trails: Exception: Failed to load'), findsOneWidget);
    });

    testWidgets('displays no trails message when no events are available', (WidgetTester tester) async {
      when(mockDatabaseService.getTrails()).thenAnswer((_) async => []);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for the correct empty state message in your implementation
      expect(find.text('No trails found'), findsOneWidget);
    });

    testWidgets('displays trails when events are available', (WidgetTester tester) async {
      final trail = TrailData(
          trailId: 1,
          trailName: 'Test Trail',
          trailDescription: 'Description',
          trailLocation: 'Location',
          trailDifficulty: 'Easy',
          trailNotice: 'Notice',
          trailDate: DateTime.now(),
          trailParticipantNumber: 10,
          trailDuration: const Duration(hours: 2),
          trailImages: [],
          trailType: 'Trail'
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Look for the trail name
      expect(find.text('Test Trail'), findsOneWidget);
    });
  });

  group('TrailListScreen UI Elements', () {
    testWidgets('displays difficulty filter dropdown', (WidgetTester tester) async {
      when(mockDatabaseService.getTrails()).thenAnswer((_) async => []);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for the filter dropdown
      expect(find.text('Filter by Difficulty:'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('shows floating action buttons', (WidgetTester tester) async {
      when(mockDatabaseService.getTrails()).thenAnswer((_) async => []);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for the FABs
      expect(find.byType(FloatingActionButton), findsNWidgets(2));
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.group_add), findsOneWidget);
    });

    testWidgets('displays trail details', (WidgetTester tester) async {
      final trail = TrailData(
          trailId: 1,
          trailName: 'Mountain Trail',
          trailDescription: 'Beautiful mountain trail',
          trailLocation: 'Rocky Mountains',
          trailDifficulty: 'Hard',
          trailNotice: 'Bring water',
          trailDate: DateTime(2024, 3, 15),
          trailParticipantNumber: 5,
          trailDuration: const Duration(hours: 3, minutes: 30),
          trailImages: [],
          trailType: 'Trail'
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for trail details
      expect(find.text('Mountain Trail'), findsOneWidget);
      expect(find.text('Beautiful mountain trail'), findsOneWidget);
      expect(find.text('Location: Rocky Mountains'), findsOneWidget);
      expect(find.text('Difficulty: Hard'), findsOneWidget);
    });

    testWidgets('handles empty trail name correctly', (WidgetTester tester) async {
      final trail = TrailData(
          trailId: 1,
          trailName: '',
          trailDescription: 'A trail with no name',
          trailLocation: 'Somewhere',
          trailDifficulty: 'Easy',
          trailNotice: 'Notice',
          trailDate: DateTime.now(),
          trailParticipantNumber: 5,
          trailDuration: const Duration(hours: 1),
          trailImages: [],
          trailType: 'Trail'
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for "Untitled Trail" fallback
      expect(find.text('Untitled Trail'), findsOneWidget);
    });
  });

  group('TrailListScreen Interaction', () {
    testWidgets('refresh button triggers reload', (WidgetTester tester) async {
      when(mockDatabaseService.getTrails()).thenAnswer((_) async => []);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find and tap the refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pump();

      // Verify getTrails was called twice (once on initial load, once on refresh)
      verify(mockDatabaseService.getTrails()).called(2);
    });

    testWidgets('add to calendar button is present', (WidgetTester tester) async {
      final trail = TrailData(
          trailId: 1,
          trailName: 'Test Trail',
          trailDescription: 'Description',
          trailLocation: 'Location',
          trailDifficulty: 'Easy',
          trailNotice: 'Notice',
          trailDate: DateTime.now(),
          trailParticipantNumber: 10,
          trailDuration: const Duration(hours: 2),
          trailImages: [],
          trailType: 'Trail'
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Check for Add to Calendar button
      expect(find.text('Add to Calendar'), findsOneWidget);
    });
  });
}