import 'dart:async';
import 'package:flutter/material.dart';

/// Semantic category for [showAppNotification] / [showAppDialog]. Selects
/// the fallback icon/gradient when no screen-specific [Color] is passed via
/// `accentColor`.
enum AppNotificationType { success, error, warning, info }

class _NotifStyle {
  final List<Color> gradient;
  final IconData icon;
  const _NotifStyle(this.gradient, this.icon);
}

const Map<AppNotificationType, _NotifStyle> _notifStyles = {
  AppNotificationType.success: _NotifStyle(
    [Color(0xFF22C55E), Color(0xFF16A34A)],
    Icons.check_circle_rounded,
  ),
  AppNotificationType.error: _NotifStyle(
    [Color(0xFFDC2626), Color(0xFFB11217)],
    Icons.error_rounded,
  ),
  AppNotificationType.warning: _NotifStyle(
    [Color(0xFFF59E0B), Color(0xFFF97316)],
    Icons.warning_amber_rounded,
  ),
  AppNotificationType.info: _NotifStyle(
    [Color(0xFF3B82F6), Color(0xFF2563EB)],
    Icons.info_rounded,
  ),
};

/// Builds a 2-stop gradient from a single screen/module accent color so call
/// sites only need to pass one [Color] (e.g. a module's existing brand
/// color) instead of a full gradient.
List<Color> _resolveGradient(AppNotificationType type, Color? accentColor) {
  if (accentColor == null) return _notifStyles[type]!.gradient;
  final hsl = HSLColor.fromColor(accentColor);
  final darker = hsl
      .withLightness((hsl.lightness - 0.14).clamp(0.0, 1.0))
      .toColor();
  return [accentColor, darker];
}

OverlayEntry? _activeNotificationEntry;
GlobalKey<_AppNotificationCardState>? _activeNotificationKey;

/// Shows a floating, theme-matched notification card near the top of the
/// screen. Replaces the default gray [SnackBar] for transient
/// success/error/info messages. Positioned at the top (instead of the
/// bottom) so it stays visible even when the on-screen keyboard is open.
/// Only one card is shown at a time.
void showAppNotification(
  BuildContext context, {
  String? title,
  required String message,
  AppNotificationType type = AppNotificationType.info,
  Color? accentColor,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  _activeNotificationKey?.currentState?.dismissImmediately();
  _activeNotificationEntry?.remove();
  _activeNotificationEntry = null;
  _activeNotificationKey = null;

  final cardKey = GlobalKey<_AppNotificationCardState>();
  late final OverlayEntry entry;

  void remove() {
    if (_activeNotificationEntry == entry) {
      entry.remove();
      _activeNotificationEntry = null;
      _activeNotificationKey = null;
    }
  }

  entry = OverlayEntry(
    builder: (_) => _AppNotificationCard(
      key: cardKey,
      title: title,
      message: message,
      type: type,
      accentColor: accentColor,
      duration: duration,
      onDismissed: remove,
    ),
  );

  _activeNotificationEntry = entry;
  _activeNotificationKey = cardKey;
  overlay.insert(entry);
}

/// Shows a themed, blocking pop-up modal for important messages (lock
/// notices, critical validation, confirmations). Visually matches the app's
/// existing learning-material dialogs: gradient icon badge, rounded 24
/// corners, Poppins typography, gradient CTA button, and a top-right close
/// (X) button.
Future<void> showAppDialog(
  BuildContext context, {
  String? title,
  required String message,
  AppNotificationType type = AppNotificationType.warning,
  Color? accentColor,
  String? okText,
  bool barrierDismissible = true,
}) async {
  final gradient = _resolveGradient(type, accentColor);
  final icon = _notifStyles[type]!.icon;

  await showDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      final compact = MediaQuery.of(dialogContext).size.width < 360;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 430),
              padding: EdgeInsets.fromLTRB(
                compact ? 18 : 22,
                compact ? 18 : 22,
                compact ? 18 : 22,
                compact ? 18 : 22,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: compact ? 54 : 62,
                    height: compact ? 54 : 62,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: compact ? 27 : 31,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (title != null && title.isNotEmpty) ...[
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: const Color(0xFF111827),
                        fontSize: compact ? 17 : 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradient),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          okText ?? 'OK',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.of(dialogContext).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _AppNotificationCard extends StatefulWidget {
  final String? title;
  final String message;
  final AppNotificationType type;
  final Color? accentColor;
  final Duration duration;
  final VoidCallback onDismissed;

  const _AppNotificationCard({
    super.key,
    this.title,
    required this.message,
    required this.type,
    this.accentColor,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_AppNotificationCard> createState() => _AppNotificationCardState();
}

class _AppNotificationCardState extends State<_AppNotificationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
    // Slides down from above so the card never has to sit near the bottom
    // of the screen where an open keyboard would cover it.
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  void dismissImmediately() {
    _timer?.cancel();
    _closing = true;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _resolveGradient(widget.type, widget.accentColor);
    final icon = _notifStyles[widget.type]!.icon;
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      left: 16,
      right: 16,
      top: topInset + 12,
      child: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onVerticalDragEnd: (_) => _dismiss(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 34, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradient),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.title != null &&
                                      widget.title!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        widget.title!,
                                        softWrap: true,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Color(0xFF111827),
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    widget.message,
                                    softWrap: true,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: Color(0xFF4B5563),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _dismiss,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
