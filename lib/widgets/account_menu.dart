import 'package:flutter/material.dart';

/// Shared visual style + item list for the small "Profile / Log Out"
/// popup menu that hangs off the avatar in the top header of the
/// Module, About Us and Profile tabs.
const Color accountMenuBrandRed = Color(0xFFB11217);

/// Rounded, elevated shape used by every avatar [PopupMenuButton] so the
/// menu looks like one consistent component across the app.
ShapeBorder accountMenuShape() {
  return RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
}

/// Builds the "Profile" / "Log Out" entries with the shared premium look:
/// circular icon badges, generous padding and a subtle divider.
List<PopupMenuEntry<String>> buildAccountMenuItems(
  BuildContext context, {
  required String profileLabel,
  required String logoutLabel,
}) {
  return [
    PopupMenuItem<String>(
      value: 'profile',
      padding: EdgeInsets.zero,
      child: _AccountMenuTile(
        icon: Icons.person_outline_rounded,
        label: profileLabel,
      ),
    ),
    const PopupMenuDivider(height: 1),
    PopupMenuItem<String>(
      value: 'logout',
      padding: EdgeInsets.zero,
      child: _AccountMenuTile(
        icon: Icons.logout_rounded,
        label: logoutLabel,
      ),
    ),
  ];
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accountMenuBrandRed.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accountMenuBrandRed),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
