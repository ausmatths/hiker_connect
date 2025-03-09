// lib/screens/profile/profile_photo_gallery.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:hiker_connect/models/photo_data.dart';
import 'package:hiker_connect/services/databaseservice.dart';
import 'package:hiker_connect/utils/logger.dart';
import 'package:hiker_connect/widgets/shimmer_loading.dart';
import 'package:hiker_connect/screens/photos/photo_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == FirebaseAuth.instance.currentUser?.uid;
    _loadPhotos();
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
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingGrid();
    }

    if (_photos == null || _photos!.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        GridView.builder(
          padding: EdgeInsets.all(4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: _photos!.length,
          itemBuilder: (context, index) {
            final photo = _photos![index];
            return _buildPhotoTile(photo);
          },
        ),
        if (_isCurrentUser)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _pickAndUploadImage,
              backgroundColor: Colors.green,
              child: Icon(Icons.add_a_photo),
              tooltip: 'Upload Photo',
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoTile(PhotoData photo) {
    return GestureDetector(
      onTap: () => _openPhotoDetail(photo),
      child: Hero(
        tag: photo.id,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CachedNetworkImage(
            imageUrl: photo.thumbnailUrl ?? photo.url,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                ),
            errorWidget: (context, url, error) =>
                Container(
                  color: Colors.grey[800],
                  child: Icon(Icons.error, color: Colors.white54),
                ),
          ),
        ),
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
        // Remove the problematic parameters
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
                  onPressed: _pickAndUploadImage,
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