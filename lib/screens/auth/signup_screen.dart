import 'package:flutter/material.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/utils/async_context_handler.dart';
import 'package:hiker_connect/utils/logger.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _obscurePassword = true;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });

        final userModel = await _authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _displayNameController.text.trim(),
        );

        AppLogger.info('Sign up successful: $userModel');
      },
      onSuccess: () {
        Navigator.of(context).pushReplacementNamed('/home');
      },
      onError: (error) {
        // Updated error logging to match the new AppLogger implementation
        AppLogger.error('Sign up error: ${error.toString()}');
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Sign Up',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Padding(
        padding: const EdgeInsets.all(24.0),
    child: Form(
    key: _formKey,
    child: SingleChildScrollView(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
    // App Logo
    Hero(
    tag: 'app-logo',
    child: Container(
    height: 100,
    width: 100,
    margin: const EdgeInsets.only(bottom: 24.0, top: 20.0),
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

    const Center(
    child: Text(
    'Hiker Connect',
    style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    ),
    ),
    ),
    const SizedBox(height: 40),

    // Display Name Field
    Container(
    decoration: BoxDecoration(
    color: Colors.grey.shade900,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade800),
    ),
    margin: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
    controller: _displayNameController,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
    labelText: 'Display Name',
    labelStyle: TextStyle(color: Colors.grey.shade400),
    prefixIcon: const Icon(Icons.person, color: Colors.green),
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    floatingLabelBehavior: FloatingLabelBehavior.never,
    hintText: 'Enter your display name',
    hintStyle: TextStyle(color: Colors.grey.shade600),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter your display name';
    }
    return null;
    },
    textInputAction: TextInputAction.next,
    ),
    ),

    // Email Field
    Container(
    decoration: BoxDecoration(
    color: Colors.grey.shade900,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade800),
    ),
    margin: const EdgeInsets.only(bottom: 16),
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
    if (value == null || value.isEmpty) {
    return 'Please enter your email';
    }
    if (!value.contains('@')) {
    return 'Please enter a valid email';
    }
    return null;
    },
    ),
    ),

    // Password Field
    Container(
    decoration: BoxDecoration(
    color: Colors.grey.shade900,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade800),
    ),
      margin: const EdgeInsets.only(bottom: 24),
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
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _signUp(),
      ),
    ),

      // Error Message
      if (_errorMessage.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _errorMessage,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),

      // Sign Up Button
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _signUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            disabledBackgroundColor: Colors.green.withOpacity(0.6),
          ),
          child: _isLoading
              ? const SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2.0,
            ),
          )
              : const Text(
            'Sign Up',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),

      const SizedBox(height: 24),

      // Login Link
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account?',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
            child: const Text(
              'Login',
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