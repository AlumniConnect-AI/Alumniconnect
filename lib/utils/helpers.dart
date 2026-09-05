import 'package:flutter/material.dart';

class Helpers {
  // Show Snackbar
  static void showSnackBar(
      BuildContext context,
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Confirm dialog (logout, delete)
  static Future<bool> confirmAction(
      BuildContext context,
      String title,
      String message,
      ) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Confirm"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    ) ??
        false;
  }

  // Date formatter (Firestore → UI)
  static String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
