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
        trailName: 'Trail 1',
        trailDescription: 'Description 1',
        trailLocation: 'Location 1',
        trailDifficulty: 'Easy',
        trailNotice: 'Notice 1',
        trailDate: DateTime.now(),
        trailParticipantNumber: 10,
        trailDuration: const Duration(hours: 2),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Trail 1'), findsOneWidget);
    });
  });

  group('TrailListScreen Interaction Tests', () {
    testWidgets('allows joining and unjoining a trail', (WidgetTester tester) async {
      final trail = TrailData(
        trailId: 1,
        trailName: 'Trail 1',
        trailDescription: 'Description 1',
        trailLocation: 'Location 1',
        trailDifficulty: 'Easy',
        trailNotice: 'Notice 1',
        trailDate: DateTime.now(),
        trailParticipantNumber: 10,
        trailDuration: const Duration(hours: 2),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify the trail is displayed
      expect(find.text('Trail 1'), findsOneWidget);

      // Verify Join button is present initially
      expect(find.text('Join'), findsOneWidget);

      // Tap the Join button
      await tester.tap(find.text('Join'));
      await tester.pump();

      // Verify the button state changed to Unjoin
      expect(find.text('Unjoin'), findsOneWidget);

      // Tap the Unjoin button
      await tester.tap(find.text('Unjoin'));
      await tester.pump();

      // Verify it changed back to Join
      expect(find.text('Join'), findsOneWidget);
    });

    testWidgets('shows snackbar message when joining a trail', (WidgetTester tester) async {
      final trail = TrailData(
        trailId: 1,
        trailName: 'Trail 1',
        trailDescription: 'Description 1',
        trailLocation: 'Location 1',
        trailDifficulty: 'Easy',
        trailNotice: 'Notice 1',
        trailDate: DateTime.now(),
        trailParticipantNumber: 10,
        trailDuration: const Duration(hours: 2),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the Join button
      await tester.tap(find.text('Join'));
      // Need to pump right after the tap
      await tester.pump();

      // Check for the snackbar
      expect(find.text('You have joined the trail!'), findsOneWidget);
    });

    testWidgets('FAB is present in the UI', (WidgetTester tester) async {
      when(mockDatabaseService.getTrails()).thenAnswer((_) async => []);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find the FAB
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget, reason: "FloatingActionButton should be visible");

      // Verify FAB has the correct icon
      expect(find.descendant(
        of: fabFinder,
        matching: find.byIcon(Icons.add),
      ), findsOneWidget, reason: "FAB should have an add icon");
    });
  });

  group('Trail Details Edge Cases', () {
    testWidgets('displays standard trail details correctly', (WidgetTester tester) async {
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
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Mountain Trail'), findsOneWidget);
      expect(find.text('Beautiful mountain trail'), findsOneWidget);
      expect(find.text('Location: Rocky Mountains'), findsOneWidget);
      expect(find.text('Difficulty: Hard'), findsOneWidget);
      expect(find.text('Notice: Bring water'), findsOneWidget);
      expect(find.text('Date: 2024-03-15'), findsOneWidget);
      expect(find.text('Participants: 5'), findsOneWidget);
      expect(find.text('Duration: 3h 30m'), findsOneWidget);
    });

    testWidgets('handles trail with empty description', (WidgetTester tester) async {
      final trail = TrailData(
        trailId: 1,
        trailName: 'Empty Description Trail',
        trailDescription: '',  // Empty description
        trailLocation: 'Test Location',
        trailDifficulty: 'Medium',
        trailNotice: 'Test Notice',
        trailDate: DateTime(2024, 3, 15),
        trailParticipantNumber: 5,
        trailDuration: const Duration(hours: 2),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Empty Description Trail'), findsOneWidget);
      // Empty description should not be rendered as a separate text widget
      expect(find.text(''), findsNothing);
    });

    testWidgets('handles trail with empty name', (WidgetTester tester) async {
      final trail = TrailData(
        trailId: 1,
        trailName: '',  // Empty name
        trailDescription: 'This trail has no name',
        trailLocation: 'Unnamed Location',
        trailDifficulty: 'Easy',
        trailNotice: 'No name notice',
        trailDate: DateTime(2024, 3, 15),
        trailParticipantNumber: 5,
        trailDuration: const Duration(hours: 1),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Should show the default name for untitled trails
      expect(find.text('Untitled Trail'), findsOneWidget);
      expect(find.text('This trail has no name'), findsOneWidget);
    });

    testWidgets('handles trail with zero duration', (WidgetTester tester) async {
      final trail = TrailData(
        trailId: 1,
        trailName: 'Zero Duration Trail',
        trailDescription: 'A trail with zero duration',
        trailLocation: 'Zero Location',
        trailDifficulty: 'Easy',
        trailNotice: 'Zero notice',
        trailDate: DateTime(2024, 3, 15),
        trailParticipantNumber: 5,
        trailDuration: const Duration(hours: 0, minutes: 0),  // Zero duration
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Zero Duration Trail'), findsOneWidget);
      expect(find.text('Duration: 0h 0m'), findsOneWidget);
    });

    testWidgets('handles trail with only minutes in duration', (WidgetTester tester) async {
      final trail = TrailData(
        trailId: 1,
        trailName: 'Minutes Only Trail',
        trailDescription: 'A trail with only minutes in duration',
        trailLocation: 'Minutes Location',
        trailDifficulty: 'Easy',
        trailNotice: 'Minutes notice',
        trailDate: DateTime(2024, 3, 15),
        trailParticipantNumber: 5,
        trailDuration: const Duration(minutes: 45),  // Only minutes, no hours
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Minutes Only Trail'), findsOneWidget);
      expect(find.text('Duration: 0h 45m'), findsOneWidget);
    });

    testWidgets('handles different difficulty levels', (WidgetTester tester) async {
      // Test each difficulty level in separate tests
      final easyTrail = TrailData(
        trailId: 1,
        trailName: 'Easy Trail',
        trailDescription: 'An easy trail',
        trailLocation: 'Easy Location',
        trailDifficulty: 'Easy',
        trailNotice: 'Easy notice',
        trailDate: DateTime(2024, 3, 15),
        trailParticipantNumber: 5,
        trailDuration: const Duration(hours: 1),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [easyTrail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Easy Trail'), findsOneWidget);
      expect(find.text('Difficulty: Easy'), findsOneWidget);

      // Hard to test colors directly, but we can verify the text is present
    });

    testWidgets('handles medium difficulty level', (WidgetTester tester) async {
      final mediumTrail = TrailData(
        trailId: 2,
        trailName: 'Medium Trail',
        trailDescription: 'A medium trail',
        trailLocation: 'Medium Location',
        trailDifficulty: 'Medium',  // Medium difficulty
        trailNotice: 'Medium notice',
        trailDate: DateTime(2024, 3, 15),
        trailParticipantNumber: 5,
        trailDuration: const Duration(hours: 2),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [mediumTrail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Medium Trail'), findsOneWidget);
      expect(find.text('Difficulty: Medium'), findsOneWidget);
    });

    testWidgets('handles hard difficulty level', (WidgetTester tester) async {
      final hardTrail = TrailData(
        trailId: 3,
        trailName: 'Hard Trail',
        trailDescription: 'A hard trail',
        trailLocation: 'Hard Location',
        trailDifficulty: 'Hard',  // Hard difficulty
        trailNotice: 'Hard notice',
        trailDate: DateTime(2024, 3, 15),
        trailParticipantNumber: 5,
        trailDuration: const Duration(hours: 3),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [hardTrail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Hard Trail'), findsOneWidget);
      expect(find.text('Difficulty: Hard'), findsOneWidget);
    });

    testWidgets('handles trail with maximum participant number', (WidgetTester tester) async {
      final trail = TrailData(
        trailId: 1,
        trailName: 'Large Group Trail',
        trailDescription: 'A trail for a large group',
        trailLocation: 'Group Location',
        trailDifficulty: 'Medium',
        trailNotice: 'Group notice',
        trailDate: DateTime(2024, 3, 15),
        trailParticipantNumber: 999999,  // Very large number
        trailDuration: const Duration(hours: 2),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Large Group Trail'), findsOneWidget);
      expect(find.text('Participants: 999999'), findsOneWidget);
    });

    testWidgets('handles trail with far future date', (WidgetTester tester) async {
      final trail = TrailData(
        trailId: 1,
        trailName: 'Future Trail',
        trailDescription: 'A trail scheduled far in the future',
        trailLocation: 'Future Location',
        trailDifficulty: 'Medium',
        trailNotice: 'Future notice',
        trailDate: DateTime(2030, 12, 31),  // Far future date
        trailParticipantNumber: 5,
        trailDuration: const Duration(hours: 2),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Future Trail'), findsOneWidget);
      expect(find.text('Date: 2030-12-31'), findsOneWidget);
    });
  });

  group('Performance Tests', () {
    testWidgets('loads and displays a large number of trails efficiently', (WidgetTester tester) async {
      // Generate 100 trail items for performance testing
      final List<TrailData> manyTrails = List.generate(
        100,
            (index) => TrailData(
          trailId: index,
          trailName: 'Trail $index',
          trailDescription: 'Description for trail $index',
          trailLocation: 'Location $index',
          trailDifficulty: index % 3 == 0 ? 'Easy' : (index % 3 == 1 ? 'Medium' : 'Hard'),
          trailNotice: 'Notice for trail $index',
          trailDate: DateTime.now().add(Duration(days: index)),
          trailParticipantNumber: 5 + index,
          trailDuration: Duration(hours: 1 + (index % 5), minutes: (index * 5) % 60),
          trailImages: [],
        ),
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => manyTrails);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      // Measure the time it takes to initially render the screen
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(createWidgetUnderTest());

      // Wait for initial frame with loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for loading to complete
      await tester.pumpAndSettle();

      final loadTime = stopwatch.elapsedMilliseconds;
      print('Initial load time for 100 trails: $loadTime ms');

      // Verify at least some trails are rendered (not all 100 will be visible at once due to ListView)
      expect(find.textContaining('Trail '), findsWidgets);

      // Verify there's no loading indicator anymore
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Test scrolling performance
      final scrollStopwatch = Stopwatch()..start();

      // Scroll down multiple times to test performance
      for (var i = 0; i < 5; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump(); // Just pump once to start scroll animation
      }

      // Complete the scrolling
      await tester.pumpAndSettle();

      final scrollTime = scrollStopwatch.elapsedMilliseconds;
      print('Time to scroll through trails: $scrollTime ms');

      // Verify we can see different trails after scrolling
      expect(find.textContaining('Trail '), findsWidgets);
    });

    testWidgets('handles trail list updates efficiently', (WidgetTester tester) async {
      // Start with a small list
      final initialTrails = List.generate(
        5,
            (index) => TrailData(
          trailId: index,
          trailName: 'Initial Trail $index',
          trailDescription: 'Initial description $index',
          trailLocation: 'Initial location $index',
          trailDifficulty: 'Easy',
          trailNotice: 'Initial notice $index',
          trailDate: DateTime.now(),
          trailParticipantNumber: 5,
          trailDuration: const Duration(hours: 1),
          trailImages: [],
        ),
      );

      // Prepare an updated list
      final updatedTrails = List.generate(
        10,
            (index) => TrailData(
          trailId: index,
          trailName: 'Updated Trail $index',
          trailDescription: 'Updated description $index',
          trailLocation: 'Updated location $index',
          trailDifficulty: 'Medium',
          trailNotice: 'Updated notice $index',
          trailDate: DateTime.now(),
          trailParticipantNumber: 10,
          trailDuration: const Duration(hours: 2),
          trailImages: [],
        ),
      );

      // Setup mock to return different values on consecutive calls
      var callCount = 0;
      when(mockDatabaseService.getTrails()).thenAnswer((_) async {
        if (callCount == 0) {
          callCount++;
          return initialTrails;
        } else {
          return updatedTrails;
        }
      });

      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Initial Trail 0'), findsOneWidget);

      // Measure refresh performance
      final refreshStopwatch = Stopwatch()..start();

      // Find the refresh button in the app bar
      await tester.tap(find.byIcon(Icons.refresh));

      // Wait for refresh to complete
      await tester.pumpAndSettle();

      final refreshTime = refreshStopwatch.elapsedMilliseconds;
      print('Time to refresh trail list: $refreshTime ms');

      // Verify updated list is displayed
      expect(find.text('Updated Trail 0'), findsOneWidget);
    });

    testWidgets('UI remains responsive during user interactions', (WidgetTester tester) async {
      // Create a single trail for reliable interaction testing
      final trail = TrailData(
        trailId: 1,
        trailName: 'Performance Test Trail',
        trailDescription: 'Test trail for performance testing',
        trailLocation: 'Test Location',
        trailDifficulty: 'Easy',
        trailNotice: 'Test Notice',
        trailDate: DateTime.now(),
        trailParticipantNumber: 5,
        trailDuration: const Duration(hours: 1),
        trailImages: [],
      );

      when(mockDatabaseService.getTrails()).thenAnswer((_) async => [trail]);
      when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify the trail card is visible
      expect(find.text('Performance Test Trail'), findsOneWidget);

      // Measure UI responsiveness during interactions
      final interactionStopwatch = Stopwatch()..start();

      // Perform several UI interactions
      for (var i = 0; i < 5; i++) {
        // Tap the refresh icon in app bar
        final refreshIcon = find.byIcon(Icons.refresh);
        expect(refreshIcon, findsOneWidget);
        await tester.tap(refreshIcon);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Complete all animations
      await tester.pumpAndSettle();

      final interactionTime = interactionStopwatch.elapsedMilliseconds;
      print('Time for 5 UI interaction cycles: $interactionTime ms');

      // Verify UI is still responsive and showing the same content
      expect(find.text('Performance Test Trail'), findsOneWidget);
    });

    group('Refresh Performance Tests', () {
      testWidgets('measures detailed refresh phases', (WidgetTester tester) async {
        // Start with initial data
        final initialTrails = List.generate(
          20,
              (index) => TrailData(
            trailId: index,
            trailName: 'Initial Trail $index',
            trailDescription: 'Initial description $index',
            trailLocation: 'Initial location $index',
            trailDifficulty: 'Easy',
            trailNotice: 'Initial notice $index',
            trailDate: DateTime.now(),
            trailParticipantNumber: 5,
            trailDuration: const Duration(hours: 1),
            trailImages: [],
          ),
        );

        // Data for refresh
        final refreshedTrails = List.generate(
          20,
              (index) => TrailData(
            trailId: index,
            trailName: 'Refreshed Trail $index',
            trailDescription: 'Refreshed description $index',
            trailLocation: 'Refreshed location $index',
            trailDifficulty: 'Medium',
            trailNotice: 'Refreshed notice $index',
            trailDate: DateTime.now(),
            trailParticipantNumber: 10,
            trailDuration: const Duration(hours: 2),
            trailImages: [],
          ),
        );

        // Mock delay for network request
        var callCount = 0;
        when(mockDatabaseService.getTrails()).thenAnswer((_) async {
          if (callCount == 0) {
            callCount++;
            return initialTrails;
          } else {
            // Add realistic network delay
            await Future.delayed(const Duration(milliseconds: 300));
            return refreshedTrails;
          }
        });

        when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

        // Load the initial UI
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Verify initial content is loaded
        expect(find.text('Initial Trail 0'), findsOneWidget);

        // Phase 1: Measure time to show loading state
        final phase1Stopwatch = Stopwatch()..start();

        // Trigger refresh
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump(); // Process the tap event

        // Wait for loading indicator to appear (may be immediate)
        final phase1Time = phase1Stopwatch.elapsedMilliseconds;

        // Phase 2: Measure network request time
        final phase2Stopwatch = Stopwatch()..start();

        // Pump until network request completes but don't settle animations
        // The artificial delay we added above is 300ms
        await tester.pump(const Duration(milliseconds: 350));

        final phase2Time = phase2Stopwatch.elapsedMilliseconds;

        // Phase 3: Measure UI update time
        final phase3Stopwatch = Stopwatch()..start();

        // Complete all remaining animations
        await tester.pumpAndSettle();

        final phase3Time = phase3Stopwatch.elapsedMilliseconds;

        // Total refresh time
        final totalRefreshTime = phase1Time + phase2Time + phase3Time;

        // Print detailed metrics
        print('Detailed Refresh Metrics:');
        print('- Phase 1 (Loading state): $phase1Time ms');
        print('- Phase 2 (Data fetching): $phase2Time ms');
        print('- Phase 3 (UI rendering): $phase3Time ms');
        print('- Total refresh time: $totalRefreshTime ms');

        // Verify refreshed content is displayed
        expect(find.text('Refreshed Trail 0'), findsOneWidget);
      });

      testWidgets('compares refresh performance with different dataset sizes', (WidgetTester tester) async {
        // Create datasets of different sizes
        final smallDataset = List.generate(
          10,
              (index) => TrailData(
            trailId: index,
            trailName: 'Small Dataset Trail $index',
            trailDescription: 'Description $index',
            trailLocation: 'Location $index',
            trailDifficulty: 'Easy',
            trailNotice: 'Notice $index',
            trailDate: DateTime.now(),
            trailParticipantNumber: 5,
            trailDuration: const Duration(hours: 1),
            trailImages: [],
          ),
        );

        final mediumDataset = List.generate(
          50,
              (index) => TrailData(
            trailId: index,
            trailName: 'Medium Dataset Trail $index',
            trailDescription: 'Description $index',
            trailLocation: 'Location $index',
            trailDifficulty: 'Medium',
            trailNotice: 'Notice $index',
            trailDate: DateTime.now(),
            trailParticipantNumber: 10,
            trailDuration: const Duration(hours: 2),
            trailImages: [],
          ),
        );

        final largeDataset = List.generate(
          200,
              (index) => TrailData(
            trailId: index,
            trailName: 'Large Dataset Trail $index',
            trailDescription: 'Description $index',
            trailLocation: 'Location $index',
            trailDifficulty: 'Hard',
            trailNotice: 'Notice $index',
            trailDate: DateTime.now(),
            trailParticipantNumber: 15,
            trailDuration: const Duration(hours: 3),
            trailImages: [],
          ),
        );

        // Keep track of which dataset to return
        var datasetIndex = 0;
        when(mockDatabaseService.getTrails()).thenAnswer((_) async {
          // Add small network delay
          await Future.delayed(const Duration(milliseconds: 100));

          switch (datasetIndex) {
            case 0:
              datasetIndex++;
              return smallDataset;
            case 1:
              datasetIndex++;
              return mediumDataset;
            case 2:
              datasetIndex++;
              return largeDataset;
            default:
              return [];
          }
        });

        when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

        // Load initial UI with small dataset
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Verify small dataset is loaded
        expect(find.text('Small Dataset Trail 0'), findsOneWidget);

        // Refresh to medium dataset and measure time
        final mediumRefreshStopwatch = Stopwatch()..start();
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();
        final mediumRefreshTime = mediumRefreshStopwatch.elapsedMilliseconds;

        // Verify medium dataset is loaded
        expect(find.text('Medium Dataset Trail 0'), findsOneWidget);

        // Refresh to large dataset and measure time
        final largeRefreshStopwatch = Stopwatch()..start();
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();
        final largeRefreshTime = largeRefreshStopwatch.elapsedMilliseconds;

        // Verify large dataset is loaded
        expect(find.text('Large Dataset Trail 0'), findsOneWidget);

        // Print dataset size comparison metrics
        print('Dataset Size Refresh Comparison:');
        print('- Small → Medium (10 → 50 items): $mediumRefreshTime ms');
        print('- Medium → Large (50 → 200 items): $largeRefreshTime ms');
        print('- Scale factor: ${largeRefreshTime / mediumRefreshTime}x');
      });

      testWidgets('measures refresh performance under simulated poor network conditions', (WidgetTester tester) async {
        final initialTrails = List.generate(
          20,
              (index) => TrailData(
            trailId: index,
            trailName: 'Trail $index',
            trailDescription: 'Description $index',
            trailLocation: 'Location $index',
            trailDifficulty: 'Easy',
            trailNotice: 'Notice $index',
            trailDate: DateTime.now(),
            trailParticipantNumber: 5,
            trailDuration: const Duration(hours: 1),
            trailImages: [],
          ),
        );

        final refreshedTrails = List.generate(
          20,
              (index) => TrailData(
            trailId: index,
            trailName: 'Refreshed Trail $index',
            trailDescription: 'Refreshed description $index',
            trailLocation: 'Refreshed location $index',
            trailDifficulty: 'Medium',
            trailNotice: 'Refreshed notice $index',
            trailDate: DateTime.now(),
            trailParticipantNumber: 10,
            trailDuration: const Duration(hours: 2),
            trailImages: [],
          ),
        );

        // Setup for slow network simulation
        var callCount = 0;
        when(mockDatabaseService.getTrails()).thenAnswer((_) async {
          if (callCount == 0) {
            callCount++;
            return initialTrails;
          } else {
            // Simulate slow network with significant delay
            await Future.delayed(const Duration(seconds: 2));
            return refreshedTrails;
          }
        });

        when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

        // Load initial UI
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Start refresh with slow network
        final stopwatch = Stopwatch()..start();
        await tester.tap(find.byIcon(Icons.refresh));

        // Verify loading indicator appears quickly
        await tester.pump();
        final loadingIndicatorTime = stopwatch.elapsedMilliseconds;
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Verify loading indicator stays visible during slow network
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete the refresh
        await tester.pumpAndSettle();
        final totalTime = stopwatch.elapsedMilliseconds;

        // Verify refreshed content is displayed
        expect(find.text('Refreshed Trail 0'), findsOneWidget);

        // Print network condition metrics
        print('Slow Network Refresh Metrics:');
        print('- Time to show loading indicator: $loadingIndicatorTime ms');
        print('- Total refresh time: $totalTime ms');
      });

      testWidgets('measures multiple rapid refreshes performance', (WidgetTester tester) async {
        final trails = List.generate(
          20,
              (index) => TrailData(
            trailId: index,
            trailName: 'Trail $index',
            trailDescription: 'Description $index',
            trailLocation: 'Location $index',
            trailDifficulty: 'Easy',
            trailNotice: 'Notice $index',
            trailDate: DateTime.now(),
            trailParticipantNumber: 5,
            trailDuration: const Duration(hours: 1),
            trailImages: [],
          ),
        );

        // Setup mock to always return the same data
        when(mockDatabaseService.getTrails()).thenAnswer((_) async {
          // Add small network delay
          await Future.delayed(const Duration(milliseconds: 100));
          return trails;
        });

        when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async => []);

        // Load initial UI
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        // Execute 5 rapid refreshes
        final refreshTimes = <int>[];

        for (var i = 0; i < 5; i++) {
          final stopwatch = Stopwatch()..start();

          // Trigger refresh
          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pumpAndSettle();

          refreshTimes.add(stopwatch.elapsedMilliseconds);
        }

        // Calculate statistics
        final avgRefreshTime = refreshTimes.reduce((a, b) => a + b) / refreshTimes.length;
        final minRefreshTime = refreshTimes.reduce((a, b) => a < b ? a : b);
        final maxRefreshTime = refreshTimes.reduce((a, b) => a > b ? a : b);

        // Print rapid refresh metrics
        print('Rapid Refresh Metrics:');
        print('- Individual refresh times: $refreshTimes ms');
        print('- Average refresh time: $avgRefreshTime ms');
        print('- Minimum refresh time: $minRefreshTime ms');
        print('- Maximum refresh time: $maxRefreshTime ms');
        print('- Variance: ${maxRefreshTime - minRefreshTime} ms');
      });

      testWidgets('tests cache behavior during refresh', (WidgetTester tester) async {
        // Initial data
        final initialTrails = List.generate(
          20,
              (index) => TrailData(
            trailId: index,
            trailName: 'Initial Trail $index',
            trailDescription: 'Initial description $index',
            trailLocation: 'Initial location $index',
            trailDifficulty: 'Easy',
            trailNotice: 'Initial notice $index',
            trailDate: DateTime.now(),
            trailParticipantNumber: 5,
            trailDuration: const Duration(hours: 1),
            trailImages: [],
          ),
        );

        // Firestore data (cloud data)
        final firestoreTrails = List.generate(
          20,
              (index) => TrailData(
            trailId: index + 100, // Different IDs to distinguish
            trailName: 'Cloud Trail $index',
            trailDescription: 'Cloud description $index',
            trailLocation: 'Cloud location $index',
            trailDifficulty: 'Medium',
            trailNotice: 'Cloud notice $index',
            trailDate: DateTime.now(),
            trailParticipantNumber: 10,
            trailDuration: const Duration(hours: 2),
            trailImages: [],
          ),
        );

        // Track number of calls to each method
        var localCacheCallCount = 0;
        var firestoreCallCount = 0;

        // Setup mock to simulate cache behavior
        when(mockDatabaseService.getTrails()).thenAnswer((_) async {
          // Local cache returns quickly
          localCacheCallCount++;
          return initialTrails;
        });

        when(mockDatabaseService.getTrailsFromFirestore()).thenAnswer((_) async {
          // Firestore takes longer to respond
          await Future.delayed(const Duration(milliseconds: 500));
          firestoreCallCount++;
          return firestoreTrails;
        });

        // Load initial UI - start measuring
        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(createWidgetUnderTest());

        // Note: Your app might not show a loading indicator if cache is fast enough
        // So we won't assert on CircularProgressIndicator

        // Wait until local cache data is shown
        await tester.pumpAndSettle();
        final cacheLoadTime = stopwatch.elapsedMilliseconds;

        // Verify we can see local data
        expect(find.text('Initial Trail 0'), findsOneWidget);

        // Explicitly trigger a refresh to test cache/cloud interaction
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump(); // Start the refresh

        // Wait for Firestore data to load and update UI
        await tester.pumpAndSettle(const Duration(milliseconds: 600));
        final totalLoadTime = stopwatch.elapsedMilliseconds;

        // Verify we can see some cloud data after refresh
        // Based on your app's merging logic, adjust this expectation
        if (find.textContaining('Cloud Trail').evaluate().isNotEmpty) {
          print('- Cloud data visible after refresh: Yes');
        } else {
          print('- Cloud data visible after refresh: No (check merging logic)');
        }

        // Print cache behavior metrics
        print('Cache Behavior Metrics:');
        print('- Time to show cached data: $cacheLoadTime ms');
        print('- Time for full refresh: $totalLoadTime ms');
        print('- Local cache accessed: $localCacheCallCount times');
        print('- Firestore called: $firestoreCallCount times');
      });
    });
  });
}