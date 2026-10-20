import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Ölçüler (8 dp ızgarası üstünde).
abstract final class CamRadius {
  static const card = 28.0;
  static const hero = 32.0;
  static const tile = 22.0;
  static const chip = 20.0;
}

abstract final class CamSpace {
  static const cardPadding = EdgeInsets.all(18);
  static const heroPadding = EdgeInsets.all(22);
  static const gap = 12.0;
}

/// Buzlu cam kart: yarı saydam koyu taban, üstünde çapraz beyaz parlaklık
/// ve 1 px açık kenar.
///
/// Varsayılan olarak gerçek bulanıklık (BackdropFilter) kullanmaz: zemin
/// zaten yumuşak olduğu için yarı saydam katman cam hissini verir ve
/// kaydırma akıcı kalır. Bulanıklık yalnızca içeriğin üstünde yüzen
/// yüzeylerde ([blur]: alt menü, alt sayfa, diyalog).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = CamSpace.cardPadding,
    this.radius = CamRadius.card,
    this.tint,
    this.baseColor,
    this.blur = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Kartın renk tonu; verilmezse beyaz parlaklık degradesi.
  final Gradient? tint;
  final Color? baseColor;
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = BorderRadius.circular(radius);
    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: baseColor ?? c.glassBase,
        borderRadius: shape,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          border: Border.all(color: c.glassBorder),
          gradient:
              tint ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.glassSheenStart, c.glassSheenEnd],
              ),
        ),
        // İçteki ListTile ve InkWell dalgaları kartın üstünde görünsün.
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(borderRadius: shape),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (blur) {
      card = ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: card,
        ),
      );
    }
    return card;
  }
}

/// Kartın renk tonu degradesi (sol üstten sağ alta).
LinearGradient camTint(Color start, Color end) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [start, end],
);
