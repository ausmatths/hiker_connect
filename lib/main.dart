import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'package:hiker_connect/services/databaseservice.dart';
import 'package:hiker_connect/services/eventbrite_service.dart';
import 'package:hiker_connect/providers/events_provider.dart';
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
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Import screens and services
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/screens/auth/login_screen.dart';
import 'package:hiker_connect/screens/auth/signup_screen.dart';
import 'package:hiker_connect/screens/auth/forgot_password_screen.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/screens/home_screen.dart';
import 'firebase_options.dart';

/// Handles the initialization of all app dependencies
class AppInitializer {
  /// Initialize all services and return them for use in the app
  static Future<(DatabaseService, EventBriteService, AuthService)> initialize() async {
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Configure error handling
    _setupErrorHandling();

    // Initialize Firebase first
    await _initializeFirebase();

    // Initialize services in the correct order
    final dbService = await _initializeDatabaseService();
    final eventbriteService = await _initializeEventBriteService();

    // Initialize auth service after Firebase is ready
    final authService = AuthService();

    return (dbService, eventbriteService, authService);
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

    // Initialize Database Service
    final dbService = DatabaseService();
    await dbService.init();
    developer.log('Database service initialized successfully', name: 'App Setup');

    return dbService;
  }

  /// Register all Hive type adapters with proper type parameters
  static void _registerHiveAdapters() {
    _safeRegisterAdapter<TrailData>(TrailDataAdapter(), 0, 'TrailDataAdapter');
    _safeRegisterAdapter<UserLocation>(UserLocationAdapter(), 1, 'UserLocationAdapter');
    _safeRegisterAdapter<EmergencyContact>(EmergencyContactAdapter(), 2, 'EmergencyContactAdapter');
    _safeRegisterAdapter<UserModel>(UserModelAdapter(), 3, 'UserModelAdapter');
    _safeRegisterAdapter<EventData>(EventDataAdapter(), 4, 'EventDataAdapter');
    _safeRegisterAdapter<Duration>(DurationAdapter(), 5, 'DurationAdapter');
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

  /// Initialize the EventBrite service with enhanced error handling and connectivity check
  static Future<EventBriteService> _initializeEventBriteService() async {
    try {
      developer.log('Initializing EventBrite service...', name: 'App Setup');

      // Check for internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnectivity = connectivityResult != ConnectivityResult.none;

      if (!hasConnectivity) {
        developer.log('No internet connectivity detected. EventBrite API may not work.',
            name: 'App Setup');
      }

      // Get tokens from .env with fallback - not logging token values for security
      final privateToken = dotenv.env['EVENTBRITE_PRIVATE_TOKEN'];
      final clientSecret = dotenv.env['EVENTBRITE_CLIENT_SECRET'];

      developer.log(
          'EventBrite tokens from ${dotenv.isInitialized ? '.env file' : 'defaults'} will be stored securely',
          name: 'App Setup'
      );

      // Create EventBrite service with secure token handling
      final eventbriteService = EventBriteService(
          privateToken: privateToken,
          clientSecret: clientSecret
      );

      developer.log('EventBrite service initialized securely', name: 'App Setup');

      // Validate tokens if we have connectivity, but don't expose token values
      if (hasConnectivity) {
        try {
          final isValid = await eventbriteService.validateToken();
          developer.log('EventBrite token validation result: ${isValid ? 'Valid' : 'Invalid'}',
              name: 'App Setup');

          if (!isValid) {
            developer.log('WARNING: EventBrite token appears to be invalid. Event fetching may fail.',
                name: 'App Setup');
          }
        } catch (e) {
          developer.log('Failed to validate EventBrite token: $e', name: 'App Setup');
        }
      }

      return eventbriteService;
    } catch (e) {
      developer.log('Error initializing EventBrite service: $e', name: 'App Setup');

      // Return a service without hardcoded tokens - it will use secure storage or fallback to samples
      return EventBriteService();
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
}

/// App entry point
void main() async {
  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before running the app
  bool envLoaded = false;
  try {
    // Try the standard path first
    await dotenv.load(fileName: ".env");
    developer.log('Environment variables loaded successfully', name: 'App Setup');
    envLoaded = true;
  } catch (e) {
    developer.log('Failed to load .env file with standard path: $e', name: 'App Setup');

    // Try with an absolute path as a fallback
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

    // If all loading attempts fail, log a warning but continue
    if (!envLoaded) {
      developer.log('WARNING: Continuing without environment variables', name: 'App Setup');
    }
  }

  // Wrap everything in a zone to catch all uncaught errors
  runZonedGuarded(() async {
    try {
      // Initialize all app dependencies
      final (dbService, eventbriteService, authService) = await AppInitializer.initialize();

      // Run app with providers
      runApp(
        MultiProvider(
          providers: [
            // Auth service and state
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

            // Services
            Provider<DatabaseService>.value(value: dbService),
            Provider<EventBriteService>.value(value: eventbriteService),

            // State providers
            ChangeNotifierProvider<EventBriteProvider>(
              create: (_) => EventBriteProvider(eventbriteService: eventbriteService),
              lazy: false, // Initialize immediately to start pre-fetching events
            ),
          ],
          child: const App(),
        ),
      );
    } catch (e, stackTrace) {
      // Fallback to error app if initialization fails
      developer.log(
        'Fatal Error during app initialization',
        name: 'App Setup',
        error: e,
        stackTrace: stackTrace,
      );
      runApp(ErrorApp(error: e));
    }
  }, (error, stackTrace) {
    // Global error handler for uncaught asynchronous errors
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
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    return user == null ? const LoginScreen() : const HomeScreen();
  }
}

/// Main application widget
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            // Changed from Size.fromHeight to fixed height without infinite width
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/events': (context) => const EventsListScreen(),
        '/trails': (context) => const TrailListScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}