import 'package:flutter/material.dart';

import 'pre_assessment_kitchen.dart';
import 'simulation_scene.dart';

class PreAssessmentCompletionPage2 extends StatelessWidget {
  const PreAssessmentCompletionPage2({
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
    final isTl = Localizations.localeOf(context).languageCode == 'tl';
    String t(String en, String tl) => isTl ? tl : en;
    final percent = totalQuestions == 0 ? 0 : ((score / totalQuestions) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _CompletionGradientHeader(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactWidth = constraints.maxWidth < 360;
                final horizontalPadding = compactWidth ? 18.0 : 24.0;
                final cardPadding = compactWidth ? 18.0 : 24.0;
                final iconSize = compactWidth ? 82.0 : 94.0;

                return Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(cardPadding, compactWidth ? 22 : 26, cardPadding, 22),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: AppColors.border),
                          boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 32, offset: Offset(0, 18))],
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
                                  colors: [AppColors.brandRedDeep, AppColors.brandRedDark, AppColors.brandRed],
                                ),
                                boxShadow: [BoxShadow(color: AppColors.brandRed.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 10))],
                              ),
                              child: Icon(Icons.check_circle_rounded, color: AppColors.textOnRed, size: compactWidth ? 44 : 50),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              t('Pre-Assessment Completed', 'Nakumpleto ang Paunang Pagsusulit'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: compactWidth ? 23 : 27,
                                height: 1.15,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t('You have completed the Module 4 Pre-Assessment.', 'Natapos mo na ang Paunang Pagsusulit ng Modyul 4.'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14.5, height: 1.4, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                            ),
                            if (assessmentTitle.trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                assessmentTitle.trim(),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                              ),
                            ],
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(compactWidth ? 16 : 18),
                              decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
                              child: Column(
                                children: [
                                  const Icon(Icons.insights_rounded, color: AppColors.brandRed, size: 34),
                                  const SizedBox(height: 12),
                                  Text(t('Initial Score', 'Panimulang Iskor'), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                                  const SizedBox(height: 6),
                                  Text('$score / $totalQuestions', style: const TextStyle(fontFamily: 'Poppins', fontSize: 34, height: 1.0, fontWeight: FontWeight.w900, color: AppColors.brandRedDeep)),
                                  const SizedBox(height: 4),
                                  Text('$percent%', style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brandRed)),
                                  const SizedBox(height: 12),
                                  Text(
                                    t('This pre-assessment is not graded. It only checks your knowledge before the kitchen fire lesson.', 'Hindi binibigyan ng grado ang paunang pagsusulit na ito. Sinusukat lamang nito ang kaalaman mo bago ang aralin tungkol sa sunog sa kusina.'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, height: 1.45, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryButton, elevation: 8, shadowColor: AppColors.primaryButton.withOpacity(0.35), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                                onPressed: () {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SimulationScene4()));
                                },
                                child: Text(t('Proceed to Simulation', 'Magpatuloy sa Simulasyon'), style: const TextStyle(color: AppColors.textOnRed, fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w900)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brandRed), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                                onPressed: () {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PreAssessmentKitchenPage()));
                                },
                                child: Text(t('Retake Pre-Test', 'Ulitin ang Paunang Pagsusulit'), style: const TextStyle(color: AppColors.brandRed, fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

class _CompletionGradientHeader extends StatelessWidget {
  const _CompletionGradientHeader();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppColors.background),
        Container(
          height: 280,
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.brandRedDeep, AppColors.brandRedDark, AppColors.brandRed]),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(34), bottomRight: Radius.circular(34)),
          ),
        ),
        const Positioned(top: 48, right: -38, child: _HeaderGlow(size: 142, opacity: 0.17)),
        const Positioned(top: 168, left: -44, child: _HeaderGlow(size: 124, opacity: 0.13)),
      ],
    );
  }
}

class _HeaderGlow extends StatelessWidget {
  const _HeaderGlow({required this.size, required this.opacity});
  final double size;
  final double opacity;
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: AppColors.textOnRed.withOpacity(opacity), shape: BoxShape.circle));
  }
}
