import 'package:flutter/material.dart';

import 'account_menu.dart';

const Color _headerBrandRed = Color(0xFFB11217);
const Color _headerGold = Color(0xFFF2A93B);

class MainTabHeaderBackdrop extends StatelessWidget {
  const MainTabHeaderBackdrop({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: MainTabHeaderSurface(height: height),
    );
  }
}

class MainTabHeaderSurface extends StatelessWidget {
  const MainTabHeaderSurface({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC9232A), _headerBrandRed, Color(0xFF7F0B12)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: const [
          Positioned(
            top: -90,
            right: -58,
            child: _HeaderOrb(size: 224, opacity: 0.10),
          ),
          Positioned(
            top: 145,
            left: -72,
            child: _HeaderOrb(size: 172, opacity: 0.07),
          ),
          Positioned(
            right: 78,
            bottom: 20,
            child: _HeaderDot(size: 7, color: _headerGold),
          ),
        ],
      ),
    );
  }
}

class MainTabHeader extends StatelessWidget {
  const MainTabHeader({
    super.key,
    required this.greeting,
    required this.accountLabel,
    required this.title,
    required this.subtitle,
    required this.titleIcon,
    required this.avatarImage,
    required this.profileLabel,
    required this.logoutLabel,
    required this.onProfile,
    required this.onLogout,
  });

  final String greeting;
  final String accountLabel;
  final String title;
  final String subtitle;
  final IconData titleIcon;
  final ImageProvider? avatarImage;
  final String profileLabel;
  final String logoutLabel;
  final VoidCallback onProfile;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 370;
    final avatarRadius = compact ? 20.0 : 22.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    accountLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: '',
              offset: const Offset(0, 54),
              elevation: 10,
              color: Colors.white,
              surfaceTintColor: Colors.white,
              shadowColor: Colors.black.withValues(alpha: 0.16),
              shape: accountMenuShape(),
              constraints: const BoxConstraints(minWidth: 205),
              onSelected: (value) async {
                if (value == 'profile') {
                  onProfile();
                  return;
                }
                if (value == 'logout') await onLogout();
              },
              itemBuilder: (context) => buildAccountMenuItems(
                context,
                profileLabel: profileLabel,
                logoutLabel: logoutLabel,
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.32),
                  ),
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: const Color(0xFFFFE6E3),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 22,
                          color: _headerBrandRed,
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Icon(titleIcon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 24 : 27,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: compact ? 10.5 : 11.5,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderOrb extends StatelessWidget {
  const _HeaderOrb({required this.size, required this.opacity});

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

class _HeaderDot extends StatelessWidget {
  const _HeaderDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.75),
      ),
    );
  }
}
