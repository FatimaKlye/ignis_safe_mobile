import 'package:flutter/material.dart';

import '../localization/language_controller.dart';

class AppColors {
  // Module 2 House Fire palette
  static const Color brandRed = Color(0xFFF97316);
  static const Color brandRedDark = Color(0xFFEA580C);
  static const Color brandRedDeep = Color(0xFFF59E0B);
  static const Color brandRedLight = Color(0xFFF59E0B);
  static const Color brandRedSoft = Color(0xFFFFF7ED);

  // Background Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFFF7ED);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnRed = Color(0xFFFFFFFF);

  // Borders / Dividers
  static const Color border = Color(0xFFF1D8C5);
  static const Color divider = Color(0xFFFDEAD7);

  // Status Colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2563EB);

  // Buttons
  static const Color primaryButton = brandRed;
  static const Color primaryButtonPressed = brandRedDark;
  static const Color secondaryButton = brandRedSoft;

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
          const _CompletionGradientHeader(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactWidth = constraints.maxWidth < 370;
                final compactHeight = constraints.maxHeight < 690;
                final horizontalPadding = compactWidth ? 16.0 : 20.0;
                final topGap = compactHeight ? 22.0 : 38.0;
                final cardPadding = compactWidth ? 18.0 : 22.0;
                final iconSize = compactWidth ? 82.0 : 94.0;
                final titleSize = compactWidth ? 23.0 : 27.0;

                return Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      24,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: topGap),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(
                              cardPadding,
                              compactWidth ? 22 : 26,
                              cardPadding,
                              22,
                            ),
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
                                  width: iconSize,
                                  height: iconSize,
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
                                        color:
                                            AppColors.brandRed.withOpacity(0.28),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.textOnRed,
                                    size: compactWidth ? 44 : 50,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  t(
                                    context,
                                    'Post-Assessment Completed',
                                    'Nakumpleto ang Panghuling Pagsusulit',
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
                                const SizedBox(height: 8),
                                Text(
                                  t(
                                    context,
                                    'You have completed the Module 2 Post-Assessment.',
                                    'Natapos mo na ang Panghuling Pagsusulit ng Modyul 2.',
                                  ),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (assessmentTitle.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    assessmentTitle.trim(),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 22),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: compactWidth ? 14 : 18,
                                    vertical: compactWidth ? 18 : 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.emoji_events_rounded,
                                        color: AppColors.brandRed,
                                        size: 34,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        t(
                                          context,
                                          'Congratulations! Your score shows how well you understood the Module 2 Learning Materials.',
                                          'Binabati ka namin! Ipinapakita ng iyong score kung gaano mo naunawaan ang Modyul 2 sa Pag-aaral.',
                                        ),
                                        textAlign: TextAlign.center,
                                        softWrap: true,
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
                                  padding: EdgeInsets.all(compactWidth ? 16 : 18),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        t(
                                          context,
                                          'Final Score',
                                          'Panghuling Iskor',
                                        ),
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
                                          backgroundColor:
                                              AppColors.brandRedSoft,
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
                                  padding: EdgeInsets.all(compactWidth ? 14 : 16),
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
                                            'Your post-assessment result has been recorded. This score helps identify what you learned from the house fire safety and evacuation lesson.',
                                            'Naitala na ang iyong resulta sa panghuling pagsusulit. Ang score na ito ay tumutulong matukoy kung ano ang natutunan mo tungkol sa kaligtasan at paglikas sa panahon ng sunog sa bahay.',
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
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                      minimumSize:
                                          const WidgetStatePropertyAll<Size>(
                                        Size.fromHeight(54),
                                      ),
                                      padding:
                                          const WidgetStatePropertyAll<EdgeInsets>(
                                        EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                      ),
                                      backgroundColor:
                                          WidgetStateProperty.resolveWith<Color>(
                                        (states) {
                                          if (states
                                              .contains(WidgetState.pressed)) {
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
                                      shape:
                                          WidgetStatePropertyAll<OutlinedBorder>(
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
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.done_all_rounded,
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
                        ),
                      ],
                    ),
                  ),
                );
              },
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

    Navigator.of(context).popUntil((route) => route.isFirst);
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
