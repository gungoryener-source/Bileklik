import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme.dart';

export 'package:google_maps_flutter/google_maps_flutter.dart'
    show CameraUpdate, GoogleMapController, LatLng;

/// Haritada gösterilecek bir kişi ya da yer.
class CamMapMarker {
  const CamMapMarker({
    required this.id,
    required this.point,
    required this.label,
    this.snippet,
    this.color = DataColors.oxygen,
  });

  final String id;
  final LatLng point;
  final String label;
  final String? snippet;
  final Color color;
}

/// Koyu (Cam) görünümlü Google Haritası. Derlemede harita anahtarı
/// verilmediyse (`--dart-define=GOOGLE_MAPS=true` yok), web'de ve testlerde
/// harita açılmaz; kodla çizilmiş şehir zemini ve işaretler gösterilir.
class CamMap extends StatelessWidget {
  const CamMap({
    super.key,
    required this.center,
    this.zoom = 12,
    this.markers = const [],
    this.interactive = true,
    this.onCreated,
  });

  /// İstanbul; konum bilinmezken haritanın başlangıç merkezi.
  static const fallbackCenter = LatLng(41.0082, 28.9784);

  /// Google Haritalar açık mı: anahtar derlemede verildi ve platform mobil.
  static bool get enabled =>
      const bool.fromEnvironment('GOOGLE_MAPS') &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  final LatLng center;
  final double zoom;
  final List<CamMapMarker> markers;
  final bool interactive;
  final ValueChanged<GoogleMapController>? onCreated;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return _FallbackMap(center: center, zoom: zoom, markers: markers);
    }
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: center, zoom: zoom),
      style: darkStyle,
      onMapCreated: onCreated,
      markers: {
        for (final m in markers)
          Marker(
            markerId: MarkerId(m.id),
            position: m.point,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              HSVColor.fromColor(m.color).hue,
            ),
            infoWindow: InfoWindow(title: m.label, snippet: m.snippet),
          ),
      },
      zoomGesturesEnabled: interactive,
      scrollGesturesEnabled: interactive,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }

  /// Uygulamanın gece paletine uyan koyu harita biçimi.
  static const darkStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#151e2c"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9fb0c8"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0b111b"}]},
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#173a34"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2a3850"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3d5170"}]},
  {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#14324a"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#5d7a99"}]}
]
''';
}

/// Harita yokken: çizilmiş zemin, işaretler merkeze göre yerleştirilir.
class _FallbackMap extends StatelessWidget {
  const _FallbackMap({
    required this.center,
    required this.zoom,
    required this.markers,
  });

  final LatLng center;
  final double zoom;
  final List<CamMapMarker> markers;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // Web Mercator ölçeği, enlem düzeltmesiyle kabaca.
      final perDeg = 256 * pow(2, zoom) / 360;
      final latScale = 1 / cos(center.latitude * pi / 180);
      return Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: CityPainter()),
          for (final m in markers)
            Positioned(
              left:
                  box.maxWidth / 2 +
                  (m.point.longitude - center.longitude) * perDeg,
              top:
                  box.maxHeight / 2 -
                  (m.point.latitude - center.latitude) * perDeg * latScale,
              // İğnenin ucu noktanın üstünde, ortada.
              child: FractionalTranslation(
                translation: const Offset(-0.5, -0.55),
                child: Semantics(
                  label: [m.label, ?m.snippet].join(', '),
                  excludeSemantics: true,
                  child: _Pin(marker: m),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Çizilmiş haritada kişi iğnesi: baş harf dairesi ve ad.
class _Pin extends StatelessWidget {
  const _Pin({required this.marker});
  final CamMapMarker marker;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: marker.color,
          border: Border.all(color: MapColors.label, width: 2),
        ),
        child: Text(
          marker.label.isEmpty ? '?' : marker.label.characters.first,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: MapColors.labelBackground,
          ),
        ),
      ),
      const SizedBox(height: 2),
      DecoratedBox(
        decoration: BoxDecoration(
          color: MapColors.labelBackground,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            marker.label,
            maxLines: 1,
            style: const TextStyle(fontSize: 11, color: MapColors.label),
          ),
        ),
      ),
    ],
  );
}

/// Kodla çizilmiş, gerçek bir yeri göstermeyen koyu şehir zemini: su,
/// park, ana yollar ve ara sokaklar. Her çizimde aynı (sabit tohum).
class CityPainter extends CustomPainter {
  const CityPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = MapColors.land);

    // Göl ve kıyı.
    final water = Paint()..color = MapColors.water;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.42)
        ..cubicTo(w * 0.18, h * 0.40, w * 0.24, h * 0.55, w * 0.16, h * 0.66)
        ..cubicTo(w * 0.10, h * 0.74, w * 0.22, h * 0.80, w * 0.30, h * 0.78)
        ..lineTo(0, h * 0.86)
        ..close(),
      water,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.86)
        ..cubicTo(w * 0.3, h * 0.80, w * 0.6, h * 0.84, w, h * 0.74)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      water,
    );

    // Parklar.
    final park = Paint()..color = MapColors.park;
    canvas.drawOval(
      Rect.fromLTWH(w * 0.52, h * 0.04, w * 0.22, h * 0.22),
      park,
    );
    canvas.drawOval(
      Rect.fromLTWH(w * 0.30, h * 0.56, w * 0.10, h * 0.08),
      park,
    );
    canvas.drawOval(Rect.fromLTWH(w * 0.80, h * 0.36, w * 0.14, h * 0.1), park);

    // Ara sokaklar: hafif eğik, düzensiz ızgara.
    final rnd = Random(7);
    final street = Paint()
      ..color = MapColors.street
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 26; i++) {
      final x = w * (i / 26) + rnd.nextDouble() * 12;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + (rnd.nextDouble() - 0.5) * w * 0.2, h * 0.84),
        street,
      );
    }
    for (var i = 0; i < 22; i++) {
      final y = h * 0.84 * (i / 22) + rnd.nextDouble() * 10;
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y + (rnd.nextDouble() - 0.5) * h * 0.12),
        street,
      );
    }

    // Ana yollar.
    final road = Paint()
      ..color = MapColors.road
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.30)
        ..cubicTo(w * 0.3, h * 0.26, w * 0.6, h * 0.34, w, h * 0.22),
      road,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, 0)
        ..cubicTo(w * 0.48, h * 0.3, w * 0.56, h * 0.5, w * 0.54, h * 0.82),
      road,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.2, h * 0.84)
        ..cubicTo(w * 0.5, h * 0.66, w * 0.8, h * 0.66, w, h * 0.5),
      road,
    );
  }

  @override
  bool shouldRepaint(CityPainter oldDelegate) => false;
}
