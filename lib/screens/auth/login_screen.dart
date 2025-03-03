import 'package:flutter/material.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';

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
  String _errorMessage = '';
  bool _isTestingConnection = false;

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
          _errorMessage = 'Firebase connection issue: Network error. Please check your internet connection.';
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
      setState(() => _errorMessage = 'Please enter your email first');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        setState(() => _errorMessage = 'Password reset email sent. Please check your inbox.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e is String ? e : 'Failed to send password reset email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    final authService = context.read<AuthService>();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      developer.log('Starting Google sign-in flow', name: 'LoginScreen');
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
          } else {
            _errorMessage = e is String ? e : 'Failed to sign in with Google. Please try again.';
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      developer.log('Attempting email/password login', name: 'LoginScreen');

      final userModel = await authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userModel != null && mounted) {
        developer.log('Login successful, navigating to home', name: 'LoginScreen');
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        developer.log('Login resulted in null user model', name: 'LoginScreen');
        setState(() => _errorMessage = 'Failed to login. Please try again.');
      }
    } catch (e) {
      developer.log('Login error: $e', name: 'LoginScreen', error: e);
      if (mounted) {
        setState(() => _errorMessage = e is String ? e : 'An error occurred during login. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                  ),
                ),
                const SizedBox(height: 32),

                // App Logo
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hiking,
                    size: 60,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 16),

                // App Name
                const Text(
                  'Hiker Connect',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.grey.shade700),
                      prefixIcon: const Icon(Icons.email, color: Colors.deepPurple),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: 'Enter your email',
                    ),
                    keyboardType: TextInputType.emailAddress,
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.grey.shade700),
                      prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: 'Enter your password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.deepPurple,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter your password' : null,
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
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _errorMessage.contains('sent')
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _errorMessage,
                          style: TextStyle(
                            color: _errorMessage.contains('sent') ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_errorMessage.contains('Network') || _errorMessage.contains('connection') || _errorMessage.contains('emulator'))
                          TextButton(
                            onPressed: _retryConnection,
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
                              Colors.deepPurple.shade300,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Testing connection...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
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
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
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
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
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
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.deepPurple.withOpacity(0.3)),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/signup'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.deepPurple,
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