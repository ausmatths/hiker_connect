import 'package:flutter/material.dart';
import 'package:hiker_connect/services/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isChecking = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    try {
      if (!mounted) return;
      setState(() {
        _isChecking = true;
      });
      // Check login state logic here
      final currentUser = _authService.currentUser;
      if (currentUser != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      await _authService.resetPassword(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent. Please check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send password reset email. Please try again.';
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

  Future<void> _signInWithGoogle() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final userModel = await _authService.signInWithGoogle();

      if (userModel != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to sign in with Google. Please try again.';
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

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      try {
        print('Attempting to login with email: ${_emailController.text}');
        final userModel = await _authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (userModel != null && mounted) {
          print('Login successful. Navigating to home screen.');
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (mounted) {
          setState(() {
            _errorMessage = 'Failed to login. Please try again.';
          });
        }
      } catch (e) {
        print('Login error: $e');
        if (mounted) {
          setState(() {
            if (e is String) {
              _errorMessage = e;
            } else {
              _errorMessage = 'An error occurred during login. Please try again.';
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Icon(
                  Icons.hiking,
                  size: 80,
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hiker Connect',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        }
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Login'),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/signup');
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}