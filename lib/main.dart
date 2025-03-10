import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hiker_connect/screens/common/initialization_screen.dart';
import 'package:hiker_connect/screens/trails/trail_list_screen.dart';
import 'package:hiker_connect/screens/trails/events_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/models/duration_adapter.dart';
import 'package:hiker_connect/models/event_data.dart';
import 'package:hiker_connect/models/event_filter.dart';
import 'package:hiker_connect/models/photo_data.dart'; // Add this import
import 'package:hiker_connect/services/databaseservice.dart';
import 'package:hiker_connect/services/google_events_service.dart'; // New import for Google Events
import 'package:hiker_connect/providers/events_provider.dart';
import 'package:hiker_connect/providers/event_browsing_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Add for LatLng support
import 'dart:async'; // Add this for runZonedGuarded
import 'dart:developer' as developer;
import 'dart:io' show Directory, HttpClient, Platform;
import 'package:flutter/foundation.dart' show
defaultTargetPlatform,
kIsWeb,
kDebugMode,
TargetPlatform,
FlutterError,
FlutterErrorDetails,
ErrorSummary;
import 'package:flutter/src/foundation/binding.dart' show BindingBase;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_performance/firebase_performance.dart'; // Add for performance monitoring
import 'package:geolocator/geolocator.dart'; // Add for user location

// Import screens and services
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/screens/auth/login_screen.dart';
import 'package:hiker_connect/screens/auth/signup_screen.dart';
import 'package:hiker_connect/screens/auth/forgot_password_screen.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/screens/profile/profile_photo_gallery.dart'; // Add this import
import 'package:hiker_connect/screens/photos/photo_detail_screen.dart'; // Add this import
import 'package:hiker_connect/screens/home_screen.dart';
import 'package:hiker_connect/screens/events/events_browsing_screen.dart';
import 'firebase_options.dart';
import 'package:hiker_connect/screens/events/event_form_screen.dart';

// Adapter classes for Hive
class EventPreferencesAdapter extends TypeAdapter<EventPreferences> {
  @override
  final int typeId = 6;

  @override
  EventPreferences read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventPreferences(
      preferredCategories: (fields[0] as List?)?.cast<String>() ?? [],
      preferredDifficulty: fields[1] as int?,
      maxDistance: fields[2] as double?,
      notifyNewEvents: fields[3] as bool? ?? true,
      notifyEventChanges: fields[4] as bool? ?? true,
      notifyEventReminders: fields[5] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, EventPreferences obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.preferredCategories)
      ..writeByte(1)
      ..write(obj.preferredDifficulty)
      ..writeByte(2)
      ..write(obj.maxDistance)
      ..writeByte(3)
      ..write(obj.notifyNewEvents)
      ..writeByte(4)
      ..write(obj.notifyEventChanges)
      ..writeByte(5)
      ..write(obj.notifyEventReminders);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is EventPreferencesAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}

class EventFilterAdapter extends TypeAdapter<EventFilter> {
  @override
  final int typeId = 7;

  @override
  EventFilter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventFilter(
      startDate: fields[0] as DateTime?,
      endDate: fields[1] as DateTime?,
      categories: (fields[2] as List?)?.cast<String>() ?? [],
      minDifficulty: fields[3] as int?,
      maxDifficulty: fields[4] as int?,
      location: fields[5] as String?,
      maxDistance: fields[6] as double?,
      userLatitude: fields[7] as double?,
      userLongitude: fields[8] as double?,
      favoritesOnly: fields[9] as bool? ?? false,
      showOnlyFavorites: fields[10] as bool? ?? false,
      searchQuery: fields[11] as String?,
      category: fields[12] as String?,
      difficultyLevel: fields[13] as int?,
      locationQuery: fields[14] as String?,
      includePastEvents: fields[15] as bool? ?? false,
      includeCurrentEvents: fields[16] as bool? ?? true,
      includeFutureEvents: fields[17] as bool? ?? true,
      includeGoogleEvents: fields[18] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, EventFilter obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.startDate)
      ..writeByte(1)
      ..write(obj.endDate)
      ..writeByte(2)
      ..write(obj.categories)
      ..writeByte(3)
      ..write(obj.minDifficulty)
      ..writeByte(4)
      ..write(obj.maxDifficulty)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.maxDistance)
      ..writeByte(7)
      ..write(obj.userLatitude)
      ..writeByte(8)
      ..write(obj.userLongitude)
      ..writeByte(9)
      ..write(obj.favoritesOnly)
      ..writeByte(10)
      ..write(obj.showOnlyFavorites)
      ..writeByte(11)
      ..write(obj.searchQuery)
      ..writeByte(12)
      ..write(obj.category)
      ..writeByte(13)
      ..write(obj.difficultyLevel)
      ..writeByte(14)
      ..write(obj.locationQuery)
      ..writeByte(15)
      ..write(obj.includePastEvents)
      ..writeByte(16)
      ..write(obj.includeCurrentEvents)
      ..writeByte(17)
      ..write(obj.includeFutureEvents)
      ..writeByte(18)
      ..write(obj.includeGoogleEvents);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is EventFilterAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}

// PhotoData adapter for Hive
class PhotoDataAdapter extends TypeAdapter<PhotoData> {
  @override
  final int typeId = 8; // Use a unique type ID

  @override
  PhotoData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhotoData(
      id: fields[0] as String,
      url: fields[1] as String,
      thumbnailUrl: fields[2] as String?,
      uploaderId: fields[3] as String,
      trailId: fields[4] as String?,
      eventId: fields[5] as String?,
      uploadDate: fields[6] as DateTime,
      caption: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PhotoData obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.thumbnailUrl)
      ..writeByte(3)
      ..write(obj.uploaderId)
      ..writeByte(4)
      ..write(obj.trailId)
      ..writeByte(5)
      ..write(obj.eventId)
      ..writeByte(6)
      ..write(obj.uploadDate)
      ..writeByte(7)
      ..write(obj.caption);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PhotoDataAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}

/// Performance monitoring service for the app
class PerformanceMonitoringService {
  final FirebasePerformance _performance = FirebasePerformance.instance;

  PerformanceMonitoringService() {
    // Enable performance collection (can be toggled based on user preferences)
    _performance.setPerformanceCollectionEnabled(true);
  }

  // Create a trace for a specific operation
  Trace newTrace(String name) {
    return _performance.newTrace(name);
  }

  // Trace a network request
  HttpMetric newHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  // Helper method to trace event loading
  Future<T> traceEventOperation<T>({
    required String traceName,
    required Future<T> Function() operation,
    Map<String, String>? attributes,
  }) async {
    final trace = _performance.newTrace(traceName);
    await trace.start();

    try {
      final result = await operation();

      // Add success attribute
      trace.putAttribute('success', 'true');

      // Add custom attributes
      if (attributes != null) {
        attributes.forEach((key, value) {
          trace.putAttribute(key, value);
        });
      }

      return result;
    } catch (e) {
      // Record error
      trace.putAttribute('success', 'false');
      trace.putAttribute('error', e.toString().substring(0, min(100, e.toString().length)));
      rethrow;
    } finally {
      await trace.stop();
    }
  }

  int min(int a, int b) => a < b ? a : b;
}

/// Location service to get and track user location
class LocationService {
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  // Check if location services are enabled
  Future<bool> _checkLocationServices() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    return true;
  }

  // Request location permission
  Future<LocationPermission> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  // Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await _checkLocationServices();
      if (!serviceEnabled) {
        developer.log('Location services are disabled', name: 'LocationService');
        return null;
      }

      // Request permission
      LocationPermission permission = await _requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        developer.log('Location permission denied', name: 'LocationService');
        return null;
      }

      // Get position
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      developer.log(
          'Got user location: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
          name: 'LocationService'
      );

      return _currentPosition;
    } catch (e) {
      developer.log('Error getting location: $e', name: 'LocationService');
      return null;
    }
  }

  // Convert Position to LatLng for Google Maps
  LatLng? positionToLatLng(Position? position) {
    if (position == null) return null;
    return LatLng(position.latitude, position.longitude);
  }
}

/// Handles the initialization of all app dependencies
class AppInitializer {
  /// Initialize all services and return them for use in the app
  static Future<(DatabaseService, GoogleEventsService, AuthService, PerformanceMonitoringService, LocationService)> initialize() async {
    // Configure error handling
    _setupErrorHandling();

    // Initialize Firebase first
    await _initializeFirebase();

    // Initialize Firebase Performance Monitoring
    final performanceService = PerformanceMonitoringService();

    // Initialize location service
    final locationService = LocationService();

    // Try to get initial location
    await locationService.getCurrentLocation();

    // Initialize services in the correct order
    final dbService = await _initializeDatabaseService();
    final googleEventsService = await _initializeGoogleEventsService();

    // Initialize auth service after Firebase is ready
    final authService = AuthService();

    return (dbService, googleEventsService, authService, performanceService, locationService);
  }

  /// Set up global error handling
  static void _setupErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log(
        'Unhandled Flutter Framework Error',
        name: 'GlobalErrorHandler',
        error: details.exception,
        stackTrace: details.stack,
      );
      FlutterError.presentError(details);
    };
  }

  /// Initialize Firebase
  static Future<void> _initializeFirebase() async {
    try {
      developer.log('Initializing Firebase...', name: 'App Setup');

      // Initialize Firebase with the configuration
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      developer.log('Firebase initialized successfully', name: 'App Setup');

      // Initialize App Check properly - with the correct provider
      await _initializeAppCheck();

      // Configure emulators for local development
      await _configureEmulators();

    } catch (e, stackTrace) {
      developer.log(
        'Firebase initialization error',
        name: 'App Setup',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow; // Re-throw so the calling code knows initialization failed
    }
  }

  /// Initialize the database service and Hive
  static Future<DatabaseService> _initializeDatabaseService() async {
    // Hive initialization
    final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
    final hivePath = '${appDocumentDirectory.path}/hive_boxes';

    // Clear Hive data in debug mode to prevent type adapter conflicts
    if (kDebugMode) {
      try {
        final directory = Directory(hivePath);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
          developer.log('Cleared Hive data directory', name: 'App Setup');
        }
      } catch (e) {
        developer.log('Failed to clear Hive directory: $e', name: 'App Setup');
      }
    }

    // Initialize Hive
    Hive.init(hivePath);

    // Register Hive adapters
    _registerHiveAdapters();

    // Initialize Hive boxes
    await _initializeHiveBoxes();

    // Initialize Database Service
    final dbService = DatabaseService();
    await dbService.init();
    developer.log('Database service initialized successfully', name: 'App Setup');

    return dbService;
  }

  /// Initialize all required Hive boxes
  static Future<void> _initializeHiveBoxes() async {
    try {
      // Open all required Hive boxes
      await Hive.openBox('settings');
      await Hive.openBox<TrailData>('trailBox');
      await Hive.openBox<EventData>('eventBox');
      await Hive.openBox<String>('favoritesBox');

      try {
        if (!Hive.isBoxOpen('photoBox')) {
          await Hive.openBox<PhotoData>('photoBox');
          developer.log('Opened photoBox successfully', name: 'App Setup');
        }
      } catch (e) {
        developer.log('Error opening photoBox: $e', name: 'App Setup');

        try {
          // Attempt recovery
          if (await Hive.boxExists('photoBox')) {
            await Hive.deleteBoxFromDisk('photoBox');
            developer.log('Deleted problematic photoBox', name: 'App Setup');
          }
          await Hive.openBox<PhotoData>('photoBox');
          developer.log('Recreated photoBox successfully', name: 'App Setup');
        } catch (recovery) {
          developer.log('Could not recover photoBox: $recovery', name: 'App Setup');
        }
      }
    } catch (e) {
      developer.log('Error initializing Hive boxes: $e', name: 'App Setup');
    }
  }

  /// Register all Hive type adapters with proper type parameters
  static void _registerHiveAdapters() {
    _safeRegisterAdapter<TrailData>(TrailDataAdapter(), 0, 'TrailDataAdapter');
    _safeRegisterAdapter<UserLocation>(UserLocationAdapter(), 1, 'UserLocationAdapter');
    _safeRegisterAdapter<EmergencyContact>(EmergencyContactAdapter(), 2, 'EmergencyContactAdapter');
    _safeRegisterAdapter<UserModel>(UserModelAdapter(), 3, 'UserModelAdapter');
    _safeRegisterAdapter<EventData>(EventDataAdapter(), 4, 'EventDataAdapter');
    _safeRegisterAdapter<Duration>(DurationAdapter(), 5, 'DurationAdapter');
    _safeRegisterAdapter<EventPreferences>(EventPreferencesAdapter(), 6, 'EventPreferencesAdapter');
    _safeRegisterAdapter<EventFilter>(EventFilterAdapter(), 7, 'EventFilterAdapter');
    _safeRegisterAdapter<PhotoData>(PhotoDataAdapter(), 8, 'PhotoDataAdapter'); // Register PhotoData adapter
  }

  /// Register a Hive adapter with error handling and explicit type parameter
  static void _safeRegisterAdapter<T>(TypeAdapter<T> adapter, int typeId, String adapterName) {
    try {
      if (!Hive.isAdapterRegistered(typeId)) {
        Hive.registerAdapter<T>(adapter);
        developer.log('$adapterName registered with typeId $typeId', name: 'App Setup');
      } else {
        developer.log('$adapterName already registered with typeId $typeId', name: 'App Setup');
      }
    } catch (e) {
      developer.log('Failed to register $adapterName: $e', name: 'App Setup');
    }
  }

  /// Initialize the Google Events service
  static Future<GoogleEventsService> _initializeGoogleEventsService() async {
    try {
      developer.log('Initializing Google Events service...', name: 'App Setup');

      // Check for internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnectivity = connectivityResult != ConnectivityResult.none;

      if (!hasConnectivity) {
        developer.log('No internet connectivity detected. Google Events API may not work.',
            name: 'App Setup');
      }

      // Create Google Events service
      final googleEventsService = GoogleEventsService();

      // Initialize the service
      await googleEventsService.initialize();

      developer.log('Google Events service initialized successfully', name: 'App Setup');
      return googleEventsService;
    } catch (e) {
      developer.log('Error initializing Google Events service: $e', name: 'App Setup');

      // Return a new instance even if initialization failed - it will use local data
      return GoogleEventsService();
    }
  }

  /// Configure Firebase emulators for local development
  static Future<void> _configureEmulators() async {
    if (kDebugMode) {
      try {
        developer.log('Checking if we should use Firebase emulators...', name: 'App Setup');

        // Skip emulator setup if we're on a physical device
        // This helps when testing on real devices but still using debug mode
        final bool isPhysicalDevice = !Platform.isIOS || !(await isIOSSimulator());

        if (isPhysicalDevice) {
          developer.log('Running on physical device, skipping emulator setup', name: 'App Setup');
          return;
        }

        final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
        developer.log('Using emulator host: $host', name: 'App Setup');

        // Try to check if emulators are actually running before connecting
        bool emulatorsRunning = await _checkEmulatorsRunning(host);

        if (!emulatorsRunning) {
          developer.log('Firebase emulators do not appear to be running. Using production Firebase instead.',
              name: 'App Setup');
          return;
        }

        // Connect to Firestore emulator
        try {
          FirebaseFirestore.instance.useFirestoreEmulator(host, 7070);
          developer.log('Connected to Firestore emulator at $host:7070', name: 'App Setup');
        } catch (e) {
          developer.log('Failed to connect to Firestore emulator: $e', name: 'App Setup', error: e);
        }

        // Connect to Auth emulator
        try {
          await FirebaseAuth.instance.useAuthEmulator(host, 9099);
          developer.log('Connected to Auth emulator at $host:9099', name: 'App Setup');
        } catch (e) {
          developer.log('Failed to connect to Auth emulator: $e', name: 'App Setup', error: e);
        }

        // Connect to Storage emulator
        try {
          FirebaseStorage.instance.useStorageEmulator(host, 9195);
          developer.log('Connected to Storage emulator at $host:9195', name: 'App Setup');
        } catch (e) {
          developer.log('Failed to connect to Storage emulator: $e', name: 'App Setup', error: e);
        }

        // Disable App Check token refresh in emulator mode
        try {
          FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);
          developer.log('Firebase App Check token refresh disabled', name: 'App Setup');
        } catch (e) {
          developer.log('Failed to configure App Check: $e', name: 'App Setup', error: e);
        }

        developer.log('Firebase emulators configured successfully', name: 'App Setup');
      } catch (e) {
        developer.log('Error configuring emulators, falling back to production Firebase: $e',
            name: 'App Setup', error: e);
      }
    } else {
      developer.log('Running in release mode, using production Firebase', name: 'App Setup');
    }
  }

  /// Helper method to check if a device is a simulator
  static Future<bool> isIOSSimulator() async {
    if (!Platform.isIOS) return false;

    // A simple check for simulator - can be enhanced if needed
    return Platform.environment.containsKey('SIMULATOR_DEVICE_NAME') ||
        Platform.environment.containsKey('SIMULATOR_HOST_HOME');
  }

  /// Helper method to check if emulators are running
  static Future<bool> _checkEmulatorsRunning(String host) async {
    try {
      // Create a simple HTTP request to check if Auth emulator is running
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);

      final request = await client.getUrl(Uri.parse('http://$host:9099/'));
      final response = await request.close();
      await response.drain(); // Discard the response

      return response.statusCode != 404; // Any response other than 404 suggests the emulator is running
    } catch (e) {
      developer.log('Emulator check failed: $e', name: 'App Setup');
      return false; // Assume emulators are not running if we get an error
    }
  }

  /// Initialize Firebase App Check
  static Future<void> _initializeAppCheck() async {
    try {
      // Always use the debug provider in debug mode
      if (kDebugMode) {
        developer.log('Initializing App Check with debug provider', name: 'App Setup');

        // Use debug provider for all platforms in debug mode
        await FirebaseAppCheck.instance.activate(
          // Debug provider is suitable for development
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
          webProvider: ReCaptchaV3Provider('6LfoXNUqAAAAACnOEV3yeMG5a7du0spOyuYp2l0J'),
        );

        // Set a debug token that will be accepted by Firebase
        await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
        developer.log('App Check activated with debug provider', name: 'App Setup');
      } else {
        // Production mode - use the appropriate provider based on platform
        if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
          developer.log('Initializing App Check for iOS/macOS with DeviceCheck', name: 'App Setup');
          await FirebaseAppCheck.instance.activate(
            appleProvider: AppleProvider.deviceCheck,
          );
        } else if (kIsWeb) {
          developer.log('Initializing App Check for Web with reCAPTCHA', name: 'App Setup');
          await FirebaseAppCheck.instance.activate(
            webProvider: ReCaptchaV3Provider('6LfoXNUqAAAAACnOEV3yeMG5a7du0spOyuYp2l0J'),
          );
        } else if (defaultTargetPlatform == TargetPlatform.android) {
          developer.log('Initializing App Check for Android with Play Integrity', name: 'App Setup');
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.playIntegrity,
          );
        }
        developer.log('App Check activated for production', name: 'App Setup');
      }
    } catch (e) {
      developer.log('App Check initialization error: $e', name: 'App Setup', error: e);
      // Continue without App Check rather than failing the app startup
    }
  }

  /// Initialize Google Maps
  static Future<void> _initializeGoogleMaps() async {
    try {
      // Here you would initialize any Google Maps specific settings
      // such as custom styles, initial configuration, etc.
      if (Platform.isAndroid) {
        developer.log('Initializing Google Maps for Android', name: 'App Setup');
        // Platform-specific setup would go here
      }

      developer.log('Google Maps initialized successfully', name: 'App Setup');
    } catch (e) {
      developer.log('Google Maps initialization error: $e', name: 'App Setup', error: e);
      // Continue without failing app startup
    }
  }
}

/// App entry point
void main() {
  // Set this to true to make the zone error fatal during development
  // This helps catch the issue early
  BindingBase.debugZoneErrorsAreFatal = true;

  // Wrap everything in a zone to catch all uncaught errors
  runZonedGuarded(() async {
    // Ensure Flutter binding is initialized inside the same zone as runApp
    WidgetsFlutterBinding.ensureInitialized();

    // Load environment variables
    bool envLoaded = false;
    try {
      await dotenv.load(fileName: ".env");
      developer.log('Environment variables loaded successfully', name: 'App Setup');
      envLoaded = true;
    } catch (e) {
      developer.log('Failed to load .env file with standard path: $e', name: 'App Setup');

      try {
        if (Platform.isIOS || Platform.isMacOS) {
          final directory = await path_provider.getApplicationDocumentsDirectory();
          final path = '${directory.path}/.env';
          developer.log('Trying alternate path: $path', name: 'App Setup');
          await dotenv.load(fileName: path);
          developer.log('Environment variables loaded from alternate path', name: 'App Setup');
          envLoaded = true;
        }
      } catch (e2) {
        developer.log('Failed to load .env from alternate path: $e2', name: 'App Setup');
      }

      if (!envLoaded) {
        developer.log('WARNING: Continuing without environment variables', name: 'App Setup');
      }
    }

    try {
      // Initialize all app dependencies
      final (dbService, googleEventsService, authService, performanceService, locationService) =
      await AppInitializer.initialize();

      // Get user's current location as LatLng
      final userLocation = locationService.positionToLatLng(locationService.currentPosition);

      // Run app with providers
      runApp(
          MultiProvider(
              providers: [
          // Auth providers
          ChangeNotifierProvider<AuthService>.value(value: authService),
          StreamProvider<User?>.value(
          value: authService.authStateChanges,
          initialData: null,
          catchError: (context, error) {
        developer.log(
          'Auth State Stream Error',
          name: 'AuthProvider',
          error: error,
        );
        return null;
      },
    ),

    // Database provider
    Provider<DatabaseService>.value(value: dbService),

    // Google Events provider
    Provider<GoogleEventsService>.value(value: googleEventsService),

    // Performance monitoring provider
    Provider<PerformanceMonitoringService>.value(value: performanceService),

                // Location service provider
                Provider<LocationService>.value(value: locationService),

                // Events provider (using Google Events)
                ChangeNotifierProvider<EventsProvider>(
                  create: (_) => EventsProvider(googleEventsService: googleEventsService),
                  lazy: true,
                ),

                // Event browsing provider
                ChangeNotifierProvider<EventBrowsingProvider>(
                  create: (_) => EventBrowsingProvider(
                    databaseService: dbService,
                    googleEventsService: googleEventsService,
                    initialUserLocation: userLocation,
                  ),
                  lazy: false,
                ),
              ],
            child: const App(),
          ),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Fatal Error during app initialization',
        name: 'App Setup',
        error: e,
        stackTrace: stackTrace,
      );
      runApp(ErrorApp(error: e));
    }
  }, (error, stackTrace) {
    developer.log(
      'UNCAUGHT EXCEPTION in app',
      name: 'Global Error Handler',
      error: error,
      stackTrace: stackTrace,
    );
  });
}

/// Error screen shown when app initialization fails
class ErrorApp extends StatelessWidget {
  final Object error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'App Initialization Failed',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Handles conditional rendering based on authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize providers outside of build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
        final eventBrowsingProvider = Provider.of<EventBrowsingProvider>(context, listen: false);
        final performanceService = Provider.of<PerformanceMonitoringService>(context, listen: false);

        // Initialize event providers with performance tracing
        if (!eventsProvider.initialized) {
          performanceService.traceEventOperation(
            traceName: 'events_initialization',
            operation: () => eventsProvider.initialize(),
          );
        }

        // Refresh event data in the browsing provider
        performanceService.traceEventOperation(
          traceName: 'event_browsing_refresh',
          operation: () => eventBrowsingProvider.refreshEvents(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    return user == null ? const LoginScreen() : const HomeScreen();
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return InitializationScreen(
      child: MaterialApp(
        title: 'Hiker Connect',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US')],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
        ),
        themeMode: ThemeMode.dark, // Set default to dark theme for the photo gallery appearance
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/events': (context) => const EventsListScreen(),
          '/events-browse': (context) => const EventsBrowsingScreen(),
          '/trails': (context) => const TrailListScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/event-form': (context) => const EventFormScreen(),
          // Removed problematic PhotoDetailScreen route
        },
      ),
    );
  }
}