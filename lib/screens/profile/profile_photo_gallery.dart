import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image_picker/image_picker.dart' as picker; // Use prefix for ImagePicker
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:hiker_connect/models/photo_data.dart';
import 'package:hiker_connect/services/databaseservice.dart';
import 'package:hiker_connect/utils/logger.dart';
import 'package:hiker_connect/widgets/shimmer_loading.dart';
import 'package:hiker_connect/screens/photos/photo_detail_screen.dart';

import '../../models/user_model.dart';

class ProfilePhotoGallery extends StatefulWidget {
  final String userId;

  const ProfilePhotoGallery({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _ProfilePhotoGalleryState createState() => _ProfilePhotoGalleryState();
}

class _ProfilePhotoGalleryState extends State<ProfilePhotoGallery> {
  final DatabaseService _databaseService = DatabaseService();
  List<PhotoData>? _photos;
  bool _isLoading = true;
  bool _isCurrentUser = false;
  List<String> _imageUrls = [];
  final picker.ImagePicker _picker = picker.ImagePicker(); // Use prefix for ImagePicker
  List<File> _galleryImages = [];

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == FirebaseAuth.instance.currentUser?.uid;
    _loadPhotos();
    _loadSavedImages(); // Load saved images when the page is opened
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final photos = await _databaseService.getUserPhotos(widget.userId);

      if (mounted) {
        setState(() {
          _photos = photos;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading photos: $e');

      if (mounted) {
        setState(() {
          _photos = [];
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load photos: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: picker.ImageSource.gallery, // Use prefix for ImageSource
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploading photo...')),
        );
      }

      final file = File(pickedFile.path);
      await _databaseService.uploadPhoto(
        file,
        caption: 'Shared from my profile',
      );

      // Refresh the gallery
      await _loadPhotos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo uploaded successfully')),
        );
      }
    } catch (e) {
      AppLogger.error('Error uploading photo: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: ${e.toString()}')),
        );
      }
    }
  }

  void _openPhotoDetail(PhotoData photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PhotoDetailScreen(
              photo: photo,
              isOwner: _isCurrentUser,
            ),
      ),
    ).then((deleted) {
      if (deleted == true) {
        // If photo was deleted, reload the gallery
        _loadPhotos();
      }
    });
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
                  await _pickImage(picker.ImageSource.camera); // Use prefix for ImageSource
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text("Select from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(picker.ImageSource.gallery); // Use prefix for ImageSource
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(picker.ImageSource source) async {
    final picker.XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      await _saveImages(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingGrid();
    }

    if (_photos == null || _photos!.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
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
              itemCount: _imageUrls.length + 1, // Use _imageUrls instead of _galleryImages
              itemBuilder: (context, index) {
                if (index == _imageUrls.length) {
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
                  child: CachedNetworkImage(
                    imageUrl: _imageUrls[index], // Use _imageUrls instead of _galleryImages
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

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 9, // Show 9 shimmer placeholders
      itemBuilder: (context, index) {
        return ShimmerLoading(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
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
}