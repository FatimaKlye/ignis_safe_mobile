import 'package:flutter/material.dart';
import '../localization/app_text.dart';
import 'pre_assessment_kitchen.dart';

String _getLocalizedText(String en, String tl, BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
}

String getAssessmentDisplayTitle(BuildContext context) {
  return _getLocalizedText(
    'Pre-Assessment',
    'Paunang Pagsusulit',
    context,
  );
}

List<String> getConciseInstructions(BuildContext context) {
  return [
    _getLocalizedText(
      'Answer based on what you currently know before studying the module.',
      'Sagutan batay sa kasalukuyan mong alam bago aralin ang modyul.',
      context,
    ),
    _getLocalizedText(
      'You have 5 minutes to complete the pre-test.',
      'Mayroon kang 5 minuto para matapos ang paunang pagsusulit.',
      context,
    ),
    _getLocalizedText(
      'Unanswered questions will be marked incorrect when time runs out.',
      'Ang hindi nasagutang tanong ay mamarkahang mali kapag naubos ang oras.',
      context,
    ),
    _getLocalizedText(
      'This is not graded. It checks your starting knowledge for Module 4.',
      'Hindi ito binibigyan ng grado. Sinusukat lamang nito ang panimulang kaalaman mo para sa Modyul 4.',
      context,
    ),
  ];
}

class PreAssessmentIntroPage2 extends StatelessWidget {
  const PreAssessmentIntroPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _IntroGradientHeader(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.textOnRed.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.textOnRed.withOpacity(0.22)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded, color: AppColors.textOnRed, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('module_4'),
                              style: const TextStyle(
                                color: AppColors.textOnRed,
                                fontFamily: 'Poppins',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            getAssessmentDisplayTitle(context),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textOnRed,
                              fontFamily: 'Poppins',
                              fontSize: 30,
                              height: 1.12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('module_4_full_header'),
                          style: TextStyle(
                            color: AppColors.textOnRed.withOpacity(0.88),
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(color: AppColors.shadow, blurRadius: 30, offset: Offset(0, 18)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.brandRed, AppColors.brandRedDark],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(color: AppColors.brandRed.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 8)),
                                      ],
                                    ),
                                    child: const Icon(Icons.quiz_rounded, color: AppColors.textOnRed, size: 30),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isTl ? 'Handa ka na bang magsimula?' : 'Ready to begin?',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontFamily: 'Poppins',
                                            fontSize: 22,
                                            height: 1.18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          isTl
                                              ? 'Sagutan muna ang paunang pagsusulit bago aralin ang Modyul 4. Susukatin nito ang kasalukuyan mong kaalaman tungkol sa sunog sa kusina, mga sanhi, pag-iwas, at tamang pagtugon.'
                                              : 'Take this pre-assessment before studying Module 4. This checks what you already know about kitchen fire basics, causes, prevention, and proper emergency response.',
                                          style: const TextStyle(
                                            color: AppColors.brandRedDeep,
                                            fontFamily: 'Poppins',
                                            fontSize: 13.5,
                                            height: 1.38,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              Text(
                                context.tr('module_4_full_title'),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Poppins',
                                  fontSize: 15.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 18),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 330;
                                  return Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _IntroInfoTile(
                                        compact: compact,
                                        width: compact ? constraints.maxWidth : 138,
                                        icon: Icons.dynamic_form_rounded,
                                        title: isTl ? 'Mga tanong' : 'Questions',
                                        value: isTl ? 'Mula sa BFP Dasmariñas' : 'From BFP Dasmariñas',
                                      ),
                                      _IntroInfoTile(
                                        compact: compact,
                                        width: compact ? constraints.maxWidth : 138,
                                        icon: Icons.schedule_rounded,
                                        title: isTl ? 'Oras' : 'Time',
                                        value: '5 mins',
                                      ),
                                      _IntroInfoTile(
                                        compact: compact,
                                        width: compact ? constraints.maxWidth : 138,
                                        icon: Icons.school_rounded,
                                        title: isTl ? 'Uri' : 'Type',
                                        value: isTl ? 'Paunang Pagsusulit' : 'Pre-Test',
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 22),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.brandRedSoft,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.brandRed, size: 18),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          isTl ? 'Mga Panuto' : 'Instructions',
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontFamily: 'Poppins',
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 13),
                                    ...getConciseInstructions(context).map((text) => _InstructionLine(text: text)),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PreAssessmentKitchenPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              elevation: 8,
              shadowColor: AppColors.primaryButton.withOpacity(0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isTl ? 'Simulan ang Paunang Pagsusulit' : 'Start Pre-Test',
                  style: const TextStyle(
                    color: AppColors.textOnRed,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: AppColors.textOnRed, size: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroGradientHeader extends StatelessWidget {
  const _IntroGradientHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 315,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandRedDeep, AppColors.brandRedDark, AppColors.brandRed],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(34), bottomRight: Radius.circular(34)),
      ),
      child: const Stack(
        children: [
          Positioned(right: -34, top: 46, child: _GlowCircle(size: 140, opacity: 0.18)),
          Positioned(left: -42, top: 158, child: _GlowCircle(size: 120, opacity: 0.14)),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: AppColors.textOnRed.withOpacity(opacity), shape: BoxShape.circle),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.textOnRed.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textOnRed.withOpacity(0.24)),
        ),
        child: Icon(icon, color: AppColors.textOnRed, size: 22),
      ),
    );
  }
}

class _IntroInfoTile extends StatelessWidget {
  const _IntroInfoTile({required this.compact, required this.width, required this.icon, required this.title, required this.value});
  final bool compact;
  final double width;
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: AppColors.brandRedSoft, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.brandRed, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins', fontSize: 11.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 12.5, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionLine extends StatelessWidget {
  const _InstructionLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(margin: const EdgeInsets.only(top: 6), width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.brandRed, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins', fontSize: 13.5, height: 1.42, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
