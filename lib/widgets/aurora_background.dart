import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// Koyu zemin ve üstünde yumuşak renkli ışık lekeleri.
///
/// Bulanıklık filtresi yerine kenarı saydama giden radyal degrade kullanır;
/// bu çok daha ucuzdur. Tek seferlik çizilir (RepaintBoundary).
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
                  stops: [0, 0.5, 1],
                ),
              ),
              child: Stack(
                children: [
                  _orb(left: -0.28 * w, top: -0.08 * h, size: 0.87 * w, color: AppColors.auroraPink, opacity: 0.95),
                  _orb(right: -0.36 * w, top: 0.24 * h, size: 0.97 * w, color: AppColors.auroraViolet, opacity: 1),
                  _orb(left: -0.33 * w, top: 0.56 * h, size: 0.92 * w, color: AppColors.auroraCyan, opacity: 0.75),
                  _orb(right: -0.26 * w, bottom: -0.09 * h, size: 0.82 * w, color: AppColors.auroraLime, opacity: 0.45),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _orb({
    double? left,
    double? top,
    double? right,
    double? bottom,
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withAlpha((opacity * 255).round()), color.withAlpha(0)],
            stops: const [0, 0.7],
          ),
        ),
      ),
    );
  }
}
