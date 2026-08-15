part of 'profile.dart';

Widget _buildModernProfileView(_ProfilePageState state, BuildContext context) {
  const brandRed = Color(0xFFB11217);
  final avatarImage = state._getAvatarImage();
  final completedCount =
      int.tryParse(state._completedSimulations.split('/').first.trim()) ?? 0;
  final progress = (completedCount / _ProfilePageState._totalSimulations).clamp(
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
              final horizontalPadding = compactWidth ? 16.0 : 22.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  MediaQuery.paddingOf(context).bottom + 96,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MainTabHeader(
                          greeting: state._displayName.trim().isEmpty
                              ? state._t(context, 'Welcome back', 'Mabuhay')
                              : state._t(
                                  context,
                                  'Hi, ${state._displayName.trim().split(' ').first}',
                                  'Kumusta, ${state._displayName.trim().split(' ').first}',
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
                          profileLabel: state._t(context, 'Profile', 'Profile'),
                          logoutLabel: state._t(
                            context,
                            'Log Out',
                            'Mag-logout',
                          ),
                          onProfile: () {},
                          onLogout: state._logout,
                        ),
                        const SizedBox(height: 23),
                        _ModernProfileOverviewCard(
                          avatarImage: avatarImage,
                          isLoading: state._isLoadingProfile,
                          displayName: state._displayName,
                          email: state._email,
                          completedText: state._completedSimulations,
                          progress: progress,
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
                            'simulations completed',
                            'simulation ang natapos',
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
                        const SizedBox(height: 24),
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
                        const SizedBox(height: 12),
                        _ModernProfileActionPanel(
                          children: [
                            _ModernProfileActionTile(
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
                      ],
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
    required this.lastSimulation,
    required this.onEdit,
    required this.accountLabel,
    required this.progressLabel,
    required this.completedLabel,
    required this.recentLabel,
    required this.noActivityLabel,
  });

  final ImageProvider? avatarImage;
  final bool isLoading;
  final String displayName;
  final String email;
  final String completedText;
  final double progress;
  final String lastSimulation;
  final VoidCallback onEdit;
  final String accountLabel;
  final String progressLabel;
  final String completedLabel;
  final String recentLabel;
  final String noActivityLabel;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF142D57);
    const red = Color(0xFFB11217);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
                    width: 88,
                    height: 88,
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
                          ? const Icon(
                              Icons.person_rounded,
                              size: 38,
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
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 15,
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
          const SizedBox(height: 20),
          Container(height: 1, color: const Color(0xFFF0ECEA)),
          const SizedBox(height: 17),
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
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3E7E5),
              valueColor: const AlwaysStoppedAnimation<Color>(red),
            ),
          ),
          const SizedBox(height: 7),
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
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
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
