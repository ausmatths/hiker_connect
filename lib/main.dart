import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiker_connect/screens/trails/events_list_screen.dart';
import 'package:hiker_connect/screens/trails/trail_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:hiker_connect/models/trail_data.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/models/event_data.dart';
import 'package:hiker_connect/models/duration_adapter.dart';
import 'package:hiker_connect/services/databaseservice.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, kDebugMode, TargetPlatform;

// Import screens and services
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/screens/auth/login_screen.dart';
import 'package:hiker_connect/screens/auth/signup_screen.dart';
import 'package:hiker_connect/screens/auth/forgot_password_screen.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/screens/home_screen.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
            minimumSize: const Size.fromHeight(50),
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

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Get directory for Hive
    final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
    final hivePath = '${appDocumentDirectory.path}/hive_boxes';

    // Close any existing Hive instances
    await Hive.close();

    // For development only - clear Hive data to avoid adapter conflicts
    // THIS WILL DELETE SAVED DATA - only use in development mode
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

    // Initialize Hive with a fresh directory
    Hive.init(hivePath);

    // Debug: Check what adapters are registered
    developer.log('Registering adapters...', name: 'App Setup');

    // Register all adapters in the correct order
    Hive.registerAdapter(TrailDataAdapter());   // TypeId 0
    developer.log('TrailDataAdapter registered with typeId 0', name: 'App Setup');

    Hive.registerAdapter(UserLocationAdapter()); // TypeId 1
    developer.log('UserLocationAdapter registered with typeId 1', name: 'App Setup');

    Hive.registerAdapter(EmergencyContactAdapter()); // TypeId 2
    developer.log('EmergencyContactAdapter registered with typeId 2', name: 'App Setup');

    Hive.registerAdapter(UserModelAdapter());  // TypeId 3
    developer.log('UserModelAdapter registered with typeId 3', name: 'App Setup');

    // Register EventDataAdapter with proper error handling
    // try {
    //   Hive.registerAdapter(EventDataAdapter()); // Should be TypeId 4
    //   developer.log('EventDataAdapter registered successfully', name: 'App Setup');
    // } catch (e) {
    //   developer.log('Failed to register EventDataAdapter: $e', name: 'App Setup');
    // }

    // Register DurationAdapter for Duration serialization
    try {
      Hive.registerAdapter(DurationAdapter()); // TypeId 5
      developer.log('DurationAdapter registered with typeId 5', name: 'App Setup');
    } catch (e) {
      developer.log('Failed to register DurationAdapter: $e', name: 'App Setup');
    }

    // Initialize DatabaseService without registering adapters again
    developer.log('Initializing database service...', name: 'App Setup');
    final dbService = DatabaseService();
    await dbService.init();
    developer.log('Database service initialized successfully', name: 'App Setup');

    // Initialize Firebase
    developer.log('Initializing Firebase', name: 'App Setup');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('Firebase Core initialized', name: 'App Setup');

    // App Check initialization
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      developer.log('Initializing App Check for iOS', name: 'App Setup');
      await FirebaseAppCheck.instance.activate(
        appleProvider: AppleProvider.debug,
      );
      developer.log('App Check activated for iOS', name: 'App Setup');
    } else if (kIsWeb) {
      developer.log('Initializing App Check for Web', name: 'App Setup');
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('6LfoXNUqAAAAACnOEV3yeMG5a7du0spOyuYp2l0J'),
      );
      developer.log('App Check activated for Web', name: 'App Setup');
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      developer.log('Initializing App Check for Android', name: 'App Setup');
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
      developer.log('App Check activated for Android', name: 'App Setup');
    }

    // Load any previously saved trail data
    if (!kDebugMode) {
      try {
        // Fetch trails from Firestore to sync with local database
        await dbService.getTrailsFromFirestore();
        developer.log('Synced trails from cloud to local storage', name: 'App Setup');
      } catch (e) {
        developer.log('Error pre-loading trail data: $e', name: 'App Setup');
      }
    }

    // Set up error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log(
        'Unhandled Flutter Framework Error',
        name: 'GlobalErrorHandler',
        error: details.exception,
        stackTrace: details.stack,
      );
      FlutterError.presentError(details);
    };

    final authService = AuthService();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>(
            create: (_) => authService,
          ),
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
          // Add DatabaseService provider for easy access
          Provider<DatabaseService>.value(
            value: dbService,
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
}