import 'package:flutter/material.dart';

import '../localization/language_controller.dart';
import '../learning_materials.dart';
import 'module_2_learningmaterials.dart' as house_lm;

const Color kHouseOrange = Color(0xFFF97316);
const Color kHouseAmber = Color(0xFFF59E0B);
const Color kHouseOrangeSoft = Color(0xFFFFF7ED);
const Color kDarkText = Color(0xFF1F2937);
const Color kSoftBg = Color(0xFFF8FAFC);

class AppColors {
  // Module 2 House Fire palette
  static const Color brandRed = kHouseOrange;
  static const Color brandRedDark = Color(0xFFEA580C);
  static const Color brandRedDeep = kHouseAmber;
  static const Color brandRedLight = kHouseAmber;
  static const Color brandRedSoft = kHouseOrangeSoft;

  // Background Colors
  static const Color background = kSoftBg;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = kHouseOrangeSoft;

  // Text Colors
  static const Color textPrimary = kDarkText;
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnRed = Color(0xFFFFFFFF);

  // Borders / Dividers
  static const Color border = Color(0xFFF1D8C5);
  static const Color divider = Color(0xFFFDEAD7);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = kHouseAmber;
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2563EB);

  // Buttons
  static const Color primaryButton = kHouseOrange;
  static const Color primaryButtonPressed = Color(0xFFEA580C);
  static const Color secondaryButton = kHouseOrangeSoft;

  // Shadows
  static const Color shadow = Color(0x1A000000);
}

class PreAssessmentCompletionPage1 extends StatelessWidget {
  const PreAssessmentCompletionPage1({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.assessmentTitle,
  });

  final int score;
  final int totalQuestions;
  final String assessmentTitle;

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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (assessmentTitle.trim().isNotEmpty) ...[
                      Text(
                        t(
                          context,
                          'Pre-Assessment',
                          'Paunang Pagsusulit',
                        ).toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandRed,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    _ScoreGauge(
                      score: score,
                      totalQuestions: totalQuestions,
                      percent: percent,
                      progressValue: progressValue,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      t(
                        context,
                        'Pre-Assessment Complete!',
                        'Tapos na ang Paunang Pagsusulit!',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 26,
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
                        'Great work! Your result is saved and Module 2 is now ready for you.',
                        'Magaling! Naitala na ang iyong resulta at handa na ang Modyul 2 para sa iyo.',
                      ),
                      textAlign: TextAlign.center,
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
                          label: t(context, 'Score Saved', 'Naitala ang Marka'),
                        ),
                        _InfoChip(
                          icon: Icons.menu_book_rounded,
                          label: t(
                            context,
                            'Module 2 Unlocked',
                            'Bukas na ang Modyul 2',
                          ),
                        ),
                      ],
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
                          foregroundColor: const WidgetStatePropertyAll<Color>(
                            AppColors.textOnRed,
                          ),
                          elevation: const WidgetStatePropertyAll<double>(8),
                          shadowColor: WidgetStatePropertyAll<Color>(
                            AppColors.brandRed.withValues(alpha: 0.30),
                          ),
                          shape: WidgetStatePropertyAll<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const house_lm.LearningMaterialHousePage(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.textOnRed,
                              size: 21,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                t(
                                  context,
                                  'Proceed to Learning Materials',
                                  'Magpatuloy sa Modyul sa Pag-aaral',
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

  void _closeToLearningMaterials(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class PreAssessmentCompletionPage extends PreAssessmentCompletionPage1 {
  const PreAssessmentCompletionPage({
    super.key,
    required int score,
    required int totalQuestions,
    required String assessmentTitle,
  }) : super(
          score: score,
          totalQuestions: totalQuestions,
          assessmentTitle: assessmentTitle,
        );
}

class _ScoreGauge extends StatelessWidget {
  const _ScoreGauge({
    required this.score,
    required this.totalQuestions,
    required this.percent,
    required this.progressValue,
  });

  final int score;
  final int totalQuestions;
  final int percent;
  final double progressValue;

  @override
  Widget build(BuildContext context) {
    const double size = 190;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 14,
              valueColor: AlwaysStoppedAnimation<Color>(
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
                Icons.check_rounded,
                color: AppColors.textOnRed,
                size: 22,
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
