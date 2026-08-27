import 'package:dio/dio.dart';

/// Centralized Utility to transform raw Dio & Backend API errors into clean, human-readable messages.
/// Ensures raw technical error dumps are never displayed to the user.
abstract final class ApiErrorHandler {
  /// Parses any exception/error and returns a user-friendly message.
  static String parseMessage(
    dynamic error, {
    String fallback = 'Operation could not be completed. Please try again.',
  }) {
    if (error is String) {
      final message = error.trim();
      final lower = message.toLowerCase();
      if (lower.contains('401') ||
          lower.contains('unauthorized') ||
          lower.contains('authentication required') ||
          lower.contains('session expired')) {
        return 'Your session has expired. Please log in again.';
      }
      if (lower.contains('invalid credential') ||
          lower.contains('incorrect password')) {
        return 'Incorrect email or password.';
      }
      if (lower.contains('403') || lower.contains('forbidden')) {
        return 'You do not have permission for this action.';
      }
      if (lower.contains('dioexception') ||
          lower.contains('requestoptions') ||
          lower.contains('status code of')) {
        return fallback;
      }
      return message.isEmpty ? fallback : message;
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Network Timeout: Unable to connect to server. Please check internet connection.';
      }

      final response = error.response;
      if (response != null && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);

        // 1. Check custom backend error fields
        String? serverMsg;
        if (data['message'] is String &&
            (data['message'] as String).trim().isNotEmpty) {
          serverMsg = data['message'] as String;
        } else if (data['error'] is Map &&
            (data['error'] as Map)['message'] is String) {
          serverMsg = (data['error'] as Map)['message'] as String;
        }

        if (serverMsg != null && serverMsg.trim().isNotEmpty) {
          if (serverMsg.contains('Access restricted') ||
              serverMsg.contains('Forbidden')) {
            return 'Access Restricted: You do not have permission for this role.';
          }
          if (serverMsg.contains('expired') ||
              serverMsg.contains('Authentication required')) {
            return 'Session Expired: Please log in again to refresh your session.';
          }
          if (serverMsg.contains('not found') ||
              serverMsg.contains('NOT_FOUND')) {
            return 'Resource Not Found: Requested item does not exist on server.';
          }
          return serverMsg;
        }

        // 2. Status code based friendly messages
        switch (response.statusCode) {
          case 400:
            return 'Invalid Request: Please check the entered details and try again.';
          case 401:
            return 'Session Expired: Please log in again to continue.';
          case 403:
            return 'Access Denied: Your role does not have permission for this feature.';
          case 404:
            return 'Not Found: Requested record could not be found.';
          case 409:
            return 'Conflict: Record already exists or was updated elsewhere.';
          case 500:
          case 502:
          case 503:
            return 'Server Error: System is temporarily undergoing maintenance. Please retry shortly.';
        }
      }
    }

    if (error is Exception) {
      final msg = error.toString();
      if (msg.contains('SocketException')) {
        return 'Network Error: Unable to reach KaratFlow server.';
      }
      if (msg.contains('FormatException')) {
        return 'Data Error: Unexpected server response format.';
      }
    }

    return fallback;
  }
}
