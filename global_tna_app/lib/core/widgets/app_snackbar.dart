import 'package:flutter/material.dart';

enum AppSnackType { success, error, info }

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackType type = AppSnackType.info,
  }) {
    final theme = Theme.of(context);
    final color = switch (type) {
      AppSnackType.success => Colors.green.shade700,
      AppSnackType.error => theme.colorScheme.error,
      AppSnackType.info => theme.colorScheme.primary,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
