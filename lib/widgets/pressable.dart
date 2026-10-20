import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Basınca hafifçe küçülen, haptik geri bildirim veren dokunma alanı.
///
/// Erişilebilirlik için buton olarak duyurulur. "Hareketi azalt" açıksa
/// küçülme animasyonu yapılmaz.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
    this.selected,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool? selected;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final scale = _pressed && !reduceMotion ? widget.pressedScale : 1.0;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: enabled ? _handleTap : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: enabled ? _handleTap : null,
        child: AnimatedScale(
          scale: scale,
          duration: Duration(milliseconds: _pressed ? 90 : 160),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
