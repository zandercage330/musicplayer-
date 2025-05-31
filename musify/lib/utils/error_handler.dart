import 'package:flutter/material.dart';

/// A utility class for handling errors throughout the application.
/// It provides methods for logging errors and showing user-friendly messages.
class ErrorHandler {
  // Private constructor to prevent instantiation
  ErrorHandler._();

  /// Logs an error message and optionally an exception and stack trace.
  ///
  /// [message] A descriptive message about the error.
  /// [error] The exception object (optional).
  /// [stackTrace] The stack trace (optional).
  static void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    print('[ERROR] $message');
    if (error != null) {
      print('  Exception: $error');
    }
    if (stackTrace != null) {
      print('  Stack Trace: \n$stackTrace');
    }
    // In a real app, you might integrate with a crash reporting service here
    // e.g., Firebase Crashlytics, Sentry, etc.
  }

  /// Shows a user-friendly error message using a SnackBar.
  ///
  /// [context] The BuildContext to show the SnackBar in.
  /// [message] The user-friendly message to display.
  /// [actionLabel] Optional label for an action button on the SnackBar.
  /// [onAction] Optional callback for the action button.
  static void showUserFriendlyError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return; // Check if the context is still valid

    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating, // Or .fixed depending on design
      action:
          actionLabel != null && onAction != null
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
    );

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar(); // Hide any existing snackbar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// A more comprehensive handler that logs the error and shows a user-friendly message.
  ///
  /// [context] The BuildContext for showing the SnackBar.
  /// [logMessage] The message to log (can be more technical).
  /// [userMessage] The user-friendly message to display.
  /// [error] The exception object (optional).
  /// [stackTrace] The stack trace (optional).
  static void handleError(
    BuildContext context, {
    required String logMessage,
    required String userMessage,
    Object? error,
    StackTrace? stackTrace,
  }) {
    logError(logMessage, error: error, stackTrace: stackTrace);
    showUserFriendlyError(context, userMessage);
  }
}
