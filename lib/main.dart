import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      developer.log(
        'Unhandled Flutter Framework Error',
        name: 'GlobalErrorHandler',
        error: details.exception,
        stackTrace: details.stack,
      );
      FlutterError.presentError(details);
    };

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

    developer.log(
      'Firebase Initialization Details',
      name: 'App Setup',
      error: {
        'Firebase Core Version': 'Initialized Successfully',
        'Platform': defaultTargetPlatform.toString(),
        'Firebase Auth Version': FirebaseAuth.instance.toString(),
        'Firestore Instance': FirebaseFirestore.instance.toString(),
        'App Check': 'Initialized Successfully',
      },
    );

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