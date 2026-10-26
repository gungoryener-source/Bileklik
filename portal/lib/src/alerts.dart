import 'model.dart';
import 'store.dart';

/// Hekimin rızalı hastalarının verisinden uyarı üretir.
///
/// Kurallar (eşikler [AlertRules] içinde):
/// - SpO2 en az 10 dk %90 altında,
/// - nabız en az 10 dk 120 üstünde (egzersiz sırasında değil) ya da 40 altında,
/// - tansiyon 180/120 ve üstü (bileklikten tahmini değer),
/// - vücut ısısı 38 °C ve üstü,
/// - 24 saattir veri gelmiyor.
///
/// Yalnızca hekimin süren rızasındaki türlere bakılır. Aynı türde bir saat
/// içinde süren olay yeni uyarı açmaz, açık uyarıyı günceller. Karar destek
/// içindir, tanı koymaz.
class AlertEngine {
  AlertEngine(this.store, {this.rules = const AlertRules()});

  final PortalStore store;
  final AlertRules rules;

  /// Taranan geçmiş: son ölçümlerden geriye.
  static const window = Duration(hours: 48);

  /// Hekimlerin uyarılarını günceller. [patientId] verilirse yalnızca o
  /// hasta (veri yüklendiğinde), [ownerId] verilirse yalnızca o hekim
  /// (panel açıldığında) taranır. Yeni açılan uyarıları döner.
  List<Alert> scan(DateTime now, {String? patientId, String? ownerId}) {
    final created = <Alert>[];
    final owners = ownerId != null
        ? [?store.account(ownerId)]
        : store.clinicians();
    for (final owner in owners) {
      if (owner.role != Role.clinician) continue;
      final consents = [
        for (final c in store.consentsForActor(owner.id))
          if (c.activeAt(now) &&
              (patientId == null || c.patientId == patientId))
            c,
      ];
      for (final c in consents) {
        created.addAll(_scanPatient(owner.id, c, now));
      }
    }
    return created;
  }

  List<Alert> _scanPatient(String ownerId, Consent c, DateTime now) {
    final codes = c.codes;
    final existing = [
      for (final a in store.alertsOf(ownerId))
        if (a.patientId == c.patientId) a,
    ];
    final out = <Alert>[];

    void raise(_Episode e) {
      // Aynı türde, bir saat içinde süren olay aynı uyarıdır.
      final same = existing
          .where(
            (a) =>
                a.kind == e.kind &&
                a.resolvedAt == null &&
                !a.lastSeen.isBefore(e.start.subtract(rules.mergeGap)),
          )
          .firstOrNull;
      if (same != null) {
        if (e.end.isAfter(same.lastSeen)) {
          final worse = switch (e.kind) {
            AlertKind.spo2Low ||
            AlertKind.heartRateLow => e.value < (same.value ?? double.infinity),
            _ => e.value > (same.value ?? double.negativeInfinity),
          };
          store.putAlert(
            same.copyWith(
              lastSeen: e.end,
              value: worse ? e.value : null,
              value2: worse ? e.value2 : null,
            ),
          );
        }
        return;
      }
      final a = Alert(
        id: store.nextId('al'),
        ownerId: ownerId,
        patientId: c.patientId,
        kind: e.kind,
        start: e.start,
        lastSeen: e.end,
        created: now,
        value: e.value,
        value2: e.value2,
      );
      store.putAlert(a);
      existing.add(a);
      out.add(a);
    }

    final recent = store.observations(
      c.patientId,
      codes: codes,
      from: now.subtract(window),
      to: now.add(const Duration(minutes: 1)),
    )..sort((a, b) => a.effective.compareTo(b.effective));
    List<(DateTime, double)> series(String code) => [
      for (final o in recent)
        if (o.code == code)
          if (_value(o.resource) case final v?) (o.effective, v),
    ];

    for (final e in _runs(
      series('59408-5'),
      (v) => v > 0 && v < rules.spo2Below,
      AlertKind.spo2Low,
      lowest: true,
    )) {
      raise(e);
    }

    // Egzersiz sırasındaki yüksek nabız uyarı sayılmaz (etkinlik
    // paylaşılmıyorsa egzersiz bilinmez; o zaman her yüksek nabız sayılır).
    final workouts = [
      for (final o in recent)
        if (o.code == 'workout') (o.effective, _end(o.resource) ?? o.effective),
    ];
    bool inWorkout(DateTime t) => workouts.any(
      (w) =>
          !t.isBefore(w.$1.subtract(const Duration(minutes: 5))) &&
          !t.isAfter(w.$2.add(const Duration(minutes: 15))),
    );
    final hr = [
      for (final r in series('8867-4'))
        if (!inWorkout(r.$1)) r,
    ];
    for (final e in _runs(
      hr,
      (v) => v > rules.heartRateAbove,
      AlertKind.heartRateHigh,
    )) {
      raise(e);
    }
    for (final e in _runs(
      hr,
      (v) => v > 0 && v < rules.heartRateBelow,
      AlertKind.heartRateLow,
      lowest: true,
    )) {
      raise(e);
    }

    for (final o in recent) {
      if (o.code != '85354-9') continue;
      final s = _component(o.resource, '8480-6');
      final d = _component(o.resource, '8462-4');
      if (s == null || d == null) continue;
      if (s >= rules.systolicCrisis || d >= rules.diastolicCrisis) {
        raise(
          _Episode(
            AlertKind.bloodPressureCrisis,
            o.effective,
            o.effective,
            s,
            d,
          ),
        );
      }
    }

    for (final (t, v) in series('8310-5')) {
      if (v >= rules.feverFrom) {
        raise(_Episode(AlertKind.fever, t, t, v));
      }
    }

    // Veri gelmemesi: rızadaki türlerin en son ölçümü.
    final last = store
        .observations(c.patientId, codes: codes)
        .map((o) => o.effective)
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    final openNoData = existing
        .where((a) => a.kind == AlertKind.noData && a.resolvedAt == null)
        .firstOrNull;
    if (openNoData != null && last != null && last.isAfter(openNoData.start)) {
      // Veri yeniden geldi: uyarı kendiliğinden kapanır.
      store.putAlert(openNoData.copyWith(resolvedAt: now));
    } else if (openNoData == null) {
      final since = last ?? c.start;
      if (now.difference(since) >= rules.noDataAfter) {
        raise(_Episode(AlertKind.noData, since, since, 0));
      }
    }
    return out;
  }

  /// Eşiği aşan ardışık ölçümlerden en az [AlertRules.sustained] süren
  /// diziler. Arada eşiği aşmayan bir ölçüm diziyi böler.
  Iterable<_Episode> _runs(
    List<(DateTime, double)> readings,
    bool Function(double) over,
    AlertKind kind, {
    bool lowest = false,
  }) sync* {
    (DateTime, DateTime, double)? run;
    for (final (t, v) in [...readings, (DateTime(9999), double.nan)]) {
      if (!v.isNaN && over(v)) {
        final r = run;
        run = r == null
            ? (t, t, v)
            : (r.$1, t, lowest ? (v < r.$3 ? v : r.$3) : (v > r.$3 ? v : r.$3));
        continue;
      }
      final r = run;
      if (r != null && r.$2.difference(r.$1) >= rules.sustained) {
        yield _Episode(kind, r.$1, r.$2, r.$3);
      }
      run = null;
    }
  }

  /// Hekimin "Gördüm" demesi: uyarı kapanır, kim ve ne zaman kaydı kalır.
  /// Uyarı hekimin değilse ya da zaten kapandıysa null.
  Alert? acknowledge(String alertId, String byId, String? note, DateTime now) {
    final a = store.alert(alertId);
    if (a == null || a.ownerId != byId || !a.open) return null;
    final trimmed = note?.trim();
    final updated = a.copyWith(
      ackAt: now,
      ackBy: byId,
      note: trimmed == null || trimmed.isEmpty
          ? null
          : (trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed),
    );
    store.putAlert(updated);
    return updated;
  }

  static double? _value(Map<String, Object?> r) =>
      ((r['valueQuantity'] as Map?)?['value'] as num?)?.toDouble();

  static double? _component(Map<String, Object?> r, String code) {
    for (final c in (r['component'] as List?) ?? const []) {
      if (c is! Map) continue;
      final coding = ((c['code'] as Map?)?['coding'] as List?)?.firstOrNull;
      if (coding is Map && coding['code'] == code) {
        return ((c['valueQuantity'] as Map?)?['value'] as num?)?.toDouble();
      }
    }
    return null;
  }

  static DateTime? _end(Map<String, Object?> r) =>
      switch ((r['effectivePeriod'] as Map?)?['end']) {
        final String s => DateTime.tryParse(s),
        _ => null,
      };
}

/// Uyarı eşikleri. Klinik danışmanla gözden geçirilecek.
class AlertRules {
  const AlertRules({
    this.spo2Below = 90,
    this.heartRateAbove = 120,
    this.heartRateBelow = 40,
    this.systolicCrisis = 180,
    this.diastolicCrisis = 120,
    this.feverFrom = 38,
    this.sustained = const Duration(minutes: 10),
    this.noDataAfter = const Duration(hours: 24),
    this.mergeGap = const Duration(hours: 1),
    this.overdueAfter = const Duration(minutes: 15),
  });

  final double spo2Below;
  final double heartRateAbove;
  final double heartRateBelow;
  final double systolicCrisis;
  final double diastolicCrisis;
  final double feverFrom;

  /// SpO2 ve nabız kurallarında olayın en az süresi.
  final Duration sustained;
  final Duration noDataAfter;

  /// Bu kadar içinde süren aynı tür olay aynı uyarıdır.
  final Duration mergeGap;

  /// Kritik uyarı bu süre yanıtlanmazsa panoda "gecikti" olur.
  final Duration overdueAfter;
}

class _Episode {
  const _Episode(this.kind, this.start, this.end, this.value, [this.value2]);

  final AlertKind kind;
  final DateTime start;
  final DateTime end;
  final double value;
  final double? value2;
}
