import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'community.dart';

/// Bir kişinin paylaşılan son konumu.
@immutable
class SharedLocation {
  const SharedLocation({
    required this.latitude,
    required this.longitude,
    required this.time,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;

  /// Konumun alındığı an.
  final DateTime time;
  final double? accuracyMeters;
}

/// Konumun alınamama nedeni.
enum LocationProblem { serviceOff, denied, deniedForever, failed }

class LocationException implements Exception {
  const LocationException(this.problem);
  final LocationProblem problem;

  @override
  String toString() => 'LocationException(${problem.name})';
}

/// Telefonun konumu. Telefonda [PhoneLocationSource], web ve testlerde
/// [FakeLocationSource].
abstract class LocationSource {
  /// Uygulamanın kullandığı kaynak; `main` telefonda gerçeğini koyar.
  static LocationSource instance = FakeLocationSource();

  /// İzin gerekiyorsa ister; alınamazsa [LocationException].
  Future<SharedLocation> current();
}

/// geolocator ile telefonun konumu; yalnızca uygulama açıkken.
class PhoneLocationSource implements LocationSource {
  @override
  Future<SharedLocation> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationProblem.serviceOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        throw const LocationException(LocationProblem.denied);
      case LocationPermission.deniedForever:
        throw const LocationException(LocationProblem.deniedForever);
      default:
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return SharedLocation(
        latitude: p.latitude,
        longitude: p.longitude,
        time: p.timestamp,
        accuracyMeters: p.accuracy,
      );
    } catch (_) {
      throw const LocationException(LocationProblem.failed);
    }
  }
}

/// İstanbul merkezinde, her çağrıda biraz oynayan sahte konum.
class FakeLocationSource implements LocationSource {
  FakeLocationSource({Random? random, DateTime Function()? clock})
    : _random = random ?? Random(3),
      _now = clock ?? DateTime.now;

  final Random _random;
  final DateTime Function() _now;

  @override
  Future<SharedLocation> current() async => SharedLocation(
    latitude: 41.0082 + (_random.nextDouble() - 0.5) * 0.004,
    longitude: 28.9784 + (_random.nextDouble() - 0.5) * 0.004,
    time: _now(),
    accuracyMeters: 15,
  );
}

/// Paylaşım açıkken konumu uygulama açık olduğu sürece [interval] arayla
/// alır ve topluluk sunucusuna gönderir. Paylaşım kapanınca durur.
class LocationReporter {
  LocationReporter(
    this.community, {
    LocationSource? source,
    this.interval = const Duration(minutes: 5),
  }) : _source = source ?? LocationSource.instance {
    community.addListener(_onChange);
    _onChange();
  }

  final CommunityService community;
  final LocationSource _source;
  final Duration interval;
  Timer? _timer;
  bool _busy = false;

  void _onChange() {
    final on = community.sharingLocation;
    if (on && _timer == null) {
      _timer = Timer.periodic(interval, (_) => report());
      unawaited(report());
    } else if (!on && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  /// Konumu hemen alıp gönderir; hata topluluk hizmetinde saklanır.
  Future<void> report() async {
    if (_busy || !community.sharingLocation) return;
    _busy = true;
    try {
      final loc = await _source.current();
      if (community.sharingLocation) await community.updateMyLocation(loc);
    } on LocationException catch (e) {
      community.reportLocationProblem(e.problem);
    } finally {
      _busy = false;
    }
  }

  void dispose() {
    community.removeListener(_onChange);
    _timer?.cancel();
  }
}
