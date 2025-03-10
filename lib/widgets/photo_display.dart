import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hiker_connect/models/photo_data.dart';

class PhotoDisplay extends StatelessWidget {
  final PhotoData photo;
  final bool useThumbnail;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const PhotoDisplay({
    Key? key,
    required this.photo,
    this.useThumbnail = true,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = useThumbnail && photo.thumbnailUrl != null
        ? photo.thumbnailUrl!
        : photo.url;

    Widget imageWidget;

    // Determine whether to use network or local image
    if (imageUrl.startsWith('http')) {
      // Use network image with local fallback
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) {
          // Try to load from local path if network fails
          return _buildLocalImage(imageUrl);
        },
      );
    } else {
      // Use local image directly
      imageWidget = _buildLocalImage(imageUrl);
    }

    // Apply border radius if specified
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalImage(String path) {
    // Handle both regular paths and file:// URIs
    File file;

    if (path.startsWith('file://')) {
      // For file:// URIs, we need to extract the path part
      try {
        final uri = Uri.parse(path);
        file = File(uri.path);
      } catch (e) {
        // If URI parsing fails, try using the path directly without the scheme
        file = File(path.replaceFirst('file://', ''));
      }
    } else {
      // Regular file path
      file = File(path);
    }

    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingPlaceholder();
        }

        if (snapshot.data == true) {
          return Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (ctx, error, stackTrace) {
              return _buildErrorPlaceholder();
            },
          );
        } else {
          // If we reach here, try other potential paths if available
          if (photo.localPath != null && photo.localPath != path) {
            return _buildLocalImage(photo.localPath!); // Recursive call with alternate path
          } else {
            return _buildErrorPlaceholder();
          }
        }
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          size: 32,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}