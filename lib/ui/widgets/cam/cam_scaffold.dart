import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';

/// Cam zemini: gece mavisi degrade, üstünde yumuşak renkli ışıklar
/// (aurora) ve metin karşıtlığını koruyan koyu perde.
///
/// Bulanıklık filtresi yerine kenarı saydama giden radyal degrade kullanır;
/// tek katmanda çizilir ve dokunmaları geçirir.
class CamBackground extends StatelessWidget {
  const CamBackground({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _AuroraPainter(context.colors),
        size: Size.infinite,
      ),
    ),
  );
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter(this.c);
  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.bgTop, c.bgMid, c.bgBottom],
        ).createShader(rect),
    );
    // Konumlar ekran boyutuna oranlı: sol üst pembe, sağ üst-orta mor,
    // sol alt-orta camgöbeği, sağ alt neon yeşil.
    void light(double cx, double cy, double d, Color color) {
      final r = d / 2;
      final circle = Rect.fromCircle(center: Offset(cx, cy), radius: r);
      canvas.drawRect(
        circle,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 1],
          ).createShader(circle),
      );
    }

    light(0.16 * w, 0.06 * h + 0.2 * w, 1.1 * w, c.auroraPink);
    light(0.88 * w, 0.24 * h + 0.48 * w, 1.2 * w, c.auroraViolet);
    light(0.13 * w, 0.56 * h + 0.46 * w, 1.15 * w, c.auroraCyan);
    light(0.85 * w, h - 0.32 * w, 1.0 * w, c.auroraLime);
    canvas.drawRect(rect, Paint()..color = c.scrim);
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.c != c;
}

/// Her rotanın iskeleti: zemini ve aurorayı kendisi çizer, üstüne saydam
/// bir [Scaffold] koyar. Böylece sayfa geçişlerinde iki ekran üst üste
/// görünmez.
class CamScaffold extends StatelessWidget {
  const CamScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: camSystemOverlay,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const CamBackground(),
        Scaffold(
          backgroundColor: const Color(0x00000000),
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
        ),
      ],
    ),
  );
}
