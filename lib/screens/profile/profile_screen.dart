import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hiker_connect/models/user_model.dart';
import 'package:hiker_connect/services/firebase_auth.dart';
import 'package:hiker_connect/screens/profile/edit_profile_screen.dart';
import 'package:hiker_connect/utils/async_context_handler.dart';
import 'package:hiker_connect/utils/logger.dart';
import 'package:image_picker/image_picker.dart';
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

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  static const double _avatarRadius = 50.0;
  late Future<UserModel?> _userFuture;
  bool _isCurrentUser = false;
  late TabController _tabController;
  List<File> _galleryImages = [];
  List<String> _imageUrls = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _userFuture = Future.value(null);
    _loadSavedImages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        final authService = context.read<AuthService>();
        await _loadUserData(authService);
      },
      onError: (error) {
        AppLogger.error('Error loading user dependencies: ${error.toString()}');
        _handleInitializationError(error);
      },
    );
  }

  Future<void> _loadUserData(AuthService authService) async {
    try {
      if (widget.userId != null) {
        _userFuture = authService.getUserData(widget.userId!);
        _isCurrentUser = widget.userId == authService.currentUser?.uid;
      } else {
        _userFuture = authService.getCurrentUserData();
        _isCurrentUser = true;
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      await _handleInitializationError(e);
    }
  }

  Future<void> _handleInitializationError(Object error) async {
    await AsyncContextHandler.safeAsyncOperation(
      context,
          () async {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Initialization Error'),
            content: Text(error.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  final authService = context.read<AuthService>();

                  // Separate method to handle retry
                  _retryLoadUserData(authService);
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
      },
      onError: (dialogError) {
        AppLogger.error('Error showing initialization error dialog: ${dialogError.toString()}');
      },
    );
  }

  void _retryLoadUserData(AuthService authService) {
    // Set a new future that attempts to load user data
    setState(() {
      _userFuture = Future.sync(() async {
        try {
          return await (widget.userId != null
              ? authService.getUserData(widget.userId!)
              : authService.getCurrentUserData());
        } catch (e) {
          AppLogger.error('Error reloading user data: $e');
          return null;
        }
      });
    });
  }

  Future<void> _editProfile(UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: user),
      ),
    );

    if (result == true && mounted) {
      final authService = context.read<AuthService>();

      // Use _retryLoadUserData method
      _retryLoadUserData(authService);
    }
  }

  Future<void> _handleSignOut() async {
    try {
      final authService = context.read<AuthService>();
      await authService.signOut();

      // Navigate to login explicitly instead of waiting for the AuthWrapper
      if (mounted) {
        // Use pushNamedAndRemoveUntil to clear the entire navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      AppLogger.error('Unexpected error during sign out: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _loadSavedImages() async {
    print('Loading saved images for user: ${widget.userId}');
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (doc.exists && doc.data()!.containsKey('galleryImages')) {
      setState(() {
        _imageUrls = List<String>.from(doc['galleryImages']);
      });
    }
  }
  // Future<void> _pickImage(picker.ImageSource source) async {
  //   final picker.XFile? image = await _picker.pickImage(source: source);
  //   if (image != null) {
  //     await _saveImages(File(image.path));
  //   }
  // }

  Future<void> _saveImages(File imageFile) async {
    try {
      String fileName = 'gallery/${widget.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putFile(imageFile);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _imageUrls.add(downloadUrl);
      });

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
        'galleryImages': _imageUrls,
      }, SetOptions(merge: true));

    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Choose Image Source"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text("Take a Photo"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Select from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      await _saveImages(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (_isCurrentUser) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () async {
                final user = await _userFuture;
                if (user != null) {
                  await _editProfile(user);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _handleSignOut,
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(key: ValueKey('feed_tab'), text: 'Feed'),
            Tab(key: ValueKey('photos_tab'), text: 'Photos'),
            Tab(key: ValueKey('reviews_tab'), text: 'Reviews'),
            Tab(key: ValueKey('activities_tab'), text: 'Activities'),
            Tab(key: ValueKey('more_tab'), text: 'More'),
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
                  // valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final authService = context.read<AuthService>();
                        _retryLoadUserData(authService);
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
                child: Text('User not found', style: TextStyle(color: Colors.white)),
              );
            }

            return Column(
              children: [
                _buildProfileHeader(user),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFeedTab(),
                      _buildPhotoGalleryTab(user),
                      // ProfilePhotoGallery(userId: user.uid ?? widget.userId ?? ''),
                      _buildReviewsTab(),
                      _buildActivitiesTab(),
                      _buildMoreTabContent(user),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: _avatarRadius,
            backgroundColor: Colors.grey[800],
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
                color: Colors.white,
              ),
            )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          if (user.location?.address?.isNotEmpty == true)
            Text(
              user.location!.address ?? '',
              style: TextStyle(color: Colors.grey[400]),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('Followers', user.followers.length),
              Container(width: 1, height: 40, color: Colors.grey[800]),
              _buildStatColumn('Following', user.following.length),
            ],
          ),
          const SizedBox(height: 16),
          // Stats card similar to the screenshot
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '2025 Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Icon(Icons.arrow_forward, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: const [
                          Text(
                            '0',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Activities',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 70,
                      width: 1,
                      color: Colors.white24,
                    ),
                    Expanded(
                      child: Column(
                        children: const [
                          Text(
                            '0',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Miles',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return const Center(
      child: Text(
        'Feed content will be displayed here',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
  Widget _buildPhotoGalleryTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Photo Gallery',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _galleryImages.length + 1,
              itemBuilder: (context, index) {
                if (index == _galleryImages.length) {
                  return GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.grey.shade200,
                      ),
                      child: Icon(
                        Icons.photo_camera,
                        size: 40,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _galleryImages[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildReviewsTab() {
    return const Center(
      child: Text(
        'Reviews will be displayed here',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildActivitiesTab() {
    return const Center(
      child: Text(
        'Activities will be displayed here',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildMoreTabContent(UserModel user) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Medical'),
              Tab(text: 'Emergency'),
              Tab(text: 'Social'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBasicInfoTab(user),
                _buildMedicalInfoTab(user),
                _buildEmergencyContactsTab(user),
                _buildSocialTab(user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.interests.map((interest) {
                return Chip(
                  label: Text(interest),
                  backgroundColor: Colors.green.shade900,
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              const Text(
                'Add some photos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share your hiking experiences',
                style: TextStyle(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_isCurrentUser)
                ElevatedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Upload Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
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
        child: Text('No medical information available', style: TextStyle(color: Colors.white)),
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
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: emergencyContacts.length,
      itemBuilder: (context, index) {
        final contact = emergencyContacts[index];
        return Card(
          color: Colors.grey[900],
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade900,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              contact.name,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.relationship, style: TextStyle(color: Colors.grey[400])),
                Text(contact.phoneNumber, style: TextStyle(color: Colors.grey[400])),
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
        child: Text('No social links added', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: socialLinks.length,
      itemBuilder: (context, index) {
        final platform = socialLinks.keys.elementAt(index);
        final link = socialLinks[platform];
        return Card(
          color: Colors.grey[900],
          child: ListTile(
            leading: Icon(_getSocialIcon(platform), color: Colors.green),
            title: Text(platform, style: const TextStyle(color: Colors.white)),
            subtitle: Text(link ?? '', style: TextStyle(color: Colors.grey[400])),
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(content, style: TextStyle(color: Colors.grey[300])),
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        // Use ListView.builder for larger lists
        items.length > 10
            ? ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) => Chip(
            label: Text(items[index]),
            backgroundColor: Colors.green.shade900,
            labelStyle: const TextStyle(color: Colors.white),
          ),
        )
            : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Chip(
            label: Text(item),
            backgroundColor: Colors.green.shade900,
            labelStyle: const TextStyle(color: Colors.white),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400]),
        ),
      ],
    );
  }
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 16,
        ),
      ),
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