import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

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
