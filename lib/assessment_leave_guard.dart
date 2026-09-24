import 'package:flutter/material.dart';

import 'assessment_confirm_actions.dart';
import 'localization/language_controller.dart';

/// Neutral palette used by the leave-confirmation modal. The accent colors
/// (icon, Stay / Leave buttons) come from the calling module's theme.
class _LeaveDialogColors {
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color shadow = Color(0x1A000000);
}

/// Shows the shared "Leave assessment?" modal, tinted with the module's
/// [accentColor] (icon and buttons), [accentSoftColor] (icon background) and
/// [onAccentColor] (text on the solid Leave button).
///
/// Resolves to `true` only when the user taps **Leave**. Tapping **Stay**,
/// tapping outside the modal, or pressing the system back button all resolve
/// to `false`.
Future<bool> showLeaveAssessmentDialog(
  BuildContext context, {
  required Color accentColor,
  required Color accentSoftColor,
  required Color onAccentColor,
  ValueChanged<BuildContext>? onShown,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      onShown?.call(dialogContext);

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          decoration: BoxDecoration(
            color: _LeaveDialogColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _LeaveDialogColors.shadow.withOpacity(0.80),
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
                decoration: BoxDecoration(
                  color: accentSoftColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: accentColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                t(dialogContext, 'Leave assessment?', 'Umalis sa pagsusulit?'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _LeaveDialogColors.textPrimary,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                t(
                  dialogContext,
                  'Your answers and progress will not be saved if you leave '
                      'before submitting.',
                  'Hindi mase-save ang iyong mga sagot at progreso kung aalis '
                      'ka bago magpasa.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _LeaveDialogColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              AssessmentConfirmActions(
                reviewText: t(dialogContext, 'Stay', 'Manatili'),
                submitText: t(dialogContext, 'Leave', 'Umalis'),
                onReview: () => Navigator.pop(dialogContext, false),
                onSubmit: () => Navigator.pop(dialogContext, true),
                primaryColor: accentColor,
                onPrimaryColor: onAccentColor,
              ),
            ],
          ),
        ),
      );
    },
  );

  return result == true;
}

/// Guards a Pre-/Post-Assessment screen against leaving before submission.
///
/// Wrap the screen's [Scaffold] with [buildAssessmentLeaveGuard] (covers the
/// Android system back button / back gesture) and route every exit button
/// through [requestLeaveAssessment]. While [hasUnsubmittedAssessment] is
/// true the user is asked to confirm; choosing **Leave** simply pops the
/// screen — nothing is submitted, scored, or marked complete, and the
/// in-memory answers are discarded with the page.
mixin AssessmentLeaveGuard<T extends StatefulWidget> on State<T> {
  bool _leaveAllowed = false;
  bool _leaveDialogOpen = false;
  BuildContext? _leaveDialogContext;

  /// True while an assessment is in progress and has not been submitted.
  bool get hasUnsubmittedAssessment;

  /// Module theme accent for the leave modal's icon and Stay / Leave buttons.
  Color get leaveDialogAccentColor;

  /// Light module tint behind the leave modal's icon.
  Color get leaveDialogAccentSoftColor;

  /// Text color on the solid Leave button.
  Color get leaveDialogOnAccentColor;

  Widget buildAssessmentLeaveGuard({required Widget child}) {
    return PopScope(
      canPop: _leaveAllowed || !hasUnsubmittedAssessment,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        requestLeaveAssessment();
      },
      child: child,
    );
  }

  /// Leaves the assessment, confirming first if there is unsubmitted
  /// progress.
  Future<void> requestLeaveAssessment() async {
    if (_leaveDialogOpen || !mounted) return;

    if (_leaveAllowed || !hasUnsubmittedAssessment) {
      _leaveAllowed = true;
      Navigator.of(context).pop();
      return;
    }

    _leaveDialogOpen = true;
    final leave = await showLeaveAssessmentDialog(
      context,
      accentColor: leaveDialogAccentColor,
      accentSoftColor: leaveDialogAccentSoftColor,
      onAccentColor: leaveDialogOnAccentColor,
      onShown: (dialogContext) => _leaveDialogContext = dialogContext,
    );
    _leaveDialogOpen = false;
    _leaveDialogContext = null;

    if (!leave || !mounted) return;

    _leaveAllowed = true;
    Navigator.of(context).pop();
  }

  /// Closes the screen without the unsaved-progress warning, for flows that
  /// exit on their own (e.g. the attempt is locked or failed to load).
  void closeAssessmentWithoutPrompt() {
    if (!mounted) return;
    _leaveAllowed = true;
    Navigator.of(context).maybePop();
  }

  /// Closes the leave modal (as "Stay") if it is showing, e.g. when the quiz
  /// timer runs out and the assessment is about to auto-submit.
  void dismissLeaveAssessmentDialog() {
    final dialogContext = _leaveDialogContext;
    if (dialogContext == null) return;
    _leaveDialogContext = null;
    Navigator.of(dialogContext).pop(false);
  }
}
