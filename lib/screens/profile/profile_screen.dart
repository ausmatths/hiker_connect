import 'package:flutter/material.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/screens/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
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
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Profile',
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          actions: [
            if (_isCurrentUser) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.black),
                onPressed: () async {
                  try {
                    final user = await _userFuture;
                    if (user != null && mounted) {
                      await _editProfile(user);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error loading profile: $e')),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black),
                onPressed: () async {
                  try {
                    await _authService.signOut();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error signing out: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ],
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Medical'),
              Tab(text: 'Emergency'),
              Tab(text: 'Social'),
            ],
          ),
        ),
        body: SafeArea(
          child: FutureBuilder<UserModel?>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
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
                        'Error loading profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _loadUserData()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final user = snapshot.data;
              if (user == null) {
                return const Center(
                  child: Text('User not found'),
                );
              }

              return TabBarView(
                children: [
                  _buildBasicInfoTab(user),
                  _buildMedicalInfoTab(user),
                  _buildEmergencyContactsTab(user),
                  _buildSocialTab(user),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('Followers', user.followers.length),
                    _buildStatColumn('Following', user.following.length),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSection('Bio', user.bio),
          _buildSection('Phone', user.phoneNumber),
          if (user.location != null)
            _buildSection('Address', user.location!.address),
          _buildSection('Gender', user.gender),
          if (user.dateOfBirth != null)
            _buildSection('Date of Birth',
                '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}'
            ),
          if (user.height != null)
            _buildSection('Height', '${user.height} cm'),
          if (user.weight != null)
            _buildSection('Weight', '${user.weight} kg'),
          _buildSection('Language', user.preferredLanguage),

          if (user.interests.isNotEmpty) ...[
            const SizedBox(height: 16),
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
                  backgroundColor: Colors.deepPurple.shade50,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMedicalInfoTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Blood Type', user.bloodType),
          _buildSection('Allergies', user.allergies),
          _buildSection('Insurance Info', user.insuranceInfo),

          if (user.medicalConditions.isNotEmpty)
            _buildListSection('Medical Conditions', user.medicalConditions),

          if (user.medications.isNotEmpty)
            _buildListSection('Medications', user.medications),

          if (user.medicalConditions.isEmpty &&
              user.medications.isEmpty &&
              user.bloodType == null &&
              user.allergies == null &&
              user.insuranceInfo == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No medical information added',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsTab(UserModel user) {
    if (user.emergencyContacts.isEmpty) {
      return Center(
        child: Text(
          'No emergency contacts added',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: user.emergencyContacts.length,
      itemBuilder: (context, index) {
        final contact = user.emergencyContacts[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(
              contact.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.relationship),
                Text(contact.phoneNumber),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialTab(UserModel user) {
    if (user.socialLinks?.isEmpty ?? true) {
      return const Center(
        child: Text('No social links added'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: user.socialLinks!.length,
      itemBuilder: (context, index) {
        final platform = user.socialLinks!.keys.elementAt(index);
        final link = user.socialLinks![platform];
        return Card(
          child: ListTile(
            leading: Icon(_getSocialIcon(platform)),
            title: Text(platform),
            subtitle: Text(link ?? ''),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(content),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Chip(
            label: Text(item),
            backgroundColor: Colors.deepPurple.shade50,
          )).toList(),
        ),
        const SizedBox(height: 16),
      ],
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

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.ac_unit; // Replace with appropriate icon
      case 'instagram':
        return Icons.camera_alt;
      case 'linkedin':
        return Icons.work;
      default:
        return Icons.link;
    }
  }
}