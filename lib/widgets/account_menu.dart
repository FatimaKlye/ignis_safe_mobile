import 'package:flutter/material.dart';

/// Shared visual style + item list for the small "Profile / Refresh & Check
/// Updates / Log Out" popup menu that hangs off the avatar in the top header
/// of the Module, About Us and Profile tabs.
const Color accountMenuBrandRed = Color(0xFFB11217);

/// Navy used by the two account actions that are not destructive, so Log Out
/// stays the only red entry in the menu.
const Color _accountMenuNavy = Color(0xFF142D57);

/// Rounded, elevated shape used by every avatar [PopupMenuButton] so the
/// menu looks like one consistent component across the app.
ShapeBorder accountMenuShape() {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(22),
    side: const BorderSide(color: Color(0xFFEEE9E6)),
  );
}

/// Builds the "Profile" / "Refresh & Check Updates" / "Log Out" entries with
/// the shared premium look: circular icon badges, generous padding and a
/// subtle divider.
List<PopupMenuEntry<String>> buildAccountMenuItems(
  BuildContext context, {
  required String profileLabel,
  required String refreshLabel,
  required String logoutLabel,
}) {
  return [
    PopupMenuItem<String>(
      value: 'profile',
      padding: EdgeInsets.zero,
      child: _AccountMenuTile(
        icon: Icons.manage_accounts_outlined,
        label: profileLabel,
        color: _accountMenuNavy,
      ),
    ),
    const PopupMenuDivider(height: 1),
    PopupMenuItem<String>(
      value: 'refresh',
      padding: EdgeInsets.zero,
      child: _AccountMenuTile(
        icon: Icons.sync_rounded,
        label: refreshLabel,
        color: _accountMenuNavy,
        showChevron: false,
      ),
    ),
    const PopupMenuDivider(height: 1),
    PopupMenuItem<String>(
      value: 'logout',
      padding: EdgeInsets.zero,
      child: _AccountMenuTile(
        icon: Icons.logout_rounded,
        label: logoutLabel,
        color: accountMenuBrandRed,
        showChevron: false,
      ),
    ),
  ];
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.icon,
    required this.label,
    required this.color,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 19,
              color: Color(0xFFB7B9C0),
            ),
          ],
        ],
      ),
    );
  }
}
