import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool isTimeoutError(dynamic error) {
  if (error is TimeoutException) return true;
  final msg = error.toString().toLowerCase();
  return msg.contains('timeoutexception') ||
      msg.contains('timed out') ||
      msg.contains('timeout');
}

bool isSessionError(dynamic error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    return msg.contains('jwt') ||
        msg.contains('session') ||
        msg.contains('refresh token') ||
        msg.contains('not authenticated') ||
        msg.contains('token is expired') ||
        msg.contains('401');
  }
  final msg = error.toString().toLowerCase();
  return msg.contains('jwt expired') ||
      msg.contains('invalid refresh token') ||
      msg.contains('refresh_token_not_found') ||
      msg.contains('session_not_found') ||
      msg.contains('session_expired') ||
      msg.contains('session is expired') ||
      msg.contains('no active session') ||
      msg.contains('auth session missing') ||
      msg.contains('pgrst301');
}

bool isServerError(dynamic error) {
  if (error is PostgrestException) return true;
  final msg = error.toString().toLowerCase();
  return msg.contains('postgrestexception') ||
      msg.contains('internal server error') ||
      msg.contains('service unavailable') ||
      msg.contains('bad gateway') ||
      msg.contains('server error') ||
      msg.contains(' 500') ||
      msg.contains(' 502') ||
      msg.contains(' 503');
}

/// Classifies any caught error/exception and returns a short, non-technical
/// message safe to show to end users. Never surfaces exception types, stack
/// traces, URLs, or backend/provider details — callers should still log the
/// original [error] to the console (e.g. via `debugPrint`) for diagnostics.
String friendlyErrorMessage(dynamic error, {bool isTagalog = false}) {
  if (isSessionError(error)) {
    return isTagalog
        ? 'Nag-expire na ang iyong session. Mangyaring mag-sign in muli.'
        : 'Your session has expired. Please sign in again.';
  }
  if (isTimeoutError(error)) {
    return isTagalog
        ? 'Matagal masyado ang request. Pakisubukang muli.'
        : 'The request is taking too long. Please try again.';
  }
  if (isNetworkError(error)) {
    return isTagalog
        ? 'Walang internet connection. Pakisuri ang iyong network at subukang muli.'
        : 'No internet connection. Please check your network and try again.';
  }
  if (isServerError(error)) {
    return isTagalog
        ? 'Hindi namin nakumpleto ang iyong request ngayon. Pakisubukang muli mamaya.'
        : "We couldn't complete your request right now. Please try again later.";
  }
  return isTagalog
      ? 'May naganap na error. Pakisubukang muli.'
      : 'Something went wrong. Please try again.';
}

/// Convenience wrapper that resolves the Tagalog flag from [context] before
/// delegating to [friendlyErrorMessage].
String friendlyErrorMessageFor(BuildContext context, dynamic error) {
  final isTagalog = Localizations.localeOf(context).languageCode == 'tl';
  return friendlyErrorMessage(error, isTagalog: isTagalog);
}

bool isNetworkError(dynamic error) {
  if (error is SocketException) return true;
  if (error is TimeoutException) return true;
  final msg = error.toString().toLowerCase();
  return msg.contains('socketexception') ||
      msg.contains('authretryablefetchexception') ||
      msg.contains('failed host lookup') ||
      msg.contains('connection refused') ||
      msg.contains('connection reset') ||
      msg.contains('network is unreachable') ||
      msg.contains('clientexception') ||
      msg.contains('operation timed out') ||
      msg.contains('request_timeout') ||
      msg.contains('connection timed out') ||
      msg.contains('connection closed') ||
      msg.contains('connection terminated') ||
      msg.contains('no address associated') ||
      msg.contains('errno = 7') ||
      msg.contains('errno = 101') ||
      msg.contains('errno = 111');
}

Future<void> showNoInternetDialog(BuildContext context) async {
  if (!context.mounted) return;
  final isTl = Localizations.localeOf(context).languageCode == 'tl';
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          isTl ? 'Walang Internet' : 'No Internet Connection',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          isTl
              ? 'Hindi kami makakonekta sa server. Mangyaring i-on ang iyong internet connection at subukang muli.'
              : "We couldn't connect to the server. Please turn on your internet connection and try again.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Poppins', height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    },
  );
}
