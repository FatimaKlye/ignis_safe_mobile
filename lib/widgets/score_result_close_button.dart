import 'package:flutter/material.dart';

import '../localization/language_controller.dart';
import '../pre_assessment_completion_guard.dart';
import 'app_notification.dart';

/// The X button in the top-left corner of a Pre-Assessment Score Result
/// screen.
///
/// Visually identical to the plain close button it replaces — a 40x40 circle
/// carrying the module's own accent colors. What changed is the behaviour:
/// closing is an exit *after* the completion is confirmed saved, never a way
/// to cancel, undo or skip an already submitted Pre-Assessment.
///
/// On tap it:
///  1. confirms with Supabase that the submitted attempt is stored and that
///     the module progress record points at it (repairing the record from the
///     real attempt when it is out of sync) — see
///     [PreAssessmentCompletionGuard];
///  2. asks the Learning Materials / Modules tabs to re-fetch progress, which
///     the guard does by bumping `moduleProgressRefreshNotifier`;
///  3. returns to the Learning/Module screen the assessment was opened from.
///
/// Repeat taps while that is still running are ignored, and a failure keeps
/// the learner on the Score Result screen with the real error instead of
/// dropping the completion state.
class ScoreResultCloseButton extends StatefulWidget {
  const ScoreResultCloseButton({
    super.key,
    required this.moduleNo,
    required this.attemptId,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
  });

  /// Which module this Score Result belongs to (1-5).
  final int moduleNo;

  /// The `assessment_attempts` row this Score Result was built from.
  final String attemptId;

  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;

  @override
  State<ScoreResultCloseButton> createState() => _ScoreResultCloseButtonState();
}

class _ScoreResultCloseButtonState extends State<ScoreResultCloseButton> {
  bool _closing = false;

  Future<void> _handleClose() async {
    if (_closing) return;

    setState(() => _closing = true);

    try {
      await PreAssessmentCompletionGuard.confirmSaved(
        moduleNo: widget.moduleNo,
        attemptId: widget.attemptId,
      );

      if (!mounted) return;

      // Back to the Learning/Module screen this assessment was opened from.
      // That screen re-reads progress once this route is gone, and the guard
      // has already signalled the tabs to re-fetch.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      setState(() => _closing = false);

      await showAppDialog(
        context,
        title: t(
          context,
          'Could not confirm your result',
          'Hindi makumpirma ang iyong resulta',
        ),
        message: e is PreAssessmentNotSavedException ? e.message : '$e',
        type: AppNotificationType.error,
        accentColor: widget.iconColor,
        okText: t(context, 'OK', 'Sige'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _closing ? null : _handleClose,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: widget.borderColor),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.close_rounded,
          color: widget.iconColor,
          size: 22,
        ),
      ),
    );
  }
}
