import 'package:flutter/material.dart';

/// Releases stale input focus when the Android keyboard is dismissed, when a
/// route changes, or when the user taps outside the focused input.
class KeyboardDismissScope extends StatefulWidget {
  const KeyboardDismissScope({required this.child, super.key});

  final Widget child;

  @override
  State<KeyboardDismissScope> createState() => _KeyboardDismissScopeState();
}

class _KeyboardDismissScopeState extends State<KeyboardDismissScope>
    with WidgetsBindingObserver {
  double _lastKeyboardInset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lastKeyboardInset = View.of(context).viewInsets.bottom;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;

    final currentInset = View.of(context).viewInsets.bottom;
    final keyboardWasVisible = _lastKeyboardInset > 0;
    _lastKeyboardInset = currentInset;

    if (keyboardWasVisible && currentInset == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && View.of(context).viewInsets.bottom == 0) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    final renderObject = focus?.context?.findRenderObject();

    if (focus == null || !focus.hasFocus) return;

    if (renderObject is RenderBox && renderObject.attached) {
      final localPosition = renderObject.globalToLocal(event.position);
      // Preserve focus for taps in the input and its nearby suffix/prefix
      // controls, while buttons and navigation elsewhere release it.
      final protectedInputArea = Rect.fromLTWH(
        -52,
        -12,
        renderObject.size.width + 104,
        renderObject.size.height + 24,
      );
      if (protectedInputArea.contains(localPosition)) return;
    }

    focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: widget.child,
    );
  }
}

class KeyboardDismissNavigatorObserver extends NavigatorObserver {
  void _releaseFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _releaseFocus();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _releaseFocus();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _releaseFocus();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _releaseFocus();
    super.didRemove(route, previousRoute);
  }
}
