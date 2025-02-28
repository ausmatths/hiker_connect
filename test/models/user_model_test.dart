// test/models/user_model_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart'; // Use flutter_test instead of test

void main() {
  group('UserModel Tests', () {
    late UserModel userModel;
    late Map<String, dynamic> testData;

    setUp(() {
      // Initialize test data
      testData = {
        'uid': '123',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'photoUrl': 'https://example.com/photo.jpg',
        'bio': 'This is a bio',
        'interests': ['coding', 'reading'],
        'createdAt': Timestamp.fromDate(DateTime(2023, 1, 1)),
        'lastActive': Timestamp.fromDate(DateTime(2023, 10, 1)),
        'isEmailVerified': true,
        'following': ['user1', 'user2'],
        'followers': ['user3', 'user4'],
        'phoneNumber': '1234567890',
        'location': {
          'geoPoint': const GeoPoint(37.7749, -122.4194),
          'address': 'San Francisco, CA',
        },
        'emergencyContacts': [
          {
            'name': 'John Doe',
            'relationship': 'Friend',
            'phoneNumber': '0987654321',
          }
        ],
        'bloodType': 'O+',
        'medicalConditions': ['Asthma'],
        'medications': ['Inhaler'],
        'insuranceInfo': 'Some Insurance Info',
        'allergies': 'Pollen',
        'dateOfBirth': Timestamp.fromDate(DateTime(1990, 1, 1)),
        'gender': 'Male',
        'height': 180.0,
        'weight': 75.0,
        'preferredLanguage': 'English',
        'socialLinks': {
          'twitter': 'https://twitter.com/test',
          'linkedin': 'https://linkedin.com/in/test',
        },
      };

      // Create a UserModel instance from the test data
      userModel = UserModel.fromFirestore(
        FakeDocumentSnapshot(testData, '123'),
      );
    });

    test('toMap should return correct map', () {
      final map = userModel.toMap();

      expect(map['uid'], '123');
      expect(map['email'], 'test@example.com');
      expect(map['displayName'], 'Test User');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
      expect(map['bio'], 'This is a bio');
      expect(map['interests'], ['coding', 'reading']);
      expect(map['createdAt'], Timestamp.fromDate(DateTime(2023, 1, 1)));
      expect(map['lastActive'], Timestamp.fromDate(DateTime(2023, 10, 1)));
      expect(map['isEmailVerified'], true);
      expect(map['following'], ['user1', 'user2']);
      expect(map['followers'], ['user3', 'user4']);
      expect(map['phoneNumber'], '1234567890');
      expect(map['location'], {
        'geoPoint': const GeoPoint(37.7749, -122.4194),
        'address': 'San Francisco, CA',
      });
      expect(map['emergencyContacts'], [
        {
          'name': 'John Doe',
          'relationship': 'Friend',
          'phoneNumber': '0987654321',
        }
      ]);
      expect(map['bloodType'], 'O+');
      expect(map['medicalConditions'], ['Asthma']);
      expect(map['medications'], ['Inhaler']);
      expect(map['insuranceInfo'], 'Some Insurance Info');
      expect(map['allergies'], 'Pollen');
      expect(map['dateOfBirth'], Timestamp.fromDate(DateTime(1990, 1, 1)));
      expect(map['gender'], 'Male');
      expect(map['height'], 180.0);
      expect(map['weight'], 75.0);
      expect(map['preferredLanguage'], 'English');
      expect(map['socialLinks'], {
        'twitter': 'https://twitter.com/test',
        'linkedin': 'https://linkedin.com/in/test',
      });
    });

    test('fromFirestore should create correct UserModel instance', () {
      expect(userModel.uid, '123');
      expect(userModel.email, 'test@example.com');
      expect(userModel.displayName, 'Test User');
      expect(userModel.photoUrl, 'https://example.com/photo.jpg');
      expect(userModel.bio, 'This is a bio');
      expect(userModel.interests, ['coding', 'reading']);
      expect(userModel.createdAt, DateTime(2023, 1, 1));
      expect(userModel.lastActive, DateTime(2023, 10, 1));
      expect(userModel.isEmailVerified, true);
      expect(userModel.following, ['user1', 'user2']);
      expect(userModel.followers, ['user3', 'user4']);
      expect(userModel.phoneNumber, '1234567890');
      expect(userModel.location?.geoPoint?.latitude, 37.7749);
      expect(userModel.location?.geoPoint?.longitude, -122.4194);
      expect(userModel.location?.address, 'San Francisco, CA');
      expect(userModel.emergencyContacts?.first.name, 'John Doe');
      expect(userModel.emergencyContacts?.first.relationship, 'Friend');
      expect(userModel.emergencyContacts?.first.phoneNumber, '0987654321');
      expect(userModel.bloodType, 'O+');
      expect(userModel.medicalConditions, ['Asthma']);
      expect(userModel.medications, ['Inhaler']);
      expect(userModel.insuranceInfo, 'Some Insurance Info');
      expect(userModel.allergies, 'Pollen');
      expect(userModel.dateOfBirth, DateTime(1990, 1, 1));
      expect(userModel.gender, 'Male');
      expect(userModel.height, 180.0);
      expect(userModel.weight, 75.0);
      expect(userModel.preferredLanguage, 'English');
      expect(userModel.socialLinks?['twitter'], 'https://twitter.com/test');
      expect(userModel.socialLinks?['linkedin'], 'https://linkedin.com/in/test');
    });
  });
}

// Fake DocumentSnapshot for testing
class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final String _id;

  FakeDocumentSnapshot(this._data, this._id);

  @override
  String get id => _id;

  @override
  bool get exists => _data.isNotEmpty;

  @override
  Map<String, dynamic> data() => _data;

  // Implement required methods from the interface
  @override
  get(Object field) => _data[field.toString()];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError();

  @override
  operator [](Object field) => _data[field.toString()];
}