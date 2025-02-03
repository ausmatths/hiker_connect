import 'package:flutter/material.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/screens/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user's profile

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  late Future<UserModel?> _userFuture;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (widget.userId != null) {
      _userFuture = _authService.getUserData(widget.userId!);
      _isCurrentUser = widget.userId == _authService.currentUser?.uid;
    } else {
      _userFuture = _authService.getCurrentUserData();
      _isCurrentUser = true;
    }
  }

  Future<void> _editProfile(UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: user),
      ),
    );

    if (result == true) {
      setState(() {
        _loadUserData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isCurrentUser)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Navigate to settings screen
              },
            ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(
              child: Text('User not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                          user.displayName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                        )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (_isCurrentUser)
                        TextButton.icon(
                          onPressed: () => _editProfile(user),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bio Section
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(user.bio!),
                  const SizedBox(height: 24),
                ],

                // Interests Section
                if (user.interests.isNotEmpty) ...[
                  const Text(
                    'Interests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.interests.map((interest) {
                      return Chip(
                        label: Text(interest),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Stats Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Followers', user.followers.length),
                    _buildStatColumn('Following', user.following.length),
                  ],
                ),

                const SizedBox(height: 24),

                // Follow/Unfollow Button
                if (!_isCurrentUser)
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement follow/unfollow logic
                      },
                      child: const Text('Follow'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}