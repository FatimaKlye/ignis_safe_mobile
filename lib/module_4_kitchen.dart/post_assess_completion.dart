import 'package:flutter/material.dart';

import '../localization/language_controller.dart';
import '../learning_materials.dart';

class AppColors {
  // Module 4 Kitchen Fire amber/orange palette
  static const Color brandRed = Color(0xFFF59E0B);
  static const Color brandRedDark = Color(0xFFD97706);
  static const Color brandRedDeep = Color(0xFF92400E);
  static const Color brandRedLight = Color(0xFFFBBF24);
  static const Color brandRedSoft = Color(0xFFFFFBEB);

  // Background Colors
  static const Color background = Color(0xFFFFFBF2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFFF7ED);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnRed = Color(0xFFFFFFFF);

  // Borders / Dividers
  static const Color border = Color(0xFFFDE68A);
  static const Color divider = Color(0xFFFEF3C7);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2563EB);

  // Buttons
  static const Color primaryButton = Color(0xFFF59E0B);
  static const Color primaryButtonPressed = Color(0xFFD97706);
  static const Color secondaryButton = Color(0xFFFFFBEB);

  // Shadows
  static const Color shadow = Color(0x1A000000);
}

class PostAssessmentCompletionPage extends StatelessWidget {
  const PostAssessmentCompletionPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.assessmentTitle,
    this.onFinish,
  });

  final int score;
  final int totalQuestions;
  final String assessmentTitle;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final percent =
        totalQuestions == 0 ? 0 : ((score / totalQuestions) * 100).round();
    final progressValue = totalQuestions <= 0
        ? 0.0
        : (score / totalQuestions).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactWidth = constraints.maxWidth < 370;
                final compactHeight = constraints.maxHeight < 690;
                final horizontalPadding = compactWidth ? 20.0 : 28.0;
                final topGap = compactHeight ? 14.0 : 20.0;
                final gaugeSize = compactWidth ? 164.0 : 190.0;
                final titleSize = compactWidth ? 22.0 : 26.0;
                final headerSize = compactWidth ? 18.0 : 22.0;

                return Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topGap,
                      horizontalPadding,
                      28,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t(
                              context,
                              'Post-Assessment',
                              'Panghuling Pagsusulit',
                            ).toUpperCase(),
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: headerSize,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              color: AppColors.brandRed,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _ScoreGauge(
                            score: score,
                            totalQuestions: totalQuestions,
                            percent: percent,
                            progressValue: progressValue,
                            size: gaugeSize,
                          ),
                          const SizedBox(height: 30),
                          Text(
                            t(
                              context,
                              'Post-Assessment Completed!',
                              'Tapos na ang Panghuling Pagsusulit!',
                            ),
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: titleSize,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            t(
                              context,
                              'You have completed the Module 4 Post-Assessment.',
                              'Natapos mo na ang Panghuling Pagsusulit ng Modyul 4.',
                            ),
                            textAlign: TextAlign.center,
                            softWrap: true,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              height: 1.45,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _InfoChip(
                                icon: Icons.check_circle_rounded,
                                label: t(
                                  context,
                                  'Score Recorded',
                                  'Naitala ang Marka',
                                ),
                              ),
                              _InfoChip(
                                icon: Icons.emoji_events_rounded,
                                label: t(
                                  context,
                                  'Module Completed',
                                  'Nakumpleto ang Modyul',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              t(
                                context,
                                'Congratulations! Your score shows how well you understood the Module 4 Learning Materials.',
                                'Binabati ka namin! Ipinapakita ng iyong score kung gaano mo naunawaan ang Modyul 4 sa Pag-aaral.',
                              ),
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.brandRedSoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.brandRed,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t(
                                      context,
                                      'Your post-assessment result has been recorded. This score helps identify what you learned about kitchen fire basics, common causes, prevention, and proper emergency response.',
                                      'Naitala na ang iyong resulta sa panghuling pagsusulit. Ang score na ito ay tumutulong matukoy kung ano ang natutunan mo tungkol sa batayan ng sunog sa kusina, mga karaniwang sanhi, pag-iwas, at tamang pagtugon sa emerhensiya.',
                                    ),
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13.5,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.brandRedSoft,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.view_in_ar_rounded,
                                    color: AppColors.brandRed,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t(
                                      context,
                                      'You can also try the 3D Simulation to view the lesson in a clearer and more interactive way.',
                                      'Maaari mo ring subukan ang 3D Simulation upang makita ang aralin sa mas malinaw at interactive na paraan.',
                                    ),
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13.5,
                                      height: 1.45,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                minimumSize: const WidgetStatePropertyAll<Size>(
                                  Size.fromHeight(56),
                                ),
                                padding: const WidgetStatePropertyAll<EdgeInsets>(
                                  EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                ),
                                backgroundColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                  (states) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return AppColors.primaryButtonPressed;
                                    }
                                    return AppColors.primaryButton;
                                  },
                                ),
                                foregroundColor:
                                    const WidgetStatePropertyAll<Color>(
                                  AppColors.textOnRed,
                                ),
                                elevation:
                                    const WidgetStatePropertyAll<double>(8),
                                shadowColor: WidgetStatePropertyAll<Color>(
                                  AppColors.brandRed.withValues(alpha: 0.30),
                                ),
                                shape: WidgetStatePropertyAll<OutlinedBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                              onPressed: () => _finishModule(context),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.done_all_rounded,
                                    color: AppColors.textOnRed,
                                    size: 21,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      t(
                                        context,
                                        'Finish Module',
                                        'Tapusin ang Modyul',
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textOnRed,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15.5,
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
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: _CloseIconButton(
                  onTap: () => _closeToLearningMaterials(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finishModule(BuildContext context) {
    if (onFinish != null) {
      onFinish!();
      return;
    }

    _closeToLearningMaterials(context);
  }

  void _closeToLearningMaterials(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LearningMaterialsTab()),
      (route) => false,
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({
    required this.score,
    required this.totalQuestions,
    required this.percent,
    required this.progressValue,
    required this.size,
  });

  final int score;
  final int totalQuestions;
  final int percent;
  final double progressValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 14,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brandRedSoft,
              ),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progressValue,
              strokeWidth: 14,
              strokeCap: StrokeCap.round,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brandRed,
              ),
            ),
          ),
          Container(
            width: size - 40,
            height: size - 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t(context, 'out of $totalQuestions', 'sa $totalQuestions'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandRedSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$percent%',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandRedDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandRed,
                border: Border.all(color: AppColors.surface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandRed.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.textOnRed,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.brandRed),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CloseIconButton extends StatelessWidget {
  const _CloseIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.close_rounded,
          color: AppColors.brandRed,
          size: 22,
        ),
      ),
    );
  }
}
