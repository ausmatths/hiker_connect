import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hiker_connect/services/firebase_auth.dart';

@GenerateMocks([
  AuthService,
  User,
  FirebaseApp,
])
void main() {}