import 'package:flutter/material.dart';
import '../localization/app_text.dart';
import 'post_assessment_electrical.dart';
import 'module_progression_service.dart';
import '../learning_materials.dart' show LearningMaterialsTab;

/// Helper to get localized text based on context language
String _getLocalizedText(String en, String tl, BuildContext context) {
  return Localizations.localeOf(context).languageCode == 'tl' ? tl : en;
}

/// Returns the localized post-assessment locked message based on the raw
/// access-denied reason from ModuleProgressionService.
String _getLocalizedPostAssessmentAccessMessage(
  BuildContext context,
  String rawMessage,
) {
  final normalized = rawMessage.toLowerCase();

  if (normalized.contains('once') ||
      normalized.contains('already') ||
      normalized.contains('taken') ||
      normalized.contains('submitted')) {
    return _getLocalizedText(
      'You can only take the post-test once. Continue to the next module.',
      'Isang beses lang pwedeng sagutan ang Panghuling Pagsusulit. Magpatuloy sa susunod na modyul.',
      context,
    );
  }

  if (normalized.contains('pre-assessment')) {
    return _getLocalizedText(
      'Post-Assessment is locked. Complete and save the Pre-Assessment first.',
      'Naka-lock pa ang Panghuling Pagsusulit. Tapusin at i-save muna ang Paunang Pagsusulit.',
      context,
    );
  }

  if (normalized.contains('learning module')) {
    return _getLocalizedText(
      'Post-Assessment is locked. Finish the Learning Module first.',
      'Naka-lock pa ang Panghuling Pagsusulit. Tapusin muna ang Modyul sa Pag-aaral.',
      context,
    );
  }

  return rawMessage;
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
      await _showPostAssessmentAccessDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      await _showPostAssessmentAccessDialog(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _checkingAccess = false);
      }
    }
  }

  Future<void> _showPostAssessmentAccessDialog(String rawMessage) async {
    if (!context.mounted) return;

    final message = _getLocalizedPostAssessmentAccessMessage(context, rawMessage);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      color: AppColors.brandRedSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.brandRed,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _getLocalizedText(
                    'Post-Assessment Locked',
                    'Naka-lock ang Panghuling Pagsusulit',
                    context,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                    color: AppColors.brandRed,
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    height: 1.22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
                      foregroundColor: AppColors.textOnRed,
                      elevation: 8,
                      shadowColor: AppColors.brandRed.withOpacity(0.28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Text(
                      _getLocalizedText(
                        'I understand',
                        'Naiintindihan',
                        context,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                        onTap: () => Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LearningMaterialsTab(),
                          ),
                          (route) => false,
                        ),
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
                              softWrap: false,
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final veryTight = constraints.maxHeight < 560;
                        final tight = constraints.maxHeight < 625;
                        final titleSize = veryTight ? 24.0 : (tight ? 27.0 : 30.0);
                        final subtitleSize = veryTight ? 12.2 : (tight ? 13.0 : 14.0);
                        final titleGap = veryTight ? 5.0 : 7.0;
                        final cardGap = veryTight ? 11.0 : (tight ? 15.0 : 20.0);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              getAssessmentDisplayTitle(context),
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: TextStyle(
                                color: AppColors.textOnRed,
                                fontFamily: 'Poppins',
                                fontSize: titleSize,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(height: titleGap),
                            Text(
                              context.tr('module_3_full_header'),
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: TextStyle(
                                color: AppColors.textOnRed.withOpacity(0.88),
                                fontFamily: 'Poppins',
                                fontSize: subtitleSize,
                                height: 1.32,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: cardGap),
                            Expanded(
                              child: _AssessmentIntroCard(isTl: isTl),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 6, 20, 16),
        child: _SwipeStartButton(
          label: isTl
              ? 'Simulan ang Panghuling Pagsusulit'
              : 'Start Post-Test',
          onCompleted: _startPostAssessment,
        ),
      ),
    );
  }
}

class _AssessmentIntroCard extends StatefulWidget {
  const _AssessmentIntroCard({required this.isTl});

  final bool isTl;

  @override
  State<_AssessmentIntroCard> createState() => _AssessmentIntroCardState();
}

class _AssessmentIntroCardState extends State<_AssessmentIntroCard> {
  int _selectedGuide = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final veryTight = height < 500;
        final tight = height < 560;
        final compact = height < 635;
        final cardPadding = veryTight ? 12.0 : (tight ? 14.0 : (compact ? 16.0 : 18.0));
        final iconSize = veryTight ? 40.0 : (tight ? 46.0 : (compact ? 52.0 : 58.0));
        final headingSize = veryTight ? 17.0 : (tight ? 18.0 : (compact ? 20.0 : 22.0));
        final bodySize = veryTight ? 10.8 : (tight ? 11.6 : (compact ? 12.3 : 13.0));
        final sectionGap = veryTight ? 7.0 : (tight ? 9.0 : (compact ? 11.0 : 13.0));
        final miniGap = veryTight ? 6.0 : 8.0;
        final isTl = widget.isTl;

        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
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
                          color: AppColors.brandRed.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.fact_check_rounded,
                      color: AppColors.textOnRed,
                      size: veryTight ? 23 : (tight ? 26 : 30),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTl
                              ? 'Handa ka na bang sukatin ang iyong natutunan?'
                              : 'Ready to check your learning?',
                          softWrap: true,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                            fontSize: headingSize,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          isTl
                              ? 'Natapos mo na ang Modyul 3. I-tap ang gabay sa ibaba bago simulan ang panghuling pagsusulit.'
                              : 'You have completed Module 3. Tap a guide below before starting the post-assessment.',
                          softWrap: true,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                            fontSize: bodySize,
                            height: 1.34,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: sectionGap),
              _ModuleTitleBand(
                text: context.tr('module_3_full_title'),
                veryTight: veryTight,
                tight: tight,
              ),
              SizedBox(height: sectionGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MetricPill(
                      icon: Icons.schedule_rounded,
                      title: isTl ? 'Oras' : 'Time',
                      value: '5 mins',
                      compact: compact,
                      tight: tight,
                      veryTight: veryTight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricPill(
                      icon: Icons.school_rounded,
                      title: isTl ? 'Uri' : 'Type',
                      value: isTl ? 'Panghuling Pagsusulit' : 'Post-Test',
                      compact: compact,
                      tight: tight,
                      veryTight: veryTight,
                    ),
                  ),
                ],
              ),
              SizedBox(height: miniGap),
              _AssessmentSourceTile(
                icon: Icons.verified_rounded,
                title: isTl ? 'Pinagmulan ng tanong' : 'Question source',
                value: isTl
                    ? 'Bureau of Fire Protection DASMARIÑAS'
                    : 'Bureau of Fire Protection DASMARIÑAS',
                compact: compact,
                tight: tight,
                veryTight: veryTight,
              ),
              SizedBox(height: sectionGap),
              _GuideSelector(
                selectedIndex: _selectedGuide,
                isTl: isTl,
                compact: compact,
                tight: tight,
                veryTight: veryTight,
                onChanged: (index) {
                  setState(() {
                    _selectedGuide = index;
                  });
                },
              ),
              SizedBox(height: sectionGap),
              Expanded(
                child: _InteractiveGuidePanel(
                  selectedIndex: _selectedGuide,
                  isTl: isTl,
                  compact: compact,
                  tight: tight,
                  veryTight: veryTight,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuideSelector extends StatelessWidget {
  const _GuideSelector({
    required this.selectedIndex,
    required this.isTl,
    required this.compact,
    required this.tight,
    required this.veryTight,
    required this.onChanged,
  });

  final int selectedIndex;
  final bool isTl;
  final bool compact;
  final bool tight;
  final bool veryTight;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <_GuideTabData>[
      _GuideTabData(
        icon: Icons.psychology_alt_rounded,
        label: isTl ? 'Ano ito?' : 'What is it?',
      ),
      _GuideTabData(
        icon: Icons.touch_app_rounded,
        label: isTl ? 'Paano?' : 'How?',
      ),
      _GuideTabData(
        icon: Icons.lightbulb_outline_rounded,
        label: isTl ? 'Tandaan' : 'Remember',
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 7),
            child: _GuideTab(
              data: items[index],
              isSelected: selectedIndex == index,
              compact: compact,
              tight: tight,
              veryTight: veryTight,
              onTap: () => onChanged(index),
            ),
          ),
        );
      }),
    );
  }
}

class _GuideTabData {
  const _GuideTabData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _GuideTab extends StatelessWidget {
  const _GuideTab({
    required this.data,
    required this.isSelected,
    required this.compact,
    required this.tight,
    required this.veryTight,
    required this.onTap,
  });

  final _GuideTabData data;
  final bool isSelected;
  final bool compact;
  final bool tight;
  final bool veryTight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fontSize = veryTight ? 9.5 : (tight ? 10.1 : (compact ? 10.7 : 11.3));
    final verticalPadding = veryTight ? 7.0 : (tight ? 8.0 : 9.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: veryTight ? 6 : 8,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandRedSoft : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.brandRed.withOpacity(0.55) : AppColors.border,
              width: isSelected ? 1.3 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                data.icon,
                color: isSelected ? AppColors.brandRed : AppColors.textMuted,
                size: veryTight ? 16 : 18,
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  color: isSelected ? AppColors.brandRed : AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontSize: fontSize,
                  height: 1.13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveGuidePanel extends StatelessWidget {
  const _InteractiveGuidePanel({
    required this.selectedIndex,
    required this.isTl,
    required this.compact,
    required this.tight,
    required this.veryTight,
  });

  final int selectedIndex;
  final bool isTl;
  final bool compact;
  final bool tight;
  final bool veryTight;

  @override
  Widget build(BuildContext context) {
    final panel = _GuideContent.forIndex(selectedIndex, isTl);
    final titleSize = veryTight ? 13.4 : (tight ? 14.3 : (compact ? 15.2 : 16.2));
    final bodySize = veryTight ? 10.3 : (tight ? 11.0 : (compact ? 11.8 : 12.5));
    final bulletSize = veryTight ? 10.0 : (tight ? 10.6 : (compact ? 11.2 : 11.8));
    final panelPadding = veryTight ? 10.0 : (tight ? 12.0 : (compact ? 14.0 : 16.0));
    final itemGap = veryTight ? 5.0 : (tight ? 6.0 : 8.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Container(
        key: ValueKey<int>(selectedIndex),
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.all(panelPadding),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: veryTight ? 30 : (tight ? 33 : 37),
                          height: veryTight ? 30 : (tight ? 33 : 37),
                          decoration: BoxDecoration(
                            color: AppColors.brandRedSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            panel.icon,
                            color: AppColors.brandRed,
                            size: veryTight ? 16 : 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            panel.title,
                            softWrap: true,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontFamily: 'Poppins',
                              fontSize: titleSize,
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: itemGap),
                    Text(
                      panel.body,
                      softWrap: true,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                        fontSize: bodySize,
                        height: 1.33,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: itemGap),
                    ...panel.points.map(
                      (point) => _InstructionLine(
                        text: point,
                        fontSize: bulletSize,
                        bottomGap: itemGap,
                      ),
                    ),
                    SizedBox(height: veryTight ? 2 : 4),
                    _SwipeHint(
                      text: isTl
                          ? 'Kapag handa ka na, i-swipe ang button sa ibaba.'
                          : 'When ready, swipe the button below.',
                      fontSize: veryTight ? 9.8 : (tight ? 10.6 : 11.3),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GuideContent {
  const _GuideContent({
    required this.icon,
    required this.title,
    required this.body,
    required this.points,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String> points;

  static _GuideContent forIndex(int index, bool isTl) {
    switch (index) {
      case 1:
        return _GuideContent(
          icon: Icons.touch_app_rounded,
          title: isTl ? 'Paano ito sasagutan?' : 'How do you answer it?',
          body: isTl
              ? 'Basahin ang bawat tanong, piliin ang pinakaangkop na sagot, at isumite kapag tapos ka na.'
              : 'Read each question, choose the best answer, and submit when you are done.',
          points: isTl
              ? <String>[
                  'Sagutan ang bawat tanong batay sa natutunan mo sa Modyul sa Pag-aaral.',
                  'May 5 minuto ka para matapos ang panghuling pagsusulit.',
                  'Kapag naubos ang oras, ang hindi nasagutan ay mamamarkahang mali.',
                ]
              : <String>[
                  'Answer each question based on what you learned from the Learning Materials.',
                  'You have 5 minutes to finish the post-test.',
                  'When time runs out, unanswered items will be marked incorrect.',
                ],
        );
      case 2:
        return _GuideContent(
          icon: Icons.lightbulb_outline_rounded,
          title: isTl ? 'Mahalagang tandaan' : 'Important reminder',
          body: isTl
              ? 'Ang panghuling pagsusulit ay susukat kung gaano mo naunawaan ang Modyul 3 pagkatapos mong mag-aral.'
              : 'The post-assessment measures how well you understood Module 3 after studying the lesson.',
          points: isTl
              ? <String>[
                  'Isang beses lang ito masasagutan.',
                  'Ipapakita ng iyong score kung gaano mo naunawaan ang Modyul 3.',
                ]
              : <String>[
                  'You can answer this only once.',
                  'Your score will show how well you understood Module 3.',
                ],
        );
      default:
        return _GuideContent(
          icon: Icons.psychology_alt_rounded,
          title: isTl
              ? 'Ano ang panghuling pagsusulit?'
              : 'What is the post-assessment?',
          body: isTl
              ? 'Ito ay maikling pagsusulit matapos basahin ang Modyul 3 sa Pag-aaral.'
              : 'This is a short quiz after reading the Module 3 Learning Materials.',
          points: isTl
              ? <String>[
                  'Susukatin nito ang natutunan mo tungkol sa sanhi ng sunog sa kuryente, ligtas na aksyon, at pag-iwas.',
                  'Batay ang mga tanong sa Bureau of Fire Protection DASMARIÑAS.',
                ]
              : <String>[
                  'It checks what you learned about electrical fire causes, safe actions, and prevention.',
                  'The questions are based on the Bureau of Fire Protection DASMARIÑAS.',
                ],
        );
    }
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.text,
    required this.fontSize,
  });

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.swipe_rounded,
            color: AppColors.brandRed,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              softWrap: true,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
                fontSize: fontSize,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeStartButton extends StatefulWidget {
  const _SwipeStartButton({
    required this.label,
    required this.onCompleted,
  });

  final String label;
  final Future<void> Function() onCompleted;

  @override
  State<_SwipeStartButton> createState() => _SwipeStartButtonState();
}

class _SwipeStartButtonState extends State<_SwipeStartButton> {
  static const double _height = 62;
  static const double _thumbSize = 50;
  static const double _sidePadding = 6;

  double _dragX = 0;
  bool _draggingFromRight = false;
  bool _isCompleting = false;

  Future<void> _complete(double maxTravel) async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
      _dragX = _draggingFromRight ? 0 : maxTravel;
    });

    await widget.onCompleted();

    if (!mounted) return;
    setState(() {
      _isCompleting = false;
      _draggingFromRight = false;
      _dragX = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxTravel = constraints.maxWidth - _thumbSize - (_sidePadding * 2);
        final progress = maxTravel <= 0
            ? 0.0
            : (_dragX / maxTravel).clamp(0.0, 1.0).toDouble();

        return Semantics(
          button: true,
          label: widget.label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _isCompleting
                ? null
                : (details) {
                    setState(() {
                      _draggingFromRight =
                          details.localPosition.dx > constraints.maxWidth / 2;
                      _dragX = _draggingFromRight ? maxTravel : 0;
                    });
                  },
            onHorizontalDragUpdate: _isCompleting
                ? null
                : (details) {
                    setState(() {
                      _dragX = (_dragX + details.delta.dx)
                          .clamp(0.0, maxTravel)
                          .toDouble();
                    });
                  },
            onHorizontalDragEnd: _isCompleting
                ? null
                : (_) {
                    final completed = _draggingFromRight
                        ? _dragX <= maxTravel * 0.28
                        : _dragX >= maxTravel * 0.72;

                    if (completed) {
                      _complete(maxTravel);
                    } else {
                      setState(() {
                        _draggingFromRight = false;
                        _dragX = 0;
                      });
                    }
                  },
            child: Container(
              height: _height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryButton,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryButton.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: FractionallySizedBox(
                        alignment: _draggingFromRight
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        widthFactor: (0.16 + (progress * 0.84))
                            .clamp(0.16, 1.0)
                            .toDouble(),
                        child: Container(
                          color: AppColors.textOnRed.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 66),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        softWrap: false,
                        style: TextStyle(
                          color: AppColors.textOnRed.withOpacity(
                            _isCompleting ? 0.72 : 0.94,
                          ),
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: _isCompleting
                        ? const Duration(milliseconds: 140)
                        : const Duration(milliseconds: 60),
                    curve: Curves.easeOut,
                    left: _sidePadding + _dragX,
                    top: (_height - _thumbSize) / 2,
                    child: Container(
                      width: _thumbSize,
                      height: _thumbSize,
                      decoration: BoxDecoration(
                        color: AppColors.textOnRed.withOpacity(
                          0.80 + (progress * 0.16),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Icon(
                        _draggingFromRight
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        color: AppColors.primaryButton,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  const _GlowCircle({
    required this.size,
    required this.opacity,
  });

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
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

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
        child: Icon(
          icon,
          color: AppColors.textOnRed,
          size: 22,
        ),
      ),
    );
  }
}

class _ModuleTitleBand extends StatelessWidget {
  const _ModuleTitleBand({
    required this.text,
    required this.veryTight,
    required this.tight,
  });

  final String text;
  final bool veryTight;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: veryTight ? 10 : 12,
        vertical: veryTight ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        softWrap: true,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
          fontSize: veryTight ? 11.2 : (tight ? 12.2 : 13.4),
          height: 1.28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _AssessmentSourceTile extends StatelessWidget {
  const _AssessmentSourceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.compact,
    required this.tight,
    required this.veryTight,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool compact;
  final bool tight;
  final bool veryTight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: veryTight ? 9 : (tight ? 10 : 12),
        vertical: veryTight ? 7 : (tight ? 8 : (compact ? 9 : 11)),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniIconBox(
            icon: icon,
            size: veryTight ? 28 : (tight ? 30 : 34),
            iconSize: veryTight ? 15 : (tight ? 16 : 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  softWrap: true,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Poppins',
                    fontSize: veryTight ? 9.4 : (tight ? 10.2 : 11),
                    height: 1.18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  softWrap: true,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                    fontSize: veryTight ? 10.2 : (tight ? 10.9 : (compact ? 11.4 : 12.1)),
                    height: 1.25,
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

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.title,
    required this.value,
    required this.compact,
    required this.tight,
    required this.veryTight,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool compact;
  final bool tight;
  final bool veryTight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: veryTight ? 9 : (tight ? 10 : 12),
        vertical: veryTight ? 7 : (tight ? 8 : (compact ? 9 : 11)),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniIconBox(
            icon: icon,
            size: veryTight ? 28 : (tight ? 30 : 34),
            iconSize: veryTight ? 15 : (tight ? 16 : 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  softWrap: true,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Poppins',
                    fontSize: veryTight ? 9.3 : (tight ? 10.1 : 11),
                    height: 1.16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  softWrap: true,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                    fontSize: veryTight ? 10.3 : (tight ? 11.4 : (compact ? 12.0 : 12.8)),
                    height: 1.18,
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

class _MiniIconBox extends StatelessWidget {
  const _MiniIconBox({
    required this.icon,
    required this.size,
    required this.iconSize,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brandRedSoft,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color: AppColors.brandRed,
        size: iconSize,
      ),
    );
  }
}

class _InstructionLine extends StatelessWidget {
  const _InstructionLine({
    required this.text,
    required this.fontSize,
    required this.bottomGap,
  });

  final String text;
  final double fontSize;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.brandRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              softWrap: true,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
                fontSize: fontSize,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
