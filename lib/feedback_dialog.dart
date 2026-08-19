import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'feedback_service.dart';
import 'localization/language_controller.dart';
import 'widgets/app_notification.dart';

const Color _feedbackBrandRed = Color(0xFFB11217);
const Color _feedbackNavy = Color(0xFF142D57);

Future<void> showFeedbackDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (dialogContext) => const FeedbackDialog(),
  );
}

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _commentCtrl = TextEditingController();
  final _feedbackService = FeedbackService();

  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => _rating > 0 && !_isSubmitting;

  Future<void> _onSubmit() async {
    if (!_canSubmit) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      showAppNotification(
        context,
        message: t(
          context,
          'No active session. Please log in again.',
          'Walang aktibong session. Mangyaring mag-log in muli.',
        ),
        type: AppNotificationType.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _feedbackService.submitFeedback(
        userId: user.id,
        rating: _rating,
        comment: _commentCtrl.text,
      );

      if (!mounted) return;
      Navigator.pop(context);
      showAppNotification(
        context,
        message: t(
          context,
          'Thank you for your feedback!',
          'Salamat sa iyong feedback!',
        ),
        type: AppNotificationType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppNotification(
        context,
        message: t(
          context,
          'Could not submit your feedback. Please try again.',
          'Hindi naipadala ang feedback. Pakisubukang muli.',
        ),
        type: AppNotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: size.height * 0.82,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF9),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 34,
                spreadRadius: -5,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FeedbackHeader(
                title: t(context, 'Send Feedback', 'Magpadala ng Feedback'),
                subtitle: t(
                  context,
                  'Tell us how IGNIS SAFE is working for you',
                  'Sabihin sa amin kung paano gumagana ang IGNIS SAFE para sa iyo',
                ),
                onClose: _isSubmitting
                    ? null
                    : () => Navigator.pop(context),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t(
                          context,
                          'How would you rate your experience?',
                          'Paano mo ire-rate ang iyong karanasan?',
                        ),
                        style: const TextStyle(
                          color: _feedbackNavy,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: _StarRatingInput(
                          rating: _rating,
                          onChanged: _isSubmitting
                              ? null
                              : (value) => setState(() => _rating = value),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t(
                          context,
                          'Recommendation or comment (optional)',
                          'Rekomendasyon o komento (opsyonal)',
                        ),
                        style: const TextStyle(
                          color: _feedbackNavy,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F5F4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEDE8E5)),
                        ),
                        child: TextField(
                          controller: _commentCtrl,
                          enabled: !_isSubmitting,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 500,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3A3A3A),
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: t(
                              context,
                              'What did you like? What can we improve?',
                              'Ano ang nagustuhan mo? Ano ang maaari naming pahusayin?',
                            ),
                            hintStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                            contentPadding: const EdgeInsets.all(14),
                            counterStyle: TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey.shade500,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _canSubmit
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFC9232A),
                                      _feedbackBrandRed,
                                    ],
                                  )
                                : null,
                            color: _canSubmit ? null : const Color(0xFFE7E2DF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _canSubmit ? _onSubmit : null,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    t(context, 'Submit Feedback', 'Ipadala'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: _canSubmit
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackHeader extends StatelessWidget {
  const _FeedbackHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 10, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC9232A), _feedbackBrandRed, Color(0xFF861018)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Icon(
              Icons.star_rate_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            splashRadius: 20,
            tooltip: '',
          ),
        ],
      ),
    );
  }
}

class _StarRatingInput extends StatelessWidget {
  const _StarRatingInput({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final filled = starValue <= rating;

        return InkResponse(
          onTap: onChanged == null ? null : () => onChanged!(starValue),
          radius: 26,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              color: filled ? _feedbackBrandRed : const Color(0xFFC9C2BE),
              size: 38,
            ),
          ),
        );
      }),
    );
  }
}
