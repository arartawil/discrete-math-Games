import 'package:flutter/material.dart';

class InfoDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String markdownText,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: SelectableText(markdownText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
