import 'package:flutter/material.dart';

import '../../theme.dart';
import 'pressable.dart';

/// Ana eylem düğmesi: pembe-mor degrade, renkli parıltı; üstte ışık altta
/// gölge ile kabartma. Pasifken %45 opak ve parıltısız.
class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final IconData? icon;

  /// null ise düğme pasif.
  final VoidCallback? onTap;

  /// Sürüyor göstergesi; düğme pasifleşir.
  final bool loading;

  /// Bulunduğu genişliği doldurur (alt eylem düğmeleri).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null && !loading;
    final radius = BorderRadius.circular(26);
    final reduce = MediaQuery.of(context).disableAnimations;
    return Pressable(
      semanticLabel: label,
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled || loading ? 1 : 0.45,
        duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
        child: Container(
          constraints: BoxConstraints(
            minHeight: expand ? 52 : 48,
            minWidth: expand ? double.infinity : 0,
          ),
          padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 20, 12),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.ctaStart, c.ctaEnd],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: c.ctaGlow,
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                c.glassSheenStart,
                c.glassSheenStart.withValues(alpha: 0),
                c.shadow.withValues(alpha: 0.12),
              ],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.text,
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 20, color: c.text),
              if (loading || icon != null) const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
