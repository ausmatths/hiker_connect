import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/services/firebase_auth.dart';

class MockAuthService extends Mock implements AuthService {
  UserModel? _mockUserData;
  User? _mockUser;

  MockAuthService({UserModel? mockUserData, User? mockUser})
      : _mockUserData = mockUserData,
        _mockUser = mockUser;

  void updateMockData({UserModel? userData, User? user}) {
    _mockUserData = userData;
    _mockUser = user;
  }

  @override
  Future<UserModel?> getCurrentUserData() async => _mockUserData;

  @override
  User? get currentUser => _mockUser;
}