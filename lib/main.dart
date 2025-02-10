import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hiker_connect/services/auth_service_interface.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

// Import screens and services
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/screens/auth/login_screen.dart';
import 'package:hiker_connect/screens/auth/signup_screen.dart';
import 'package:hiker_connect/screens/auth/forgot_password_screen.dart';
import 'package:hiker_connect/screens/profile/profile_screen.dart';
import 'package:hiker_connect/screens/home_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handling for Flutter framework
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log(
      'Unhandled Flutter Framework Error',
      name: 'GlobalErrorHandler',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };

  // Initialize Firebase with comprehensive error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Detailed Firebase initialization logging
    developer.log(
      'Firebase Initialization Details',
      name: 'App Setup',
      error: {
        'Firebase Core Version': 'Initialized Successfully',
        'Platform': defaultTargetPlatform.toString(),
        'Firebase Auth Version': FirebaseAuth.instance.toString(),
        'Firestore Instance': FirebaseFirestore.instance.toString(),
      },
    );
  } catch (e, stackTrace) {
    developer.log(
      'Firebase Initialization Failed',
      name: 'Firebase Setup',
      error: e,
      stackTrace: stackTrace,
    );

    // Optional: Handle initialization failure
    runApp(ErrorApp(error: e));
    return;
  }

  // Create auth service
  final authService = AuthService();

  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        Provider<IAuthService>(create: (_) => authService),
        Provider<AuthService>(create: (_) => authService),
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
      ],
      child: const MyApp(),
    ),
  );
}

// Optional error display widget
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
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'App Initialization Failed',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hiker Connect',
      debugShowCheckedModeBanner: false,

      // Localization support
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],

      // App theme configuration
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

      // Initial route and route generation
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
      home: const AuthWrapper(),
    );
  }

  // Centralized route generation
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case '/signup':
        return MaterialPageRoute(
          builder: (_) => const SignUpScreen(),
          settings: settings,
        );
      case '/home':
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const AuthWrapper(),
          settings: settings,
        );
    }
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Consume the authentication state
    final user = context.watch<User?>();

    // Simplified navigation logic
    if (user == null) {
      return const LoginScreen();
    } else {
      return const HomeScreen();
    }
  }
}