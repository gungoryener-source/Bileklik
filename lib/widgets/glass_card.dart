import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// Buzlu cam görünümlü kart.
///
/// Varsayılan olarak gerçek bulanıklık (BackdropFilter) KULLANMAZ: arka plandaki
/// aurora zaten yumuşak olduğu için yarı saydam katman cam hissini verir ve
/// kaydırma akıcı kalır. Gerçek bulanıklık yalnızca içeriğin üstünde yüzen
/// yüzeylerde (alt menü gibi) `blur: true` ile açılmalı.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.tint,
    this.baseColor = AppColors.glassBase,
    this.blur = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Kartın renk tonu. Verilmezse beyaz parlaklık degradesi kullanılır.
  final Gradient? tint;
  final Color baseColor;
  final bool blur;

  static const _defaultSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.glassSheenStart, AppColors.glassSheenEnd],
  );

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    Widget card = DecoratedBox(
      decoration: BoxDecoration(color: baseColor, borderRadius: borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: tint ?? _defaultSheen,
          borderRadius: borderRadius,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
    if (blur) {
      card = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: card,
        ),
      );
    }
    return card;
  }
}
