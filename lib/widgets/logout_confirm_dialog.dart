import 'package:flutter/material.dart';

import '../assessment_confirm_actions.dart';
import '../localization/language_controller.dart';

/// IGNIS SAFE brand palette used by the logout confirmation modal; matches
/// the shared "Leave assessment?" modal so both warnings look the same.
class _LogoutDialogColors {
  static const Color brandRed = Color(0xFFB11217);
  static const Color brandRedSoft = Color(0xFFFFE8EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textOnRed = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x1A000000);
}

/// Prevents a quick double tap on a Log Out action from stacking two modals.
bool _logoutDialogOpen = false;

/// Shows the shared "Log out?" confirmation modal.
///
/// Resolves to `true` only when the user taps **Log Out**. Tapping
/// **Cancel**, tapping outside the modal, or pressing the system back button
/// all resolve to `false`, leaving the session untouched.
Future<bool> showLogoutConfirmDialog(BuildContext context) async {
  if (_logoutDialogOpen) return false;
  _logoutDialogOpen = true;

  try {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            decoration: BoxDecoration(
              color: _LogoutDialogColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _LogoutDialogColors.shadow.withValues(alpha: 0.80),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 68,
                  width: 68,
                  decoration: const BoxDecoration(
                    color: _LogoutDialogColors.brandRedSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: _LogoutDialogColors.brandRed,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  t(dialogContext, 'Log out?', 'Mag-logout?'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _LogoutDialogColors.textPrimary,
                    height: 1.18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t(
                    dialogContext,
                    'Are you sure you want to log out of your account?',
                    'Sigurado ka bang gusto mong mag-logout sa iyong account?',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _LogoutDialogColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                AssessmentConfirmActions(
                  reviewText: t(dialogContext, 'Cancel', 'Kanselahin'),
                  submitText: t(dialogContext, 'Log Out', 'Mag-logout'),
                  onReview: () => Navigator.pop(dialogContext, false),
                  onSubmit: () => Navigator.pop(dialogContext, true),
                  primaryColor: _LogoutDialogColors.brandRed,
                  onPrimaryColor: _LogoutDialogColors.textOnRed,
                ),
              ],
            ),
          ),
        );
      },
    );

    return result == true;
  } finally {
    _logoutDialogOpen = false;
  }
}
