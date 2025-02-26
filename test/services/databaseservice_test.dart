import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/services/databaseservice.dart';
import 'package:mockito/mockito.dart';

// Import the generated mocks file
import 'databaseservice_test.mocks.dart';

void main() {
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    // Initialize mocks from the generated file
    mockDatabaseService = MockDatabaseService();
  });

  group('Database Service Tests', () {
    test('insertTrails adds a trail to the database', () async {
      final trail = TrailData(
        trailId: 1,
        trailName: 'Test Trail',
        trailDescription: 'Test Description',
        trailLocation: 'Test Location',
        trailDifficulty: 'Easy',
        trailNotice: 'Test Notice',
        trailDate: DateTime.now(),
        trailParticipantNumber: 5,
        trailDuration: const Duration(hours: 1),
        trailImages: [],
      );

      // Set up mock behavior
      when(mockDatabaseService.insertTrails(any)).thenAnswer((_) async => 0);

      // Call the method
      final result = await mockDatabaseService.insertTrails(trail);

      // Verify
      expect(result, 0);
      verify(mockDatabaseService.insertTrails(trail)).called(1);
    });

    test('getTrails returns trails from the database', () async {
      final trailsList = [
        TrailData(
          trailId: 1,
          trailName: 'Trail 1',
          trailDescription: 'Description 1',
          trailLocation: 'Location 1',
          trailDifficulty: 'Easy',
          trailNotice: 'Notice 1',
          trailDate: DateTime.now(),
          trailParticipantNumber: 5,
          trailDuration: const Duration(hours: 1),
          trailImages: [],
        ),
        TrailData(
          trailId: 2,
          trailName: 'Trail 2',
          trailDescription: 'Description 2',
          trailLocation: 'Location 2',
          trailDifficulty: 'Medium',
          trailNotice: 'Notice 2',
          trailDate: DateTime.now(),
          trailParticipantNumber: 10,
          trailDuration: const Duration(hours: 2),
          trailImages: [],
        ),
      ];

      // Set up mocks
      when(mockDatabaseService.getTrails()).thenAnswer((_) async => trailsList);

      // Call method
      final result = await mockDatabaseService.getTrails();

      // Verify
      expect(result, trailsList);
      expect(result.length, 2);
      verify(mockDatabaseService.getTrails()).called(1);
    });

    test('updateTrail updates an existing trail', () async {
      final updatedTrail = TrailData(
        trailId: 1,
        trailName: 'Updated Trail',
        trailDescription: 'Updated Description',
        trailLocation: 'Updated Location',
        trailDifficulty: 'Medium',
        trailNotice: 'Updated Notice',
        trailDate: DateTime.now(),
        trailParticipantNumber: 10,
        trailDuration: const Duration(hours: 2),
        trailImages: [],
      );

      // Set up basic mock behavior
      when(mockDatabaseService.updateTrail(any, any)).thenAnswer((_) async => {});

      // Call method
      await mockDatabaseService.updateTrail('Test Trail', updatedTrail);

      // Verify
      verify(mockDatabaseService.updateTrail('Test Trail', updatedTrail)).called(1);
    });

    test('getTrailByName returns a trail if it exists', () async {
      final trail = TrailData(
        trailId: 1,
        trailName: 'Test Trail',
        trailDescription: 'Test Description',
        trailLocation: 'Test Location',
        trailDifficulty: 'Easy',
        trailNotice: 'Test Notice',
        trailDate: DateTime.now(),
        trailParticipantNumber: 5,
        trailDuration: const Duration(hours: 1),
        trailImages: [],
      );

      // Set up mocks
      when(mockDatabaseService.getTrailByName(any)).thenAnswer((_) async => trail);

      // Call method
      final result = await mockDatabaseService.getTrailByName('Test Trail');

      // Verify
      expect(result, trail);
      expect(result?.trailName, 'Test Trail');
      verify(mockDatabaseService.getTrailByName('Test Trail')).called(1);
    });

    test('getTrailByName returns null for non-existent trail', () async {
      // Set up mocks
      when(mockDatabaseService.getTrailByName(any)).thenAnswer((_) async => null);

      // Call method
      final result = await mockDatabaseService.getTrailByName('Non-existent Trail');

      // Verify
      expect(result, isNull);
      verify(mockDatabaseService.getTrailByName('Non-existent Trail')).called(1);
    });

    test('getTrailsFromFirestore returns trails from Firestore', () async {
      final trailsList = [
        TrailData(
          trailId: 1,
          trailName: 'Firestore Trail 1',
          trailDescription: 'Firestore Description 1',
          trailLocation: 'Firestore Location 1',
          trailDifficulty: 'Easy',
          trailNotice: 'Firestore Notice 1',
          trailDate: DateTime.now(),
          trailParticipantNumber: 5,
          trailDuration: const Duration(hours: 1),
          trailImages: [],
        ),
      ];

      // Set up mocks
      when(mockDatabaseService.getTrailsFromFirestore())
          .thenAnswer((_) async => trailsList);

      // Call method
      final result = await mockDatabaseService.getTrailsFromFirestore();

      // Verify
      expect(result, trailsList);
      expect(result.length, 1);
      verify(mockDatabaseService.getTrailsFromFirestore()).called(1);
    });

    // Add this test group to your existing test file

    group('Error Handling Tests', () {
      test('debug a specific error - insertTrails handles exceptions correctly', () async {
        final trail = TrailData(
          trailId: 1,
          trailName: 'Test Trail',
          trailDescription: 'Test Description',
          trailLocation: 'Test Location',
          trailDifficulty: 'Easy',
          trailNotice: 'Test Notice',
          trailDate: DateTime.now(),
          trailParticipantNumber: 5,
          trailDuration: const Duration(hours: 1),
          trailImages: [],
        );

        // Mock throwing an exception
        final testException = Exception('Database connection failed');
        when(mockDatabaseService.insertTrails(any)).thenThrow(testException);

        // Verify the exception is properly propagated
        expect(
              () => mockDatabaseService.insertTrails(trail),
          throwsA(equals(testException)),
        );
      });

      test('debug a specific error - getTrails handles exceptions correctly', () async {
        // Mock throwing an exception
        final testException = Exception('Network timeout');
        when(mockDatabaseService.getTrails()).thenThrow(testException);

        // Verify the exception is properly propagated
        expect(
              () => mockDatabaseService.getTrails(),
          throwsA(equals(testException)),
        );
      });

      test('debug a specific error - updateTrail handles exceptions correctly', () async {
        final trail = TrailData(
          trailId: 1,
          trailName: 'Error Trail',
          trailDescription: 'Error Description',
          trailLocation: 'Error Location',
          trailDifficulty: 'Hard',
          trailNotice: 'Error Notice',
          trailDate: DateTime.now(),
          trailParticipantNumber: 5,
          trailDuration: const Duration(hours: 1),
          trailImages: [],
        );

        // Mock throwing an exception
        final testException = Exception('Permission denied');
        when(mockDatabaseService.updateTrail(any, any)).thenThrow(testException);

        // Verify the exception is properly propagated
        expect(
              () => mockDatabaseService.updateTrail('Any Trail', trail),
          throwsA(equals(testException)),
        );
      });

      test('debug a specific error - getTrailsFromFirestore handles network failures', () async {
        // Mock throwing a specific network exception
        final networkException = Exception('Network unavailable');
        when(mockDatabaseService.getTrailsFromFirestore()).thenThrow(networkException);

        // Verify the exception is properly propagated
        expect(
              () => mockDatabaseService.getTrailsFromFirestore(),
          throwsA(equals(networkException)),
        );
      });

      test('debug a specific error - handles empty data correctly', () async {
        final emptyDataTrail = TrailData(
          trailId: 999,
          trailName: '',  // Empty name
          trailDescription: '',  // Empty description
          trailLocation: '',  // Empty location
          trailDifficulty: '',  // Empty difficulty
          trailNotice: '',  // Empty notice
          trailDate: DateTime.now(),
          trailParticipantNumber: 0,  // Zero participants
          trailDuration: const Duration(seconds: 0),  // Zero duration
          trailImages: [],  // Empty images array instead of null
        );

        // Set up the mock to return a valid key (even with invalid data)
        when(mockDatabaseService.insertTrails(any)).thenAnswer((_) async => 42);

        // Call the method with the empty data
        final result = await mockDatabaseService.insertTrails(emptyDataTrail);

        // Verify it still works with empty data
        expect(result, 42);
        verify(mockDatabaseService.insertTrails(emptyDataTrail)).called(1);
      });

      test('debug a specific error - handles authentication failures', () async {
        // Mock an authentication error
        final authException = Exception('User not authenticated');
        when(mockDatabaseService.syncTrailToFirestore(any)).thenThrow(authException);

        final trail = TrailData(
          trailId: 1,
          trailName: 'Auth Test Trail',
          trailDescription: 'Auth Description',
          trailLocation: 'Auth Location',
          trailDifficulty: 'Easy',
          trailNotice: 'Auth Notice',
          trailDate: DateTime.now(),
          trailParticipantNumber: 5,
          trailDuration: const Duration(hours: 1),
          trailImages: [],
        );

        // Verify the authentication error is handled correctly
        expect(
              () => mockDatabaseService.syncTrailToFirestore(trail),
          throwsA(equals(authException)),
        );
      });
    });
  });
}