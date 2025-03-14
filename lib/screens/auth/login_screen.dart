import 'package:flutter/material.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io' show Platform;
import 'package:hiker_connect/services/google_events_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isChecking = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _isTestingConnection = false;
  bool _showSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkLoginState();
        _testFirebaseConnection(); // Add connection test
      }
    });
  }

  // Test Firebase connection to diagnose login issues
  Future<void> _testFirebaseConnection() async {
    if (!mounted) return;

    setState(() {
      _isTestingConnection = true;
      _errorMessage = null;
    });

    try {
      developer.log('Testing Firebase connection...', name: 'LoginScreen');

      // Try to use a lightweight Firebase operation to test connection
      await FirebaseAuth.instance.fetchSignInMethodsForEmail('test@example.com');

      developer.log('✅ Firebase Auth connection successful', name: 'LoginScreen');

      // We succeeded, so no need to show a message
    } catch (e) {
      developer.log('❌ Firebase connection error: $e', name: 'LoginScreen', error: e);

      // Only show the error message if we have a specific issue
      if (e.toString().contains('network')) {
        setState(() {
          _errorMessage = 'Network error. Please check your internet connection.';
        });
      } else if (e.toString().contains('app-check')) {
        setState(() {
          _errorMessage = 'Firebase App Check configuration issue. Please contact support.';
        });
      } else if (e.toString().contains('emulator')) {
        setState(() {
          _errorMessage = 'Firebase emulator connection error. Are the emulators running?';
        });
      }
      // Don't show errors for other cases to avoid confusing the user
    } finally {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
        });
      }
    }
  }

  // Add the diagnostic test method
  Future<String> _runGoogleDiagnostics() async {
    try {
      final googleEventsService = Provider.of<GoogleEventsService>(context, listen: false);
      await googleEventsService.debugSignInProcess();

      // Get device info
      String diagnostics = '';

      // Platform info
      diagnostics += 'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n';

      // Use a simpler version info approach since we don't have package_info_plus
      diagnostics += 'Flutter: ${Theme.of(context).platform}\n\n';

      // Connection status
      final connectivity = await Connectivity().checkConnectivity();
      diagnostics += 'Network: $connectivity\n\n';

      // Auth status
      final isAuthenticated = await googleEventsService.isAuthenticated();
      diagnostics += 'Authenticated: $isAuthenticated\n';

      // Firebase check
      try {
        await FirebaseAuth.instance.fetchSignInMethodsForEmail('test@example.com');
        diagnostics += 'Firebase connection: OK\n';
      } catch (e) {
        diagnostics += 'Firebase connection: Failed ($e)\n';
      }

      return diagnostics;
    } catch (e) {
      return 'Error running diagnostics: $e';
    }
  }

  Future<void> _checkLoginState() async {
    if (!mounted) return;

    try {
      setState(() => _isChecking = true);
      final authService = context.read<AuthService>();
      final currentUser = authService.currentUser;

      if (currentUser != null && mounted) {
        developer.log('User already logged in: ${currentUser.uid}', name: 'LoginScreen');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        developer.log('No logged in user found', name: 'LoginScreen');
      }
    } catch (e) {
      developer.log(
          'Login state check error',
          name: 'LoginScreen',
          error: e
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final authService = context.read<AuthService>();

    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email first';
        _showSuccessMessage = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showSuccessMessage = false;
    });

    try {
      await authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _showSuccessMessage = true;
          _errorMessage = 'Password reset email sent. Please check your inbox.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _showSuccessMessage = false;
          _errorMessage = e is String ? e : 'Failed to send password reset email. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final authService = context.read<AuthService>();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showSuccessMessage = false;
    });

    try {
      developer.log('Starting Google sign-in flow', name: 'LoginScreen');

      // Add delay to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 500));

      final userModel = await authService.signInWithGoogle();

      if (userModel == null && mounted) {
        // User canceled sign-in
        developer.log('Google sign-in canceled by user', name: 'LoginScreen');
        setState(() => _isLoading = false);
        return;
      }

      if (userModel != null && mounted) {
        developer.log('Google sign-in successful, navigating to home', name: 'LoginScreen');
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      developer.log('Google sign-in error: $e', name: 'LoginScreen', error: e);
      if (mounted) {
        setState(() {
          if (e.toString().contains('network')) {
            _errorMessage = 'Network error. Please check your internet connection.';
          } else if (e.toString().contains('credential')) {
            _errorMessage = 'Google sign-in failed. Invalid credentials.';
          } else if (e.toString().contains('canceled')) {
            _errorMessage = 'Google sign-in was canceled.';
          } else if (e.toString().contains('popup_closed')) {
            _errorMessage = 'Google sign-in popup was closed. Please try again.';
          } else {
            _errorMessage = 'Failed to sign in with Google. Please try again.';
          }
          _showSuccessMessage = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showSuccessMessage = false;
    });

    try {
      developer.log('Attempting login with email: $email', name: 'LoginScreen');

      // Add a brief delay to ensure UI updates properly
      await Future.delayed(const Duration(milliseconds: 200));

      final userModel = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userModel != null && mounted) {
        developer.log('Login successful, navigating to home', name: 'LoginScreen');
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        developer.log('Login resulted in null user model', name: 'LoginScreen');
        setState(() {
          _errorMessage = 'Authentication failed. Please check your credentials.';
        });
      }
    } catch (e) {
      developer.log('Login error: $e', name: 'LoginScreen', error: e);

      if (mounted) {
        setState(() {
          // Specific error messages for different Firebase errors
          if (e.toString().contains('user-not-found')) {
            _errorMessage = 'No account found with this email address.';
          } else if (e.toString().contains('wrong-password')) {
            _errorMessage = 'Incorrect password. Please try again.';
          } else if (e.toString().contains('invalid-email')) {
            _errorMessage = 'Please enter a valid email address.';
          } else if (e.toString().contains('network-request-failed')) {
            _errorMessage = 'Network error. Please check your connection and try again.';
          } else if (e.toString().contains('too-many-requests')) {
            _errorMessage = 'Too many failed login attempts. Please try again later or reset your password.';
          } else if (e.toString().contains('INVALID_LOGIN_CREDENTIALS')) {
            _errorMessage = 'Invalid login credentials. Please check your email and password.';
          } else {
            // Log the full error message for debugging
            developer.log('Detailed login error: $e', name: 'LoginScreen');
            _errorMessage = 'Login failed: ${e.toString()}';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Function to manually retry connection
  void _retryConnection() {
    _testFirebaseConnection();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // App Title
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // App Logo
                Hero(
                  tag: 'app-logo',
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hiking,
                      size: 60,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // App Name
                const Text(
                  'Hiker Connect',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.email, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter your email';
                      if (!value!.contains('@')) return 'Please enter a valid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Password Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.lock, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(color: Colors.grey.shade600),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.green,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter your password' : null,
                    onFieldSubmitted: (_) => _login(),
                  ),
                ),

                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Error or Success Message
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _showSuccessMessage
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: _showSuccessMessage ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_errorMessage!.contains('Network') || _errorMessage!.contains('connection') || _errorMessage!.contains('emulator'))
                          TextButton(
                            onPressed: _retryConnection,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                            child: const Text('Retry Connection'),
                          ),
                      ],
                    ),
                  ),

                // Connection Status Indicator
                if (_isTestingConnection)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.shade300,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Testing connection...',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Colors.green.withOpacity(0.6),
                    ),
                    child: _isLoading && !_isTestingConnection
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.0,
                      ),
                    )
                        : const Text(
                      'Login',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Divider with text
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade800,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade800,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Google Sign In Button with Long Press for Diagnostics
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onLongPress: () async {
                      // Show diagnostics dialog
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.grey.shade900,
                          title: const Text(
                              'Google Sign-in Diagnostics',
                              style: TextStyle(color: Colors.white)
                          ),
                          content: FutureBuilder<String>(
                            future: _runGoogleDiagnostics(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                    ),
                                  ),
                                );
                              }
                              return SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Diagnostics Report:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: SelectableText(
                                        snapshot.data ?? 'No diagnostic data',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Copy this information when reporting issues with Google Sign-in.',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.green,
                              ),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: Container(
                        height: 24,
                        width: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      label: const Text('Sign in with Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.green.withOpacity(0.3)),
                        ),
                        elevation: 0,
                        disabledForegroundColor: Colors.grey.shade500,
                        disabledBackgroundColor: Colors.grey.shade900,
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Long press for diagnostics',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 30),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}