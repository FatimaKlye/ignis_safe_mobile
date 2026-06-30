import 'package:flutter/material.dart';
import '../localization/app_text.dart';
import 'post_assessment_electrical.dart';
import 'module_progression_service.dart';

/// Helper to get localized text based on context language
String _getLocalizedText(String en, String tl, BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
}

/// Returns the assessment display title with proper localization
String getAssessmentDisplayTitle(BuildContext context) {
  return _getLocalizedText(
    'Post-Assessment',
    'Panghuling Pagsusulit',
    context,
  );
}

/// Returns the concise instructions list with proper localization
List<String> getConciseInstructions(BuildContext context) {
  return [
    _getLocalizedText(
      'Answer each question based on what you learned from the Learning Materials.',
      'Sagutan ang bawat tanong batay sa natutunan mo sa Modyul sa Pag-aaral.',
      context,
    ),
    _getLocalizedText(
      'You have 5 minutes to complete the post-test.',
      'Mayroon kang 5 minuto para matapos ang panghuling pagsusulit.',
      context,
    ),
    _getLocalizedText(
      'Unanswered questions will be marked incorrect when time runs out.',
      'Ang hindi nasagutang tanong ay mamarkahang mali kapag naubos ang oras.',
      context,
    ),
    _getLocalizedText(
      'Your score will show how well you understood Module 3.',
      'Ipapakita ng iyong score kung gaano mo naunawaan ang Modyul 3.',
      context,
    ),
  ];
}

class PostAssessmentIntroPage extends StatefulWidget {
  const PostAssessmentIntroPage({super.key});

  @override
  State<PostAssessmentIntroPage> createState() => _PostAssessmentIntroPageState();
}

class _PostAssessmentIntroPageState extends State<PostAssessmentIntroPage> {
  bool _checkingAccess = false;

  Future<void> _startPostAssessment() async {
    if (_checkingAccess) return;

    setState(() => _checkingAccess = true);

    try {
      await ModuleProgressionService().ensureCanStartPostTest(moduleNo: 3);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PostAssessmentElectricalPage(),
        ),
      );
    } on ProgressionAccessDenied catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _getLocalizedText(
              'Post-Assessment Locked',
              'Naka-lock ang Panghuling Pagsusulit',
              context,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_getLocalizedText('OK', 'Sige', context)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _getLocalizedText(
              'Post-Assessment Locked',
              'Naka-lock ang Panghuling Pagsusulit',
              context,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_getLocalizedText('OK', 'Sige', context)),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingAccess = false);
      }
    }
  }

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textOnRed.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.textOnRed.withOpacity(0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.electrical_services_rounded,
                              color: AppColors.textOnRed,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.tr('module_3'),
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
                          context.tr('module_3_full_header'),
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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 26,
                                offset: const Offset(0, 12),
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
                                          AppColors.brandRed,
                                          AppColors.brandRedDark,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.brandRed.withOpacity(0.28),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.fact_check_rounded,
                                      color: AppColors.textOnRed,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isTl
                                              ? 'Handa ka na bang sukatin ang iyong natutunan?'
                                              : 'Ready to check your learning?',
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
                                              ? 'Sagutan ang panghuling pagsusulit matapos basahin ang Modyul 3 sa Pag-aaral. Susukatin nito kung ano ang natutunan mo tungkol sa sanhi ng sunog sa kuryente, ligtas na aksyon, at pag-iwas.'
                                              : 'Take this post-assessment after reading the Module 3 Learning Materials. This will help identify what you learned about electrical fire causes, safe actions, and prevention.',
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 141, 27, 27),
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
                              const SizedBox(height: 18),
                              Text(
                                context.tr('module_3_full_title'),
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
                                  // Use a slightly larger breakpoint for medium phones
                                  final compact = constraints.maxWidth < 360;
                                  // Calculate sensible tile width for multi-column or single-column
                                  final tileWidth = compact
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 20) / 3;
                                  return Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _IntroInfoTile(
                                        compact: compact,
                                        width: tileWidth.clamp(120.0, constraints.maxWidth),
                                        icon: Icons.dynamic_form_rounded,
                                        title: isTl ? 'Mga tanong' : 'Questions',
                                        value: isTl
                                            ? 'Mula sa Bureau of Fire Protection DASMARIÑAS'
                                            : 'From Bureau of Fire Protection DASMARIÑAS',
                                      ),
                                      _IntroInfoTile(
                                        compact: compact,
                                        width: tileWidth.clamp(100.0, constraints.maxWidth),
                                        icon: Icons.schedule_rounded,
                                        title: isTl ? 'Oras' : 'Time',
                                        value: '5 mins',
                                      ),
                                      _IntroInfoTile(
                                        compact: compact,
                                        width: tileWidth.clamp(120.0, constraints.maxWidth),
                                        icon: Icons.school_rounded,
                                        title: isTl ? 'Uri' : 'Type',
                                        value: isTl ? 'Panghuling Pagsusulit' : 'Post-Test',
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
                                  border: Border.all(
                                    color: AppColors.border,
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
                                            color: AppColors.brandRedSoft,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.lightbulb_outline_rounded,
                                            color: AppColors.brandRed,
                                            size: 18,
                                          ),
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
                                    _InstructionLine(
                                      text: isTl
                                          ? 'Sagutan ang bawat tanong batay sa natutunan mo sa Modyul sa Pag-aaral.'
                                          : 'Answer each question based on what you learned from the Learning Materials.',
                                    ),
                                    _InstructionLine(
                                      text: isTl
                                          ? 'Mayroon kang 5 minuto para matapos ang panghuling pagsusulit.'
                                          : 'You have 5 minutes to complete the post-test.',
                                    ),
                                    _InstructionLine(
                                      text: isTl
                                          ? 'Ang hindi nasagutang tanong ay mamarkahang mali kapag naubos ang oras.'
                                          : 'Unanswered questions will be marked incorrect when time runs out.',
                                    ),
                                    _InstructionLine(
                                      text: isTl
                                          ? 'Ipapakita ng iyong score kung gaano mo naunawaan ang Modyul 3.'
                                          : 'Your score will show how well you understood Module 3.',
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
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _checkingAccess
                ? null
                : () {
                    _startPostAssessment();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryButton,
              elevation: 8,
              shadowColor: AppColors.primaryButton.withOpacity(0.35),
              minimumSize: const Size.fromHeight(56),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    isTl
                        ? 'Simulan ang Panghuling Pagsusulit'
                        : 'Start Post-Test',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textOnRed,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
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
            AppColors.brandRedDeep,
            AppColors.brandRedDark,
            AppColors.brandRed,
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
        color: AppColors.textOnRed.withOpacity(opacity),
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
          color: AppColors.textOnRed.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textOnRed.withOpacity(0.24),
          ),
        ),
        child: Icon(icon, color: AppColors.textOnRed, size: 22),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.brandRedSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.brandRed, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Poppins',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                    fontSize: 12.0,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.brandRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
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