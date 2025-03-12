import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class EnvConfig {
  // Private constructor to prevent instantiation
  EnvConfig._();

  // Flag to track if environment is loaded
  static bool _isLoaded = false;

  // Google Maps and Places API keys
  static String get googleMapsApiKey =>
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  static String get googlePlacesApiKey =>
      dotenv.env['GOOGLE_PLACES_API_KEY'] ?? googleMapsApiKey;

  // Firebase Configuration
  static String get firebaseApiKey =>
      dotenv.env['FIREBASE_API_KEY'] ?? '';

  static String get firebaseAppId =>
      dotenv.env['FIREBASE_APP_ID'] ?? '';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';

  static String get firebaseAuthDomain =>
      dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';

  static String get firebaseMeasurementId =>
      dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '';

  static String get firebaseIosClientId =>
      dotenv.env['FIREBASE_IOS_CLIENT_ID'] ?? '';

  static String get firebaseIosBundleId =>
      dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? '';

  // App environment
  static String get appEnvironment =>
      dotenv.env['APP_ENV'] ?? 'development';

  // Environment loading
  static Future<bool> load() async {
    if (_isLoaded) return true;

    try {
      // Try standard path first
      await dotenv.load(fileName: ".env");
      developer.log('Environment variables loaded successfully', name: 'EnvConfig');
      _isLoaded = true;
      return true;
    } catch (e) {
      developer.log('Failed to load .env file with standard path: $e', name: 'EnvConfig');

      // Try alternate paths for different platforms
      try {
        if (Platform.isIOS || Platform.isMacOS) {
          final directory = await path_provider.getApplicationDocumentsDirectory();
          final path = '${directory.path}/.env';
          developer.log('Trying alternate path: $path', name: 'EnvConfig');
          await dotenv.load(fileName: path);
          developer.log('Environment variables loaded from alternate path', name: 'EnvConfig');
          _isLoaded = true;
          return true;
        }
      } catch (e2) {
        developer.log('Failed to load .env from alternate path: $e2', name: 'EnvConfig');
      }

      // Create fallback values for development environment
      if (kDebugMode) {
        developer.log('WARNING: Using fallback environment values for development', name: 'EnvConfig');
        return false;
      }

      developer.log('ERROR: Failed to load environment variables', name: 'EnvConfig');
      return false;
    }
  }

  // Helper to check if a specific key exists and is not empty
  static bool hasKey(String key) {
    final value = dotenv.env[key];
    return value != null && value.isNotEmpty;
  }

  // Helper to validate all required keys are present
  static bool validateRequiredKeys() {
    const requiredKeys = [
      'GOOGLE_MAPS_API_KEY',
      'FIREBASE_API_KEY',
      'FIREBASE_APP_ID',
      'FIREBASE_PROJECT_ID',
      'FIREBASE_MESSAGING_SENDER_ID',
      'FIREBASE_STORAGE_BUCKET',
    ];

    for (final key in requiredKeys) {
      if (!hasKey(key)) {
        developer.log('Missing required environment variable: $key', name: 'EnvConfig');
        return false;
      }
    }

    return true;
  }
}