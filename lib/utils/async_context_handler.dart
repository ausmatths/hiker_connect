import 'package:flutter/material.dart';

class AsyncContextHandler {
  // Generic method for safe async operations
  static Future<void> safeAsyncOperation(
      BuildContext context,
      Future<void> Function() operation, {
        VoidCallback? onSuccess,
        Function(dynamic)? onError,
      }) async {
    // Check if the context is still valid
    if (!context.mounted) return;

    try {
      await operation();

      // Check mounting again after async operation
      if (!context.mounted) return;

      // Optional success callback
      onSuccess?.call();
    } catch (e) {
      // Check mounting before showing any UI
      if (!context.mounted) return;

      // Error handling
      onError?.call(e);
      _showErrorSnackBar(context, e);
    }
  }

  // Utility method to show error snackbar
  static void _showErrorSnackBar(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('An error occurred: ${error.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}