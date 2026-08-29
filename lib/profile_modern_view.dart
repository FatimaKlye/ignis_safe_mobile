part of 'profile.dart';

Widget _buildModernProfileView(_ProfilePageState state, BuildContext context) {
  const brandRed = Color(0xFFB11217);
  final avatarImage = state._getAvatarImage();
  final trainingCompletedCount =
      int.tryParse(state._completedTrainingModules.split('/').first.trim()) ??
      0;
  final simulationCompletedCount =
      int.tryParse(state._completedSimulations.split('/').first.trim()) ?? 0;
  final trainingProgress =
      (trainingCompletedCount / _ProfilePageState._totalSimulations).clamp(
        0.0,
        1.0,
      );
  final simulationProgress =
      (simulationCompletedCount / _ProfilePageState._totalSimulations).clamp(
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

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        (constraints.maxHeight - topPadding - bottomPadding)
                            .clamp(0.0, double.infinity),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            title: state._t(
                              context,
                              'My Profile',
                              'Aking Profile',
                            ),
                            subtitle: state._t(
                              context,
                              'Manage your account and track your training.',
                              'Pamahalaan ang account at subaybayan ang training.',
                            ),
                            titleIcon: Icons.person_rounded,
                            avatarImage: avatarImage,
                            profileLabel: state._t(
                              context,
                              'Profile',
                              'Profile',
                            ),
                            refreshLabel: state._t(
                              context,
                              'Refresh & Check Updates',
                              'I-refresh at Tingnan ang Updates',
                            ),
                            logoutLabel: state._t(
                              context,
                              'Log Out',
                              'Mag-logout',
                            ),
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
                            completedText: state._completedTrainingModules,
                            progress: trainingProgress,
                            simulationCompletedText:
                                state._completedSimulations,
                            simulationProgress: simulationProgress,
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
                            simulationLabel: state._t(
                              context,
                              'Simulations completed',
                              'Mga simulation na natapos',
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
                                icon: Icons.help_outline_rounded,
                                title: state._t(
                                  context,
                                  'Help & FAQ',
                                  'Tulong at FAQ',
                                ),
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
                                title: state._t(
                                  context,
                                  'Feedback',
                                  'Feedback',
                                ),
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
                                    : state._t(
                                        context,
                                        'Log Out',
                                        'Mag Log Out',
                                      ),
                                subtitle: state._t(
                                  context,
                                  'Securely sign out of this device',
                                  'Ligtas na mag-sign out sa device na ito',
                                ),
                                color: brandRed,
                                onTap: state._isLoggingOut
                                    ? null
                                    : state._logout,
                                showChevron: false,
                              ),
                            ],
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
    required this.completedText,
    required this.progress,
    required this.simulationCompletedText,
    required this.simulationProgress,
    required this.lastSimulation,
    required this.onEdit,
    required this.accountLabel,
    required this.progressLabel,
    required this.completedLabel,
    required this.simulationLabel,
    required this.recentLabel,
    required this.noActivityLabel,
    this.compact = false,
  });

  final ImageProvider? avatarImage;
  final bool isLoading;
  final String displayName;
  final String email;
  final String completedText;
  final double progress;
  final String simulationCompletedText;
  final double simulationProgress;
  final String lastSimulation;
  final VoidCallback onEdit;
  final String accountLabel;
  final String progressLabel;
  final String completedLabel;
  final String simulationLabel;
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
          SizedBox(height: compact ? 10 : 14),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF5E5E1)),
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 30 : 34,
                  height: compact ? 30 : 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCE8E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_esports_rounded,
                    color: red,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              simulationLabel,
                              style: const TextStyle(
                                color: navy,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            simulationCompletedText,
                            style: const TextStyle(
                              color: red,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: simulationProgress,
                          minHeight: 5,
                          backgroundColor: const Color(0xFFF3E7E5),
                          valueColor: const AlwaysStoppedAnimation<Color>(red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
