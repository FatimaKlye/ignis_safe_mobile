part of 'profile.dart';

Widget _buildModernProfileView(_ProfilePageState state, BuildContext context) {
  const brandRed = Color(0xFFB11217);
  final avatarImage = state._getAvatarImage();
  final trainingCompletedCount =
      int.tryParse(state._completedTrainingModules.split('/').first.trim()) ??
      0;
  final trainingProgress =
      (trainingCompletedCount / _ProfilePageState._totalSimulations).clamp(
        0.0,
        1.0,
      );

  Future<void> openEditProfile() => state._openModernEditProfile(context);

  return Scaffold(
    backgroundColor: const Color(0xFFF7F4F2),
    body: Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF9F6), Color(0xFFF6F7FA)],
                stops: [0.35, 1],
              ),
            ),
          ),
        ),
        const MainTabHeaderBackdrop(height: 330),
        SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactWidth = constraints.maxWidth < 370;
              final compactHeight = constraints.maxHeight < 700;
              final horizontalPadding = compactWidth ? 16.0 : 22.0;
              final topPadding = compactHeight ? 8.0 : 12.0;
              final bottomPadding = MediaQuery.paddingOf(context).bottom + 96;
              final sectionGap = compactHeight ? 14.0 : 23.0;
              final headingGap = compactHeight ? 16.0 : 24.0;
              final panelGap = compactHeight ? 8.0 : 12.0;

              // Header + overview card (training progress, recent activity)
              // stay pinned; everything from "Account & support" down scrolls.
              final stickyChildren = <Widget>[
                MainTabHeader(
                  greeting: state._displayName.trim().isEmpty
                      ? state._t(context, 'Welcome back', 'Mabuhay')
                      : state._t(
                          context,
                          'Hi, ${state._displayName.trim()}',
                          'Kumusta, ${state._displayName.trim()}',
                        ),
                  accountLabel: state._t(
                    context,
                    'Welcome to IGNIS SAFE',
                    'Mabuhay sa IGNIS SAFE',
                  ),
                  title: state._t(context, 'My Profile', 'Aking Profile'),
                  subtitle: state._t(
                    context,
                    'Manage your account and track your training.',
                    'Pamahalaan ang account at subaybayan ang training.',
                  ),
                  titleIcon: Icons.person_rounded,
                  avatarImage: avatarImage,
                  profileLabel: state._t(context, 'Profile', 'Profile'),
                  refreshLabel: state._t(
                    context,
                    'Refresh & Check Updates',
                    'I-refresh at Tingnan ang Updates',
                  ),
                  logoutLabel: state._t(context, 'Log Out', 'Mag-logout'),
                  onProfile: () {},
                  onLogout: state._logout,
                ),
                SizedBox(height: sectionGap),
                _ModernProfileOverviewCard(
                  compact: compactHeight,
                  avatarImage: avatarImage,
                  isLoading: state._isLoadingProfile,
                  displayName: state._displayName,
                  email: state._email,
                  location: '',
                  completedText: state._completedTrainingModules,
                  progress: trainingProgress,
                  lastSimulation: state._lastSimulation,
                  onEdit: openEditProfile,
                  accountLabel: state._t(
                    context,
                    'Active learner',
                    'Aktibong learner',
                  ),
                  progressLabel: state._t(
                    context,
                    'Training progress',
                    'Training progress',
                  ),
                  completedLabel: state._t(
                    context,
                    'modules completed',
                    'modyul ang natapos',
                  ),
                  recentLabel: state._t(
                    context,
                    'Recent activity',
                    'Huling activity',
                  ),
                  noActivityLabel: state._t(
                    context,
                    'No simulation yet',
                    'Wala pang simulation',
                  ),
                ),
              ];

              final scrollChildren = <Widget>[
                _AchievementButton(
                  medals: state._virtualMedals,
                  isLoading: state._isLoadingProfile,
                  onTap: () => _showMedalCollectionSheet(
                    context,
                    medals: state._virtualMedals,
                    isLoading: state._isLoadingProfile,
                  ),
                ),
                SizedBox(height: headingGap),
                _ModernProfileSectionHeading(
                  title: state._t(
                    context,
                    'Account & support',
                    'Account at suporta',
                  ),
                  subtitle: state._t(
                    context,
                    'Personalize your experience and get help.',
                    'I-personalize ang experience at humingi ng tulong.',
                  ),
                ),
                SizedBox(height: panelGap),
                _ModernProfileActionPanel(
                  children: [
                    _ModernProfileActionTile(
                      compact: compactHeight,
                      icon: Icons.location_on_rounded,
                      title: state._t(
                        context,
                        'Registered location',
                        'Nakarehistrong lokasyon',
                      ),
                      subtitle: state._locationLabel.isEmpty
                          ? state._t(
                              context,
                              'Not recorded for this account',
                              'Walang nakatalang lokasyon sa account',
                            )
                          : state._locationLabel,
                      color: const Color(0xFF142D57),
                      showChevron: false,
                      onTap: () => _showRegisteredLocationInfo(
                        context,
                        state._locationLabel,
                      ),
                    ),
                    const _ModernProfileActionDivider(),
                    _ModernProfileActionTile(
                      compact: compactHeight,
                      icon: Icons.manage_accounts_outlined,
                      title: state._t(
                        context,
                        'Edit Profile',
                        'I-edit ang Profile',
                      ),
                      subtitle: state._t(
                        context,
                        'Update your photo, name, or password',
                        'Baguhin ang larawan, pangalan, o password',
                      ),
                      onTap: openEditProfile,
                    ),
                    const _ModernProfileActionDivider(),
                    _ModernProfileActionTile(
                      compact: compactHeight,
                      icon: Icons.language_rounded,
                      title: state._t(context, 'Language', 'Wika'),
                      subtitle: context
                          .watch<LanguageController>()
                          .currentLanguageName,
                      color: const Color(0xFF142D57),
                      onTap: () => showLanguagePicker(context),
                    ),
                    const _ModernProfileActionDivider(),
                    _ModernProfileActionTile(
                      compact: compactHeight,
                      icon: Icons.help_outline_rounded,
                      title: state._t(context, 'Help & FAQ', 'Tulong at FAQ'),
                      subtitle: state._t(
                        context,
                        'Find quick answers about IGNIS SAFE',
                        'Makahanap ng mabilis na sagot tungkol sa IGNIS SAFE',
                      ),
                      color: const Color(0xFF142D57),
                      onTap: () => showFAQDialog(context),
                    ),
                    const _ModernProfileActionDivider(),
                    _ModernProfileActionTile(
                      compact: compactHeight,
                      icon: Icons.star_rate_rounded,
                      title: state._t(context, 'Feedback', 'Feedback'),
                      subtitle: state._t(
                        context,
                        'Rate your experience and share suggestions',
                        'I-rate ang iyong karanasan at magbahagi ng mungkahi',
                      ),
                      color: const Color(0xFF142D57),
                      onTap: () => showFeedbackDialog(context),
                    ),
                    const _ModernProfileActionDivider(),
                    _ModernProfileActionTile(
                      compact: compactHeight,
                      icon: Icons.logout_rounded,
                      title: state._isLoggingOut
                          ? state._t(
                              context,
                              'Logging Out...',
                              'Nagla-log out...',
                            )
                          : state._t(context, 'Log Out', 'Mag Log Out'),
                      subtitle: state._t(
                        context,
                        'Securely sign out of this device',
                        'Ligtas na mag-sign out sa device na ito',
                      ),
                      color: brandRed,
                      onTap: state._isLoggingOut ? null : state._logout,
                      showChevron: false,
                    ),
                  ],
                ),
              ];

              return _ModernProfileStickyLayout(
                availableHeight: constraints.maxHeight,
                horizontalPadding: horizontalPadding,
                topPadding: topPadding,
                headingGap: headingGap,
                bottomPadding: bottomPadding,
                stickyChildren: stickyChildren,
                scrollChildren: scrollChildren,
              );
            },
          ),
        ),
      ],
    ),
  );
}

/// Pins [stickyChildren] (header + overview card) and scrolls only
/// [scrollChildren] below them, as long as the measured pinned section still
/// leaves a usable scroll area above the floating nav bar. On short screens,
/// in landscape or with large accessibility text, the whole page scrolls.
class _ModernProfileStickyLayout extends StatefulWidget {
  const _ModernProfileStickyLayout({
    required this.availableHeight,
    required this.horizontalPadding,
    required this.topPadding,
    required this.headingGap,
    required this.bottomPadding,
    required this.stickyChildren,
    required this.scrollChildren,
  });

  final double availableHeight;
  final double horizontalPadding;
  final double topPadding;
  final double headingGap;

  /// Space reserved at the bottom for the floating nav bar and system inset.
  final double bottomPadding;
  final List<Widget> stickyChildren;
  final List<Widget> scrollChildren;

  @override
  State<_ModernProfileStickyLayout> createState() =>
      _ModernProfileStickyLayoutState();
}

class _ModernProfileStickyLayoutState
    extends State<_ModernProfileStickyLayout> {
  // Visible height the scroll area must keep for "Account & support" (its
  // heading plus at least one action row) at 1x text, scaled with font size.
  static const double _minScrollContentHeight = 120;

  // Also keeps the pinned section's state when switching between layouts.
  final GlobalKey _stickyKey = GlobalKey();
  double? _stickyHeight;

  void _measureStickyHeight() {
    if (!mounted) return;
    final height = _stickyKey.currentContext?.size?.height;
    if (height != null && height != _stickyHeight) {
      setState(() => _stickyHeight = height);
    }
  }

  Widget _constrainedColumn(List<Widget> children, {Key? key}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          key: key,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reading the text scaler also rebuilds (and re-measures) on font changes.
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
      1.0,
      double.infinity,
    );
    // Height and fit can change with text scale, orientation, language and
    // profile data, so re-measure after every layout.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureStickyHeight());

    final stickyHeight = _stickyHeight;
    final visibleScrollHeight = stickyHeight == null
        ? 0.0
        : widget.availableHeight -
              widget.topPadding -
              stickyHeight -
              widget.bottomPadding;
    final pinTopSection =
        stickyHeight != null &&
        visibleScrollHeight >=
            widget.headingGap + _minScrollContentHeight * textScale;

    final sticky = _constrainedColumn(widget.stickyChildren, key: _stickyKey);

    if (!pinTopSection) {
      // Until measured, and whenever pinning doesn't fit, scroll everything.
      // At rest this places every section exactly where the pinned layout
      // does, so switching between the two is not visible.
      return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          widget.horizontalPadding,
          widget.topPadding,
          widget.horizontalPadding,
          widget.bottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sticky,
            SizedBox(height: widget.headingGap),
            _constrainedColumn(widget.scrollChildren),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            widget.horizontalPadding,
            widget.topPadding,
            widget.horizontalPadding,
            0,
          ),
          child: sticky,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              widget.horizontalPadding,
              widget.headingGap,
              widget.horizontalPadding,
              widget.bottomPadding,
            ),
            child: _constrainedColumn(widget.scrollChildren),
          ),
        ),
      ],
    );
  }
}

class _AchievementButton extends StatelessWidget {
  const _AchievementButton({
    required this.medals,
    required this.isLoading,
    required this.onTap,
  });

  final List<VirtualMedal> medals;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final earnedCount = medals.where((medal) => medal.earned).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isLoading ? null : onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF0E2D0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A5B16).withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: -10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE89B), Color(0xFFC98513)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(context, 'Achievements', 'Mga Nakamit'),
                      style: const TextStyle(
                        color: Color(0xFF142D57),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isLoading
                          ? t(
                              context,
                              'Checking your medals…',
                              'Sinusuri ang iyong medals…',
                            )
                          : t(
                              context,
                              '$earnedCount of ${medals.length} medals earned',
                              '$earnedCount sa ${medals.length} medals ang nakamit',
                            ),
                      style: const TextStyle(
                        color: Color(0xFF858994),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$earnedCount/${medals.length}',
                  style: const TextStyle(
                    color: Color(0xFF9A620C),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB7B9C0),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showMedalCollectionSheet(
  BuildContext context, {
  required List<VirtualMedal> medals,
  required bool isLoading,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.sizeOf(sheetContext).height * 0.84,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F6F3),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D1D5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFC88B18),
                    size: 27,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(
                            context,
                            'Achievement medals',
                            'Achievement medals',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF142D57),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          t(
                            context,
                            'Tap a medal to view its details.',
                            'I-tap ang medal upang tingnan ang detalye.',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF7D818B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: t(context, 'Close', 'Isara'),
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: _VirtualMedalCollection(
                  medals: medals,
                  isLoading: isLoading,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _VirtualMedalCollection extends StatelessWidget {
  const _VirtualMedalCollection({
    required this.medals,
    required this.isLoading,
  });

  final List<VirtualMedal> medals;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final earnedCount = medals.where((medal) => medal.earned).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E7E3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B1A1E).withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3DF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFC88B18),
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(context, 'Medal collection', 'Koleksyon ng medals'),
                      style: const TextStyle(
                        color: Color(0xFF142D57),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoading
                          ? t(
                              context,
                              'Checking achievements…',
                              'Sinusuri ang mga nakamit…',
                            )
                          : t(
                              context,
                              '$earnedCount of ${medals.length} earned',
                              '$earnedCount sa ${medals.length} ang nakamit',
                            ),
                      style: const TextStyle(
                        color: Color(0xFF858994),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE8E5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$earnedCount / ${medals.length}',
                  style: const TextStyle(
                    color: Color(0xFFB11217),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: medals
                    .map(
                      (medal) => SizedBox(
                        width: itemWidth,
                        child: _VirtualMedalCard(medal: medal),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VirtualMedalCard extends StatelessWidget {
  const _VirtualMedalCard({required this.medal});

  final VirtualMedal medal;

  @override
  Widget build(BuildContext context) {
    final label = medal.isCompletionMedal
        ? t(context, 'All modules', 'Lahat ng modyul')
        : t(context, 'Module ${medal.moduleNo}', 'Modyul ${medal.moduleNo}');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () => _showVirtualMedalDetails(context, medal),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 11),
          decoration: BoxDecoration(
            color: medal.earned
                ? medal.primaryColor.withValues(alpha: 0.055)
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: medal.earned
                  ? medal.accentColor.withValues(alpha: 0.48)
                  : const Color(0xFFE5E5E5),
            ),
          ),
          child: Column(
            children: [
              _VirtualMedalArt(medal: medal, size: 78),
              const SizedBox(height: 5),
              Text(
                medal.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: medal.earned
                      ? const Color(0xFF142D57)
                      : const Color(0xFF8B8B8B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    medal.earned
                        ? Icons.check_circle_rounded
                        : Icons.lock_rounded,
                    size: 12,
                    color: medal.earned
                        ? const Color(0xFF2E7D5B)
                        : const Color(0xFF9A9A9A),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      medal.earned ? t(context, 'Earned', 'Nakamit') : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: medal.earned
                            ? const Color(0xFF2E7D5B)
                            : const Color(0xFF8B8B8B),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VirtualMedalArt extends StatelessWidget {
  const _VirtualMedalArt({required this.medal, required this.size});

  final VirtualMedal medal;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = medal.earned ? medal.primaryColor : const Color(0xFF9C9C9C);
    final accent = medal.earned ? medal.accentColor : const Color(0xFFC5C5C5);
    final metalLight = medal.earned
        ? const Color(0xFFFFF1A8)
        : const Color(0xFFE1E1E1);
    final metalMid = medal.earned
        ? const Color(0xFFE8AC2E)
        : const Color(0xFFAAAAAA);
    final metalDark = medal.earned
        ? const Color(0xFF8E5100)
        : const Color(0xFF747474);

    return SizedBox(
      width: size,
      height: size + 13,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: size * 0.53,
            left: size * 0.18,
            child: Transform.rotate(
              angle: 0.14,
              child: _MedalRibbon(
                color: primary,
                width: size * 0.27,
                height: size * 0.43,
              ),
            ),
          ),
          Positioned(
            top: size * 0.53,
            right: size * 0.18,
            child: Transform.rotate(
              angle: -0.14,
              child: _MedalRibbon(
                color: accent,
                width: size * 0.27,
                height: size * 0.43,
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.075),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.45),
                radius: 1.05,
                colors: [metalLight, metalMid, metalDark],
                stops: const [0, 0.55, 1],
              ),
              boxShadow: medal.earned
                  ? [
                      BoxShadow(
                        color: metalDark.withValues(alpha: 0.32),
                        blurRadius: 15,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : const [],
            ),
            child: Container(
              padding: EdgeInsets.all(size * 0.035),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: metalLight.withValues(alpha: 0.72),
                border: Border.all(color: metalDark, width: size * 0.025),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.25, -0.35),
                    colors: medal.earned
                        ? [
                            Colors.white,
                            accent.withValues(alpha: 0.26),
                            primary.withValues(alpha: 0.14),
                          ]
                        : const [Color(0xFFF0F0F0), Color(0xFFD5D5D5)],
                  ),
                  border: Border.all(
                    color: medal.earned ? primary : metalDark,
                    width: size * 0.022,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      medal.earned ? medal.icon : Icons.lock_rounded,
                      color: primary,
                      size: size * 0.36,
                    ),
                    Positioned(
                      bottom: size * 0.085,
                      left: 2,
                      right: 2,
                      child: Text(
                        medal.isCompletionMedal
                            ? 'CHAMPION'
                            : 'MODULE ${medal.moduleNo}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          color: metalDark,
                          fontSize: size * 0.075,
                          fontWeight: FontWeight.w900,
                          letterSpacing: size * 0.008,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (medal.earned)
            Positioned(
              right: 0,
              top: 2,
              child: Container(
                width: size * 0.27,
                height: size * 0.27,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D5B),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: size * 0.17,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MedalRibbon extends StatelessWidget {
  const _MedalRibbon({
    required this.color,
    required this.width,
    required this.height,
  });

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _RibbonClipper(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withValues(alpha: 0.72)],
          ),
        ),
      ),
    );
  }
}

class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.78)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

Future<void> _showVirtualMedalDetails(
  BuildContext context,
  VirtualMedal medal,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => _VirtualMedalDetailsDialog(medal: medal),
  );
}

class _VirtualMedalDetailsDialog extends StatelessWidget {
  const _VirtualMedalDetailsDialog({required this.medal});

  final VirtualMedal medal;

  @override
  Widget build(BuildContext context) {
    final earnedDate = medal.earnedAt;
    final dateText = earnedDate == null
        ? null
        : '${_monthName(earnedDate.month)} ${earnedDate.day}, ${earnedDate.year}';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VirtualMedalArt(medal: medal, size: 126),
          const SizedBox(height: 10),
          Text(
            medal.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF142D57),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            medal.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6F7380),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: medal.earned
                  ? const Color(0xFFEFF7F2)
                  : const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  medal.earned ? Icons.verified_rounded : Icons.lock_rounded,
                  size: 17,
                  color: medal.earned
                      ? const Color(0xFF2E7D5B)
                      : const Color(0xFF777777),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    medal.earned
                        ? dateText == null
                              ? t(context, 'Medal earned', 'Medal ay nakamit')
                              : t(
                                  context,
                                  'Earned on $dateText',
                                  'Nakamit noong $dateText',
                                )
                        : medal.isCompletionMedal
                        ? t(
                            context,
                            'Complete all five modules to unlock',
                            'Tapusin ang limang modyul para ma-unlock',
                          )
                        : t(
                            context,
                            'Complete Module ${medal.moduleNo} to unlock',
                            'Tapusin ang Modyul ${medal.moduleNo} para ma-unlock',
                          ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: medal.earned
                          ? const Color(0xFF2E7D5B)
                          : const Color(0xFF777777),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            t(context, 'Close', 'Isara'),
            style: const TextStyle(
              color: Color(0xFFB11217),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _showRegisteredLocationInfo(
  BuildContext context,
  String location,
) async {
  final hasLocation = location.trim().isNotEmpty;
  await showAppDialog(
    context,
    title: t(context, 'Registered location', 'Nakarehistrong lokasyon'),
    message: hasLocation
        ? t(
            context,
            '$location\n\nThis is kept read-only to preserve accurate learner and barangay records. Contact an authorized administrator if your registered barangay needs to be corrected.',
            '$location\n\nHindi ito direktang nababago upang mapanatiling tama ang learner at barangay records. Makipag-ugnayan sa awtorisadong administrator kung kailangang itama ang nakarehistrong barangay.',
          )
        : t(
            context,
            'This legacy account does not have a registered barangay yet. Contact an authorized administrator to add and verify it.',
            'Wala pang nakarehistrong barangay ang legacy account na ito. Makipag-ugnayan sa awtorisadong administrator upang maidagdag at ma-verify ito.',
          ),
    type: AppNotificationType.info,
    accentColor: const Color(0xFF142D57),
    okText: t(context, 'Got it', 'Naiintindihan'),
  );
}

String _monthName(int month) {
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[(month - 1).clamp(0, 11)];
}

class _ProfileHeaderOrb extends StatelessWidget {
  const _ProfileHeaderOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity * 0.8),
        ),
      ),
    );
  }
}

class _ModernProfileOverviewCard extends StatelessWidget {
  const _ModernProfileOverviewCard({
    required this.avatarImage,
    required this.isLoading,
    required this.displayName,
    required this.email,
    required this.location,
    required this.completedText,
    required this.progress,
    required this.lastSimulation,
    required this.onEdit,
    required this.accountLabel,
    required this.progressLabel,
    required this.completedLabel,
    required this.recentLabel,
    required this.noActivityLabel,
    this.compact = false,
  });

  final ImageProvider? avatarImage;
  final bool isLoading;
  final String displayName;
  final String email;
  final String location;
  final String completedText;
  final double progress;
  final String lastSimulation;
  final VoidCallback onEdit;
  final String accountLabel;
  final String progressLabel;
  final String completedLabel;
  final String recentLabel;
  final String noActivityLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF142D57);
    const red = Color(0xFFB11217);
    final avatarSize = compact ? 72.0 : 88.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B1A1E).withValues(alpha: 0.12),
            blurRadius: 30,
            spreadRadius: -8,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [red, Color(0xFFF2A93B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: red.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFFFF0ED),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Icon(
                              Icons.person_rounded,
                              size: avatarSize * 0.43,
                              color: red,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: red,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onEdit,
                        child: SizedBox(
                          width: compact ? 26 : 30,
                          height: compact ? 26 : 30,
                          child: Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: compact ? 13 : 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: isLoading
                    ? const _ModernProfileLoadingLines()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName.trim().isEmpty ? '—' : displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            email.trim().isEmpty ? '—' : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF6F7380),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (location.trim().isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 13,
                                  color: Color(0xFFB11217),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF6F7380),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 9),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF5F2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 13,
                                  color: Color(0xFF2E7D5B),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    accountLabel,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF2E7D5B),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          SizedBox(height: compact ? 14 : 20),
          Container(height: 1, color: const Color(0xFFF0ECEA)),
          SizedBox(height: compact ? 12 : 17),
          Row(
            children: [
              Expanded(
                child: Text(
                  progressLabel,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                completedText,
                style: const TextStyle(
                  color: red,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3E7E5),
              valueColor: const AlwaysStoppedAnimation<Color>(red),
            ),
          ),
          SizedBox(height: compact ? 6 : 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$completedText $completedLabel',
              style: const TextStyle(
                color: Color(0xFF858994),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 30 : 34,
                  height: compact ? 30 : 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7EDF7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: navy,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recentLabel,
                        style: const TextStyle(
                          color: Color(0xFF858994),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastSimulation.trim().isEmpty
                            ? noActivityLabel
                            : lastSimulation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _ModernProfileLoadingLines extends StatelessWidget {
  const _ModernProfileLoadingLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 132,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEEF1),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 170,
          height: 11,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F1F3),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}

class _ModernProfileSectionHeading extends StatelessWidget {
  const _ModernProfileSectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF22242A),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF858994),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ModernProfileActionPanel extends StatelessWidget {
  const _ModernProfileActionPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEE9E6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            spreadRadius: -7,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(children: children),
      ),
    );
  }
}

class _ModernProfileActionDivider extends StatelessWidget {
  const _ModernProfileActionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 68, color: Color(0xFFF0ECEA));
  }
}

class _ModernProfileActionTile extends StatelessWidget {
  const _ModernProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color = const Color(0xFFB11217),
    this.showChevron = true,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;
  final bool showChevron;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: compact ? 10 : 14,
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: compact ? 18 : 21),
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
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF858994),
                        fontSize: 10.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (showChevron) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB7B9C0),
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
