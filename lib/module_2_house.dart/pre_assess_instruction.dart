import 'package:flutter/material.dart';
import '../localization/app_text.dart';
import 'pre_assessment_house.dart';

String _localizedText(String en, String tl, BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
}

String _getAssessmentDisplayTitle(BuildContext context) {
  return _localizedText(
    'Pre-Assessment',
    'Paunang Pagsusulit',
    context,
  );
}

class PreAssessmentIntroPage2 extends StatelessWidget {
  const PreAssessmentIntroPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final isTl = Localizations.localeOf(context).languageCode == 'tl';

    return Scaffold(
      backgroundColor: _IntroAppColors.background,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _IntroAppColors.textOnRed.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: _IntroAppColors.textOnRed.withOpacity(0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.home_rounded,
                              color: _IntroAppColors.textOnRed,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('module_2'),
                              style: const TextStyle(
                                color: _IntroAppColors.textOnRed,
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
                            _getAssessmentDisplayTitle(context),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _IntroAppColors.textOnRed,
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
                          context.tr('module_2_full_header'),
                          style: TextStyle(
                            color: _IntroAppColors.textOnRed.withOpacity(0.88),
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
                            color: _IntroAppColors.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: _IntroAppColors.shadow,
                                blurRadius: 30,
                                offset: const Offset(0, 18),
                              ),
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
                                        colors: [
                                          _IntroAppColors.brandRed,
                                          _IntroAppColors.brandRedDark,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _IntroAppColors.brandRed
                                              .withOpacity(0.28),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.quiz_rounded,
                                      color: _IntroAppColors.textOnRed,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isTl
                                              ? 'Handa ka na ba?'
                                              : 'Ready to begin?',
                                          style: const TextStyle(
                                            color: _IntroAppColors.textPrimary,
                                            fontFamily: 'Poppins',
                                            fontSize: 22,
                                            height: 1.18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          isTl
                                              ? 'Sagutan muna ang paunang pagsusulit bago simulan ang aralin.'
                                              : 'Take this pre-assessment before starting the lesson.',
                                          style: const TextStyle(
                                            color:
                                                _IntroAppColors.textSecondary,
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
                                context.tr('module_2_full_title'),
                                style: const TextStyle(
                                  color: _IntroAppColors.textPrimary,
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
                                        width: compact
                                            ? constraints.maxWidth
                                            : 138,
                                        icon: Icons.dynamic_form_rounded,
                                        title:
                                            isTl ? 'Mga tanong' : 'Questions',
                                        value: isTl
                                            ? 'Mula sa Bureau of Fire Protection DASMARIÑAS'
                                            : 'From Bureau of Fire Protection DASMARIÑAS',
                                      ),
                                      _IntroInfoTile(
                                        compact: compact,
                                        width: compact
                                            ? constraints.maxWidth
                                            : 138,
                                        icon: Icons.schedule_rounded,
                                        title: isTl ? 'Oras' : 'Time',
                                        value: '5 mins',
                                      ),
                                      _IntroInfoTile(
                                        compact: compact,
                                        width: compact
                                            ? constraints.maxWidth
                                            : 138,
                                        icon: Icons.school_rounded,
                                        title: isTl ? 'Uri' : 'Type',
                                        value: 'Practice',
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
                                  color: _IntroAppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _IntroAppColors.border,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                _IntroAppColors.brandRedSoft,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.lightbulb_outline_rounded,
                                            color: _IntroAppColors.brandRed,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          isTl
                                              ? 'Bago ka magsimula'
                                              : 'Before you start',
                                          style: const TextStyle(
                                            color:
                                                _IntroAppColors.textPrimary,
                                            fontFamily: 'Poppins',
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 13),
                                    _InstructionLine(
                                      text: isTl
                                          ? 'Piliin ang pinakamainam na sagot sa bawat tanong.'
                                          : 'Choose the best answer for each question.',
                                    ),
                                    _InstructionLine(
                                      text: isTl
                                          ? 'Maaari mong balikan ang mga tanong bago ipasa.'
                                          : 'You can review your answers before submitting.',
                                    ),
                                    _InstructionLine(
                                      text: isTl
                                          ? 'Hindi graded ang pre-assessment na ito; gabay lamang ito sa pagkatuto.'
                                          : 'This pre-assessment is not graded; it is only used as a learning guide.',
                                    ),
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
                MaterialPageRoute(
                  builder: (_) => const PreAssessmentHousePage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _IntroAppColors.primaryButton,
              elevation: 8,
              shadowColor:
                  _IntroAppColors.primaryButton.withOpacity(0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isTl ? 'Simulan ang Pagsusulit' : 'Start Test',
                  style: const TextStyle(
                    color: _IntroAppColors.textOnRed,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: _IntroAppColors.textOnRed,
                  size: 21,
                ),
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
          colors: [
            _IntroAppColors.brandRedDeep,
            _IntroAppColors.brandRedDark,
            _IntroAppColors.brandRed,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: const Stack(
        children: [
          Positioned(
            right: -34,
            top: 46,
            child: _GlowCircle(size: 140, opacity: 0.18),
          ),
          Positioned(
            left: -42,
            top: 158,
            child: _GlowCircle(size: 120, opacity: 0.14),
          ),
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
      decoration: BoxDecoration(
        color: _IntroAppColors.textOnRed.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
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
          color: _IntroAppColors.textOnRed.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: _IntroAppColors.textOnRed.withOpacity(0.24),
          ),
        ),
        child: Icon(icon, color: _IntroAppColors.textOnRed, size: 22),
      ),
    );
  }
}

class _IntroInfoTile extends StatelessWidget {
  const _IntroInfoTile({
    required this.compact,
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
  });

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
        color: _IntroAppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _IntroAppColors.border),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _IntroAppColors.brandRedSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _IntroAppColors.brandRed, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _IntroAppColors.textMuted,
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _IntroAppColors.textPrimary,
                    fontFamily: 'Poppins',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
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
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: _IntroAppColors.brandRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _IntroAppColors.textSecondary,
                fontFamily: 'Poppins',
                fontSize: 13.5,
                height: 1.42,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const Color kHouseOrange = Color(0xFFF97316);
const Color kHouseAmber = Color(0xFFF59E0B);
const Color kHouseOrangeSoft = Color(0xFFFFF7ED);
const Color kDarkText = Color(0xFF1F2937);
const Color kSoftBg = Color(0xFFF8FAFC);

class _IntroAppColors {
  const _IntroAppColors._();

  // Module 2 House Fire palette
  static const Color brandRed = kHouseOrange;
  static const Color brandRedDark = kHouseOrange;
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
  static const Color primaryButtonPressed = kHouseAmber;
  static const Color secondaryButton = kHouseOrangeSoft;

  // Shadows
  static const Color shadow = Color(0x1A000000);
}