import 'package:flutter/material.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/services/firebase_auth.dart';

/// A testable version of ProfileScreen that allows for easier testing
/// by accepting dependencies through constructor injection.
class TestableProfileScreen extends StatefulWidget {
  final AuthService authService;

  const TestableProfileScreen({
    Key? key,
    required this.authService,
  }) : super(key: key);

  @override
  State<TestableProfileScreen> createState() => _TestableProfileScreenState();
}

class _TestableProfileScreenState extends State<TestableProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await widget.authService.getCurrentUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userData == null) {
      return const Scaffold(
        body: Center(
          child: Text('Error loading user data'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userData?.displayName ?? 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile screen
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Medical'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildMedicalTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: _userData?.photoUrl != null
                  ? NetworkImage(_userData!.photoUrl!)
                  : null,
              child: _userData?.photoUrl == null
                  ? Text(
                _userData?.displayName?.substring(0, 1) ?? 'U',
                style: const TextStyle(fontSize: 40),
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _userData?.displayName ?? 'User',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (_userData?.bio != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(_userData!.bio!),
            ),
          // Add other profile information here
        ],
      ),
    );
  }

  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Medical Information',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Blood Type', _userData?.bloodType ?? 'Not provided'),
                const SizedBox(height: 8),
                _buildInfoRow('Allergies', _userData?.allergies ?? 'None'),
                const SizedBox(height: 8),
                const Text(
                  'Medical Conditions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._userData?.medicalConditions?.map((condition) => Text('• $condition')) ??
                    [const Text('None')],
                const SizedBox(height: 8),
                const Text(
                  'Medications:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._userData?.medications?.map((medication) => Text('• $medication')) ??
                    [const Text('None')],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Emergency Contacts',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _userData?.emergencyContacts?.isNotEmpty == true
                  ? _userData!.emergencyContacts!
                  .map(
                    (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${contact.relationship} • ${contact.phoneNumber}'),
                    ],
                  ),
                ),
              )
                  .toList()
                  : [const Text('No emergency contacts provided')],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return const Center(
      child: Text('Activity information will be displayed here'),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}