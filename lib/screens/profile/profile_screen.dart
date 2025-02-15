import 'package:flutter/material.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/screens/profile/edit_profile_screen.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _avatarRadius = 50.0;
  late Future<UserModel?> _userFuture;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _userFuture = Future.value(null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final authService = context.read<AuthService>();
      _loadUserData(authService);
    } catch (e) {
      _handleInitializationError(e);
    }
  }

  void _loadUserData(AuthService authService) {
    try {
      if (widget.userId != null) {
        _userFuture = authService.getUserData(widget.userId!);
        _isCurrentUser = widget.userId == authService.currentUser?.uid;
      } else {
        _userFuture = authService.getCurrentUserData();
        _isCurrentUser = true;
      }

      if (mounted) setState(() {});
    } catch (e) {
      _handleInitializationError(e);
    }
  }

  void _handleInitializationError(Object error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Initialization Error'),
            content: Text(error.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final authService = context.read<AuthService>();
                  _loadUserData(authService);
                },
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    });

    setState(() {
      _userFuture = Future.value(null);
    });
  }

  Future<void> _editProfile(UserModel user) async {
    final authService = context.read<AuthService>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: user),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _loadUserData(authService);
      });
    }
  }

  Future<void> _handleSignOut() async {
    try {
      final authService = context.read<AuthService>();
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
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
    onPressed: _handleSignOut,
    ),
    ],
    ],
          bottom: TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(key: ValueKey('info_tab'), text: 'Info'),
              Tab(key: ValueKey('medical_tab'), text: 'Medical'),
              Tab(key: ValueKey('emergency_tab'), text: 'Emergency'),
              Tab(key: ValueKey('social_tab'), text: 'Social'),
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
                          onPressed: () {
                            final authService = context.read<AuthService>();
                            setState(() => _loadUserData(authService));
                          },
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
        radius: _avatarRadius,
        backgroundColor: Colors.deepPurple.shade50,
        backgroundImage: user.photoUrl.isNotEmpty
            ? NetworkImage(user.photoUrl)
            : null,
        onBackgroundImageError: user.photoUrl.isNotEmpty
            ? (exception, stackTrace) {
          debugPrint('Error loading profile image: $exception');
        }
            : null,
        child: user.photoUrl.isEmpty
            ? Text(
          user.displayName.isNotEmpty
              ? user.displayName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 32,
            color: Colors.deepPurple,
          ),
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
    _buildSection(
    'Date of Birth',
    '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}',
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
    final medicalConditions = user.medicalConditions ?? [];
    final medications = user.medications ?? [];
    final allergies = user.allergies ?? '';
    final bloodType = user.bloodType ?? '';
    final insuranceInfo = user.insuranceInfo ?? '';

    final bool hasNoMedicalInfo = medicalConditions.isEmpty &&
        medications.isEmpty &&
        allergies.isEmpty &&
        bloodType.isEmpty &&
        insuranceInfo.isEmpty;

    if (hasNoMedicalInfo) {
      return const Center(
        child: Text('No medical information available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Blood Type', user.bloodType),
          _buildSection('Allergies', user.allergies),
          _buildSection('Insurance Info', user.insuranceInfo),

          if (medicalConditions.isNotEmpty)
            _buildListSection('Medical Conditions', medicalConditions),

          if (medications.isNotEmpty)
            _buildListSection('Medications', medications),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsTab(UserModel user) {
    final emergencyContacts = user.emergencyContacts ?? [];

    if (emergencyContacts.isEmpty) {
      return Center(
        child: Text(
          'No emergency contacts added',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: emergencyContacts.length,
      itemBuilder: (context, index) {
        final contact = emergencyContacts[index];
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
    final socialLinks = user.socialLinks ?? {};

    if (socialLinks.isEmpty) {
      return const Center(
        child: Text('No social links added'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: socialLinks.length,
      itemBuilder: (context, index) {
        final platform = socialLinks.keys.elementAt(index);
        final link = socialLinks[platform];
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
        // Use ListView.builder for larger lists
        items.length > 10
            ? ListView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          itemBuilder: (context, index) => Chip(
            label: Text(items[index]),
            backgroundColor: Colors.deepPurple.shade50,
          ),
        )
            : Wrap(
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