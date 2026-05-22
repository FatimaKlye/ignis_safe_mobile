import 'package:flutter/material.dart';

import '../localization/language_controller.dart';
import 'module_1_learningmaterials.dart';

class AppColors {
  // Main Brand Colors
  static const Color brandRed = Color(0xFFB11217);
  static const Color brandRedDark = Color(0xFF7A1014);
  static const Color brandRedDeep = Color(0xFF4E070A);
  static const Color brandRedLight = Color(0xFFE64A4F);
  static const Color brandRedSoft = Color(0xFFFFE8EA);

  // Background Colors
  static const Color background = Color(0xFFFFF7F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFFF1F2);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF9A9A9A);
  static const Color textOnRed = Color(0xFFFFFFFF);

  // Borders / Dividers
  static const Color border = Color(0xFFE8D8D9);
  static const Color divider = Color(0xFFF0E0E1);

  // Status Colors
  static const Color success = Color(0xFF198754);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2563EB);

  // Buttons
  static const Color primaryButton = brandRed;
  static const Color primaryButtonPressed = brandRedDark;
  static const Color secondaryButton = brandRedSoft;

  // Shadows
  static const Color shadow = Color(0x1A000000);
}

class PreAssessmentCompletionPage extends StatelessWidget {
  const PreAssessmentCompletionPage({
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
          const _CompletionGradientHeader(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 38),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 32,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 94,
                            height: 94,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.brandRedDeep,
                                  AppColors.brandRedDark,
                                  AppColors.brandRed,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brandRed.withOpacity(0.28),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.textOnRed,
                              size: 50,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            t(
                              context,
                              'Pre-Assessment Completed',
                              'Nakumpleto ang Paunang Pagsusulit',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 27,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t(
                              context,
                              '$assessmentTitle completed',
                              '$assessmentTitle',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.5,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  color: AppColors.brandRed,
                                  size: 34,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  t(
                                    context,
                                    'Congratulations! You can now proceed to Learning Materials.',
                                    'Binabati ka namin! Maaari ka nang magpatuloy sa Modyul sa Pag-aaral.',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    height: 1.45,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  t(context, 'Final Score', 'Panghuling Iskor'),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$score / $totalQuestions',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progressValue,
                                    minHeight: 10,
                                    backgroundColor: AppColors.brandRedSoft,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      AppColors.brandRed,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Text(
                                  '$percent%',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brandRedDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
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
                                      'Your pre-assessment result has been recorded. Continue to the learning materials to review the module content before moving to the next activity.',
                                      'Naitala na ang iyong resulta sa paunang pagsusulit. Magpatuloy sa modyul sa pag-aaral upang marepaso ang nilalaman bago pumunta sa susunod na gawain.',
                                    ),
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
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                minimumSize: const WidgetStatePropertyAll<Size>(
                                  Size.fromHeight(54),
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
                                  AppColors.brandRed.withOpacity(0.30),
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
                                    builder: (_) => LearningMaterialExtinguisherPage(),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.textOnRed,
                                    size: 21,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionGradientHeader extends StatelessWidget {
  const _CompletionGradientHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandRedDeep,
            AppColors.brandRedDark,
            AppColors.brandRed,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: const Stack(
        children: [
          Positioned(
            right: -40,
            top: 40,
            child: _HeaderGlow(size: 138, opacity: 0.18),
          ),
          Positioned(
            left: -28,
            top: 150,
            child: _HeaderGlow(size: 98, opacity: 0.14),
          ),
        ],
      ),
    );
  }
}

class _HeaderGlow extends StatelessWidget {
  const _HeaderGlow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.textOnRed.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
