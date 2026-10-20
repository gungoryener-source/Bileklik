import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dokunulabilir her Cam öğesi: basınca 0.96'ya küçülür (90 ms iniş,
/// 160 ms dönüş), hafif titreşim verir ve ekran okuyucuya düğme olarak
/// duyurulur. "Hareketi azalt" açıksa küçülmez.
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

  /// Ekran okuyucunun okuyacağı ad; çocuktaki metinler yerine geçer.
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool? selected;
  final double pressedScale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  var _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  void _tap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: enabled ? _tap : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled ? _tap : null,
        child: AnimatedScale(
          scale: _pressed && !reduce ? widget.pressedScale : 1,
          duration: Duration(milliseconds: _pressed ? 90 : 160),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
