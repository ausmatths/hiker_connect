import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiker_connect/screens/profile/edit_profile_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/services/firebase_auth.dart';

// Generate a mock class for AuthService
class MockAuthService extends Mock implements AuthService {}

class MockFirebaseUser extends Mock implements User {}

void main() {
  late MockAuthService mockAuthService;
  late MockFirebaseUser mockFirebaseUser;

  setUp(() {
    mockAuthService = MockAuthService();
    mockFirebaseUser = MockFirebaseUser();
  });

  group('ProfileScreen UI Tests', () {

    testWidgets('Displays user profile details when user data is available', (WidgetTester tester) async {
      final mockUser = UserModel(
        uid: 'navami_001',
        email: 'navamibhat0708@gmail.com',
        displayName: 'Navami Bhat',
        photoUrl: 'https://example.com/navami.jpg',
        bio: 'Software Developer | Tech Enthusiast | Problem Solver',
        interests: ['Full-Stack Development', 'AI/ML', 'UI/UX Design'],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        isEmailVerified: true,
        following: ['tech_leader_123', 'dev_friend_456'],
        followers: ['coder_789', 'mentor_101'],
        phoneNumber: '+1 206-123-4567',
        location: UserLocation(
          geoPoint: GeoPoint(47.6062, -122.3321), // Seattle, WA coordinates
          address: 'Seattle, WA, USA',
        ),
        emergencyContacts: [
          EmergencyContact(
            name: 'Shruthi',
            relationship: 'Friend',
            phoneNumber: '+1 425-987-6543',
          ),
          EmergencyContact(
            name: 'Sangeeta',
            relationship: 'Colleague',
            phoneNumber: '+1 555-789-1234',
          ),
        ],
        bloodType: 'B+',
        medicalConditions: [],
        medications: [],
        insuranceInfo: 'Star Health Insurance - Policy #987654',
        allergies: 'None',
        dateOfBirth: DateTime(1998, 5, 15),
        gender: 'Female',
        height: 162.0, // in cm
        weight: 55.0, // in kg
        preferredLanguage: 'English',
        socialLinks: {
          'LinkedIn': 'https://linkedin.com/in/navamibhat',
          'GitHub': 'https://github.com/navamibhat',
        },
      );

      when(mockAuthService.getCurrentUserData()).thenAnswer((_) async => mockUser);
      when(mockAuthService.currentUser).thenReturn(mockFirebaseUser);
      when(mockFirebaseUser.uid).thenReturn('navami_001');

      await tester.pumpWidget(MaterialApp(home: ProfileScreen()));
      await tester.pump();

      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('Displays edit profile button for current user', (WidgetTester tester) async {
      final mockUser = UserModel(
        uid: 'navami001',
        email: 'navamibhat0708@gmail.com',
        displayName: 'Navami Bhat',
        photoUrl: 'https://example.com/navami.jpg',
        bio: 'Software Developer | Hiking Enthusiast',
        interests: ['Hiking', 'Nature Photography', 'Backpacking'],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        isEmailVerified: true,
        following: ['hiking_pro_123', 'adventure_junkie_456'],
        followers: ['trail_runner_789', 'nature_lover_101'],
        phoneNumber: '+1 206-123-4567',
        location: UserLocation(
          geoPoint: GeoPoint(47.6062, -122.3321), // Seattle, WA coordinates
          address: 'Seattle, WA, USA',
        ),
        emergencyContacts: [
          EmergencyContact(
            name: 'Shruthi A',
            relationship: 'Friend',
            phoneNumber: '+1 425-987-6543',
          ),
          EmergencyContact(
            name: 'Sangeeta',
            relationship: 'Colleague',
            phoneNumber: '+1 555-789-1234',
          ),
        ],
        bloodType: 'B+',
        medicalConditions: [],
        medications: [],
        insuranceInfo: 'XYZ Health Insurance - Policy #987654',
        allergies: 'None',
        dateOfBirth: DateTime(1998, 5, 15),
        gender: 'Female',
        height: 162.0, // in cm
        weight: 55.0, // in kg
        preferredLanguage: 'English',
        socialLinks: {
          'LinkedIn': 'https://linkedin.com/in/navamibhat',
          'GitHub': 'https://github.com/navamibhat',
        },
      );

      when(mockAuthService.getCurrentUserData()).thenAnswer((_) async => mockUser);
      when(mockAuthService.currentUser).thenReturn(mockFirebaseUser);
      when(mockFirebaseUser.uid).thenReturn('navami001');

      await tester.pumpWidget(MaterialApp(
        home: ProfileScreen(),
      ));

      await tester.pump();

      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('Tapping edit profile button navigates to EditProfileScreen', (WidgetTester tester) async {
      final mockUser = UserModel(
        uid: 'navami_001',
        email: 'navami.bhat@example.com',
        displayName: 'Navami Bhat',
        photoUrl: 'https://example.com/navami.jpg',
        bio: 'Software Developer | Tech Enthusiast | Problem Solver',
        interests: ['Full-Stack Development', 'AI/ML', 'UI/UX Design'],
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        isEmailVerified: true,
        following: ['tech_leader_123', 'dev_friend_456'],
        followers: ['coder_789', 'mentor_101'],
        phoneNumber: '+1 206-123-4567',
        location: UserLocation(
          geoPoint: GeoPoint(47.6062, -122.3321), // Seattle, WA coordinates
          address: 'Seattle, WA, USA',
        ),
        emergencyContacts: [
          EmergencyContact(
            name: 'Shruthi A',
            relationship: 'Friend',
            phoneNumber: '+1 425-987-6543',
          ),
          EmergencyContact(
            name: 'Sangeeta',
            relationship: 'Colleague',
            phoneNumber: '+1 555-789-1234',
          ),
        ],
        bloodType: 'B+',
        medicalConditions: [],
        medications: [],
        insuranceInfo: 'XYZ Health Insurance - Policy #987654',
        allergies: 'None',
        dateOfBirth: DateTime(1998, 5, 15),
        gender: 'Female',
        height: 162.0, // in cm
        weight: 55.0, // in kg
        preferredLanguage: 'English',
        socialLinks: {
          'LinkedIn': 'https://linkedin.com/in/navamibhat',
          'GitHub': 'https://github.com/navamibhat',
        },
      );

      when(mockAuthService.getCurrentUserData()).thenAnswer((_) async => mockUser);
      when(mockAuthService.currentUser).thenReturn(mockFirebaseUser);
      when(mockFirebaseUser.uid).thenReturn('navami_001');

      await tester.pumpWidget(MaterialApp(
        home: ProfileScreen(),
      ));

      await tester.pump();

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });
  });
}
