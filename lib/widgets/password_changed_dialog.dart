import 'package:flutter/material.dart';

import '../localization/language_controller.dart';
import '../login.dart';

const Color _passwordChangedBrandRed = Color(0xFFB11217);
const List<Color> _passwordChangedGradient = [
  Color(0xFFC9232A),
  _passwordChangedBrandRed,
];

/// How long the "Password Changed" modal stays visible before sign-out.
const Duration passwordChangedModalDuration = Duration(seconds: 2);

const List<String> _monthsEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> _monthsTl = [
  'Enero',
  'Pebrero',
  'Marso',
  'Abril',
  'Mayo',
  'Hunyo',
  'Hulyo',
  'Agosto',
  'Setyembre',
  'Oktubre',
  'Nobyembre',
  'Disyembre',
];

/// Formats e.g. "September 24, 2026 • 7:45 PM".
String formatChangedAt(DateTime value, {required bool tagalog}) {
  final month = (tagalog ? _monthsTl : _monthsEn)[value.month - 1];
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour < 12 ? 'AM' : 'PM';
  return '$month ${value.day}, ${value.year} • $hour12:$minute $period';
}

/// Runs the post-password-change exit: shows a non-dismissible
/// "Password Changed" modal for [passwordChangedModalDuration], then calls
/// [signOut] and replaces the whole stack with [LoginPage] so Back cannot
/// return to Profile/Home.
///
/// Call only after the password update has succeeded. [navigator] must be the
/// root navigator, captured before any async gap, so the redirect still runs
/// even if the calling route is no longer mounted. [signOut] must not throw.
Future<void> showPasswordChangedAndLogout(
  NavigatorState navigator, {
  required Future<void> Function() signOut,
}) async {
  final changedAt = DateTime.now();

  // Not awaited: the dialog only closes when the stack is replaced below.
  showDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => _PasswordChangedDialog(changedAt: changedAt),
  );

  await Future<void>.delayed(passwordChangedModalDuration);
  await signOut();

  if (!navigator.mounted) return;
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

class _PasswordChangedDialog extends StatelessWidget {
  const _PasswordChangedDialog({required this.changedAt});

  final DateTime changedAt;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 360;
    final tagalog = Localizations.localeOf(context).languageCode == 'tl';

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 430),
          padding: EdgeInsets.all(compact ? 18 : 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Container(
                width: compact ? 54 : 62,
                height: compact ? 54 : 62,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: _passwordChangedGradient),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: compact ? 27 : 31,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                t(context, 'Password Changed', 'Napalitan ang Password'),
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: const Color(0xFF111827),
                  fontSize: compact ? 17 : 19,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t(
                  context,
                  'Your password was updated successfully.',
                  'Matagumpay na na-update ang iyong password.',
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF4B5563),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatChangedAt(changedAt, tagalog: tagalog),
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: _passwordChangedBrandRed,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t(context, 'Logging you out...', 'Nila-log out ka...'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF4B5563),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
