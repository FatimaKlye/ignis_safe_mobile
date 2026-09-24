import 'package:flutter/material.dart';

import '../localization/language_controller.dart';
import '../login.dart';
import 'password_changed_dialog.dart' show formatChangedAt;

const Color _emailChangedBrandRed = Color(0xFFB11217);
const List<Color> _emailChangedGradient = [
  Color(0xFFC9232A),
  _emailChangedBrandRed,
];

/// How long the "Email Changed" modal stays visible before sign-out.
const Duration emailChangedModalDuration = Duration(seconds: 2);

/// Runs the post-email-change exit: shows a non-dismissible "Email Changed"
/// modal with [newEmail] for [emailChangedModalDuration], then calls
/// [signOut] and replaces the whole stack with [LoginPage] so Back cannot
/// return to Profile/Home. The user then logs in with the new email.
///
/// Call only after Supabase confirms the email change is fully complete
/// (every Secure Email Change confirmation done). [navigator] must be the
/// root navigator, captured before any async gap, so the redirect still runs
/// even if the calling route is no longer mounted. [signOut] must not throw.
Future<void> showEmailChangedAndLogout(
  NavigatorState navigator, {
  required String newEmail,
  required Future<void> Function() signOut,
}) async {
  final changedAt = DateTime.now();

  // Not awaited: the dialog only closes when the stack is replaced below.
  showDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) =>
        _EmailChangedDialog(newEmail: newEmail, changedAt: changedAt),
  );

  await Future<void>.delayed(emailChangedModalDuration);
  await signOut();

  if (!navigator.mounted) return;
  navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}

class _EmailChangedDialog extends StatelessWidget {
  const _EmailChangedDialog({required this.newEmail, required this.changedAt});

  final String newEmail;
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
                  gradient: LinearGradient(colors: _emailChangedGradient),
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
                t(context, 'Email Changed', 'Napalitan ang Email'),
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
                  'Your email address was updated successfully.',
                  'Matagumpay na na-update ang iyong email address.',
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
                newEmail,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
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
                  color: _emailChangedBrandRed,
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
