import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:hiker_connect/models/photo_data.dart';
import 'package:hiker_connect/services/databaseservice.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hiker_connect/utils/logger.dart';

class PhotoDetailScreen extends StatefulWidget {
  final PhotoData photo;
  final bool isOwner;

  const PhotoDetailScreen({
    Key? key,
    required this.photo,
    this.isOwner = false,
  }) : super(key: key);

  @override
  _PhotoDetailScreenState createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late TextEditingController _captionController;
  bool _isEditing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.photo.caption);
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _updateCaption() async {
    if (_captionController.text == widget.photo.caption) {
      setState(() {
        _isEditing = false;
      });
      return;
    }

    try {
      await _databaseService.updatePhotoCaption(
        widget.photo.id,
        _captionController.text,
      );

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caption updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error('Error updating caption: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update caption')),
      );
    }
  }

  Future<void> _deletePhoto() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await _databaseService.deletePhoto(widget.photo.id);

      // Return to previous screen after deletion
      Navigator.pop(context, true); // Pass true to indicate deletion

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });

      AppLogger.error('Error deleting photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete photo')),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Delete Photo', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete this photo? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: Colors.green[300])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePhoto();
            },
            child: Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Photo Details', style: TextStyle(color: Colors.white)),
        actions: [
          if (widget.isOwner)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.green),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
            ),
          if (widget.isOwner)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: Stack(
        children: [
          PhotoView(
            imageProvider: CachedNetworkImageProvider(widget.photo.url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: widget.photo.id),
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                value: event?.expectedTotalBytes != null
                    ? event!.cumulativeBytesLoaded / event.expectedTotalBytes!
                    : null,
              ),
            ),
            backgroundDecoration: BoxDecoration(color: Colors.black),
          ),
          if (_isDeleting)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.7),
              child: _isEditing
                  ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _captionController,
                    decoration: InputDecoration(
                      hintText: 'Add a caption',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white24,
                    ),
                    style: TextStyle(color: Colors.white),
                    maxLines: 3,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = false;
                            _captionController.text = widget.photo.caption ?? '';
                          });
                        },
                        child: Text('CANCEL', style: TextStyle(color: Colors.green[300])),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _updateCaption,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text('SAVE'),
                      ),
                    ],
                  ),
                ],
              )
                  : widget.photo.caption != null && widget.photo.caption!.isNotEmpty
                  ? Text(
                widget.photo.caption!,
                style: TextStyle(color: Colors.white),
              )
                  : SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}