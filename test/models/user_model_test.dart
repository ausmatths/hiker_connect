import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:test/test.dart';
import 'package:hive/hive.dart';
 // Adjust the import path as needed

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
          'geoPoint': GeoPoint(37.7749, -122.4194),
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

      expect(map['uid'], equals('123'));
      expect(map['email'], equals('test@example.com'));
      expect(map['displayName'], equals('Test User'));
      expect(map['photoUrl'], equals('https://example.com/photo.jpg'));
      expect(map['bio'], equals('This is a bio'));
      expect(map['interests'], equals(['coding', 'reading']));
      expect(map['createdAt'], equals(Timestamp.fromDate(DateTime(2023, 1, 1))));
      expect(map['lastActive'], equals(Timestamp.fromDate(DateTime(2023, 10, 1))));
      expect(map['isEmailVerified'], equals(true));
      expect(map['following'], equals(['user1', 'user2']));
      expect(map['followers'], equals(['user3', 'user4']));
      expect(map['phoneNumber'], equals('1234567890'));
      expect(map['location'], equals({
        'geoPoint': GeoPoint(37.7749, -122.4194),
        'address': 'San Francisco, CA',
      }));
      expect(map['emergencyContacts'], equals([
        {
          'name': 'John Doe',
          'relationship': 'Friend',
          'phoneNumber': '0987654321',
        }
      ]));
      expect(map['bloodType'], equals('O+'));
      expect(map['medicalConditions'], equals(['Asthma']));
      expect(map['medications'], equals(['Inhaler']));
      expect(map['insuranceInfo'], equals('Some Insurance Info'));
      expect(map['allergies'], equals('Pollen'));
      expect(map['dateOfBirth'], equals(Timestamp.fromDate(DateTime(1990, 1, 1))));
      expect(map['gender'], equals('Male'));
      expect(map['height'], equals(180.0));
      expect(map['weight'], equals(75.0));
      expect(map['preferredLanguage'], equals('English'));
      expect(map['socialLinks'], equals({
        'twitter': 'https://twitter.com/test',
        'linkedin': 'https://linkedin.com/in/test',
      }));
    });

    test('fromFirestore should create correct UserModel instance', () {
      expect(userModel.uid, equals('123'));
      expect(userModel.email, equals('test@example.com'));
      expect(userModel.displayName, equals('Test User'));
      expect(userModel.photoUrl, equals('https://example.com/photo.jpg'));
      expect(userModel.bio, equals('This is a bio'));
      expect(userModel.interests, equals(['coding', 'reading']));
      expect(userModel.createdAt, equals(DateTime(2023, 1, 1)));
      expect(userModel.lastActive, equals(DateTime(2023, 10, 1)));
      expect(userModel.isEmailVerified, equals(true));
      expect(userModel.following, equals(['user1', 'user2']));
      expect(userModel.followers, equals(['user3', 'user4']));
      expect(userModel.phoneNumber, equals('1234567890'));
      expect(userModel.location?.geoPoint, equals(GeoPoint(37.7749, -122.4194)));
      expect(userModel.location?.address, equals('San Francisco, CA'));
      expect(userModel.emergencyContacts?.first.name, equals('John Doe'));
      expect(userModel.emergencyContacts?.first.relationship, equals('Friend'));
      expect(userModel.emergencyContacts?.first.phoneNumber, equals('0987654321'));
      expect(userModel.bloodType, equals('O+'));
      expect(userModel.medicalConditions, equals(['Asthma']));
      expect(userModel.medications, equals(['Inhaler']));
      expect(userModel.insuranceInfo, equals('Some Insurance Info'));
      expect(userModel.allergies, equals('Pollen'));
      expect(userModel.dateOfBirth, equals(DateTime(1990, 1, 1)));
      expect(userModel.gender, equals('Male'));
      expect(userModel.height, equals(180.0));
      expect(userModel.weight, equals(75.0));
      expect(userModel.preferredLanguage, equals('English'));
      expect(userModel.socialLinks?['twitter'], equals('https://twitter.com/test'));
      expect(userModel.socialLinks?['linkedin'], equals('https://linkedin.com/in/test'));
    });

  });
}

// Fake DocumentSnapshot for testing
class FakeDocumentSnapshot extends DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final String _id;

  FakeDocumentSnapshot(this._data, this._id);

  @override
  String get id => _id;

  @override
  bool get exists => _data.isNotEmpty;

  @override
  Map<String, dynamic> data() => _data;

  /*@override
  dynamic get(String field) => _data[field];*/

  /*@override
  dynamic operator [](String field) => _data[field];*/

  @override
  get(Object field) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  // TODO: implement metadata
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  // TODO: implement reference
  DocumentReference<Map<String, dynamic>> get reference =>
      throw UnimplementedError();

  @override
  operator [](Object field) {
    // TODO: implement []
    throw UnimplementedError();
  }
  }
// ignore: unnecessary_overrides
//SnapshotMetadata get metadata => super.metadata;

/*@override
  // ignore: unnecessary_overrides
  DocumentReference<Map<String, dynamic>> get reference => super.reference;*/
