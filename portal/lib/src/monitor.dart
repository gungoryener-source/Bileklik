/// Hekim panelinin izlem hesapları: her hastanın durumu, bu durumun
/// dayanağı olan sinyaller, uyum (bileklikten veri gelen günler), son
/// değerler ve panelin genel tablosu.
///
/// Kurallar:
/// - Yalnızca hekimin süren rızasındaki türler okunur.
/// - Her sinyal sayılarla birlikte gelir (kaç okuma, hangi eşik, kaç gün);
///   ekranda dayanağı gösterilir. Tanı değildir, eşikler rapordaki
///   ([PatientReport]) ve uyarı panosundaki ([AlertRules]) eşiklerdir.
/// - Veri yetersizse sinyal üretilmez; karşılaştırma için iki dönemde de
///   yeterli okuma gerekir.
///
/// Burada metin ya da HTML yok; ekran `panel_overview.dart` ve
/// `panel_monitor.dart` içinde.
library;

import 'dart:math';

import 'model.dart';
import 'report.dart';
import 'store.dart';

/// Hastanın izlem durumu; sıra öncelik sırasıdır.
enum MonitorStatus {
  /// Açık kritik uyarı var.
  critical,

  /// Hekimin bakması gereken bir sinyal: yinelenen eşik dışı değer, 24
  /// saattir veri yok, belirgin kilo değişimi, geciken görev, açık uyarı.
  attention,

  /// İzlenecek: tek eşik dışı değer, düşük uyum ya da kötüleşen eğilim.
  watch,

  /// Veri geliyor ve sinyal yok.
  stable,

  /// İzlenmiyor: rıza yok, bitti ya da davet bekliyor.
  inactive,
}

/// Bir sinyalin türü. Her biri ölçülebilir bir dayanağa dayanır.
enum SignalKind {
  criticalAlert,
  warningAlert,
  noData,
  highHeartRate,
  lowHeartRate,
  lowSpo2,
  highBloodPressure,
  fever,
  weightChange,
  restingHrRise,
  activityDrop,
  lowAdherence,
  overdueTask,
}

/// Panelde izlenen ölçüm türleri (anahtar, Observation kodu).
enum Vital {
  heartRate('8867-4'),
  spo2('59408-5'),
  bloodPressure('85354-9'),
  temperature('8310-5'),
  respiration('9279-1'),
  hrv('80404-7'),
  stress('stress'),
  steps('55423-8'),
  sleep('93832-4'),
  weight('29463-7');

  const Vital(this.code);
  final String code;

  static Vital? byCode(String code) {
    for (final v in values) {
      if (v.code == code) return v;
    }
    return null;
  }

  /// Gün içinde toplanan tür (adım).
  bool get summed => this == Vital.steps;
}

class Signal {
  const Signal(
    this.kind,
    this.level, {
    this.n,
    this.total,
    this.value,
    this.value2,
    this.vital,
    this.at,
  });

  final SignalKind kind;

  /// Bu sinyalin hastayı taşıdığı durum (critical, attention ya da watch).
  final MonitorStatus level;

  /// Sayım: eşik dışı okuma, saat, gün ya da görev sayısı.
  final int? n;

  /// Sayımın paydası (ör. 14 günün kaçı).
  final int? total;

  /// En uç değer ya da değişim (ör. +2,4 kg, +6 atım/dk, -%35).
  final double? value, value2;

  /// İlgili ölçüm; hasta sayfasında o grafiği açar.
  final Vital? vital;

  /// İlgili an (son veri, en uç okumanın zamanı).
  final DateTime? at;
}

/// Bir türün son değeri, son 7 günün günlük değerleri ve iki haftalık
/// karşılaştırma.
class VitalSummary {
  const VitalSummary({
    required this.vital,
    required this.latest,
    required this.latestAt,
    required this.daily,
    this.latest2,
    this.thisWeek,
    this.lastWeek,
  });

  final Vital vital;
  final double latest;

  /// Tansiyonda diyastolik.
  final double? latest2;
  final DateTime latestAt;

  /// Son 7 günün (eskiden yeniye) günlük ortalaması ya da toplamı; veri
  /// olmayan gün null.
  final List<double?> daily;

  /// Son 7 ve önceki 7 günün ortalaması (toplanan türde günlük toplamların
  /// ortalaması); yeterli veri yoksa null.
  final double? thisWeek, lastWeek;

  double? get change =>
      thisWeek == null || lastWeek == null ? null : thisWeek! - lastWeek!;
}

/// Neden izlenmiyor.
enum InactiveReason { pendingInvite, consentEnded, notLinked }

class PatientSnapshot {
  const PatientSnapshot({
    required this.record,
    required this.patientId,
    required this.consent,
    required this.status,
    required this.signals,
    required this.vitals,
    required this.coverage,
    this.lastData,
    this.inactive,
    this.openCritical = 0,
    this.openWarning = 0,
    this.openTasks = 0,
    this.overdueTasks = 0,
  });

  /// Hekimin hasta kaydı; kayda bağlanmamış bağlantıda null.
  final PatientRecord? record;
  final String? patientId;
  final Consent? consent;
  final MonitorStatus status;

  /// Önce en ağır olan.
  final List<Signal> signals;
  final Map<Vital, VitalSummary> vitals;

  /// Son [MonitorBoard.window] günün her biri için veri geldi mi (eskiden
  /// yeniye). İzlenmeyen hastada boş.
  final List<bool> coverage;
  final DateTime? lastData;
  final InactiveReason? inactive;
  final int openCritical, openWarning, openTasks, overdueTasks;

  bool get monitored => status != MonitorStatus.inactive;

  /// Veri gelen gün sayısı.
  int get adherenceDays => coverage.where((d) => d).length;

  /// Uyum oranı (0-1); izlenmiyorsa null.
  double? get adherence =>
      coverage.isEmpty ? null : adherenceDays / coverage.length;

  /// Sıralama ve arama için ad; kaydı yoksa takma kimliğin başı.
  String get displayName =>
      record?.name ??
      (patientId!.length > 8 ? patientId!.substring(0, 8) : patientId!);

  /// Listedeki satırın kimliği: kayıt ya da takma kimlik.
  String get key => record?.id ?? 'p:$patientId';
}

/// Paneldeki genel tablo: tüm hastaların durumu, kapsama ve uyarı eğilimi.
class MonitorBoard {
  MonitorBoard._({
    required this.now,
    required this.patients,
    required this.coverageDaily,
    required this.alertsDaily,
    required this.monitoredDaily,
  });

  /// Uyum ve kapsamanın hesaplandığı gün sayısı.
  static const window = 14;

  /// Eşik dışı okumanın aranacağı süre.
  static const signalDays = 7;

  /// Eşikler: rapordaki tarama eşikleri.
  static const highHr = PatientReport.tachycardiaAbove;
  static const lowHr = PatientReport.bradycardiaBelow;
  static const lowSpo2 = PatientReport.lowSpo2Below;
  static const feverFrom = PatientReport.feverFrom;
  static const systolicHigh = 140.0, diastolicHigh = 90.0;
  static const weightKg = PatientReport.weightChangeKg;

  /// Aynı eşiği bu kadar ya da daha çok aşan okuma "yinelenen" sayılır.
  static const repeated = 3;
  static const restingRise = 5.0;
  static const activityDropPct = 30.0;
  static const adherenceMin = 0.7;
  static const noDataHours = 24;

  final DateTime now;

  /// Öncelik sırasıyla: durum, sonra en yeni sinyal, sonra ad.
  final List<PatientSnapshot> patients;

  /// Son [window] günün her biri için verisi gelen izlenen hasta sayısı.
  final List<int> coverageDaily;

  /// Her gün o gün rızası süren hasta sayısı (kapsama oranının paydası).
  final List<int> monitoredDaily;

  /// Son [window] günün her birinde açılan uyarı sayısı.
  final List<int> alertsDaily;

  Map<MonitorStatus, int> get counts => {
    for (final s in MonitorStatus.values)
      s: patients.where((p) => p.status == s).length,
  };

  Iterable<PatientSnapshot> get monitored => patients.where((p) => p.monitored);

  /// Son 24 saatte verisi gelen izlenen hasta sayısı.
  int get fresh => monitored
      .where(
        (p) =>
            p.lastData != null &&
            now.difference(p.lastData!) < const Duration(hours: 24),
      )
      .length;

  /// İzlenen hastaların ortalama uyumu (0-1).
  double? get meanAdherence {
    final list = [for (final p in monitored) ?p.adherence];
    return list.isEmpty ? null : list.reduce((a, b) => a + b) / list.length;
  }

  /// Hekimin bütün hastalarını tarar. [alerts] hekimin uyarıları
  /// (`store.alertsOf`); [overdue] kritik uyarının "gecikti" süresi.
  static MonitorBoard build(PortalStore store, String ownerId, DateTime now) {
    final alerts = store.alertsOf(ownerId);
    final records = store.recordsOf(ownerId);
    final consents = [
      for (final k in store.consentsForActor(ownerId))
        if (k.activeAt(now)) k,
    ];
    final linked = {for (final r in records) ?r.patientId};
    final today = _day(now);
    final first = today.subtract(const Duration(days: window - 1));

    final out = <PatientSnapshot>[];
    for (final rec in records) {
      final pid = rec.patientId;
      final k = pid == null
          ? null
          : consents.where((c) => c.patientId == pid).firstOrNull;
      if (pid == null || k == null) {
        final code = rec.inviteCode;
        final invite = code == null ? null : store.invite(code);
        out.add(
          PatientSnapshot(
            record: rec,
            patientId: pid,
            consent: null,
            status: MonitorStatus.inactive,
            signals: const [],
            vitals: const {},
            coverage: const [],
            inactive: pid != null
                ? InactiveReason.consentEnded
                : invite != null && now.isBefore(invite.expires)
                ? InactiveReason.pendingInvite
                : InactiveReason.notLinked,
            openTasks: store.careOf(rec.id).where((e) => e.open).length,
            overdueTasks: store
                .careOf(rec.id)
                .where((e) => e.open && e.overdueAt(now))
                .length,
          ),
        );
        continue;
      }
      out.add(_snapshot(store, rec, pid, k, alerts, now, first));
    }
    for (final k in consents) {
      if (linked.contains(k.patientId)) continue;
      out.add(_snapshot(store, null, k.patientId, k, alerts, now, first));
    }
    out.sort(compare);

    final coverage = List.filled(window, 0);
    final monitoredDaily = List.filled(window, 0);
    for (final p in out) {
      if (!p.monitored) continue;
      for (var i = 0; i < p.coverage.length; i++) {
        if (p.coverage[i]) coverage[i]++;
      }
      final start = _day(p.consent!.start);
      for (var i = 0; i < window; i++) {
        if (!first.add(Duration(days: i)).isBefore(start)) monitoredDaily[i]++;
      }
    }
    final alertsDaily = List.filled(window, 0);
    for (final a in alerts) {
      final i = _day(a.created).difference(first).inDays;
      if (i >= 0 && i < window) alertsDaily[i]++;
    }
    return MonitorBoard._(
      now: now,
      patients: out,
      coverageDaily: coverage,
      monitoredDaily: monitoredDaily,
      alertsDaily: alertsDaily,
    );
  }

  /// Öncelik: durum, açık kritik uyarı sayısı, sinyal sayısı, ad.
  static int compare(PatientSnapshot a, PatientSnapshot b) {
    final s = a.status.index.compareTo(b.status.index);
    if (s != 0) return s;
    final c = b.openCritical.compareTo(a.openCritical);
    if (c != 0) return c;
    final n = b.signals.length.compareTo(a.signals.length);
    if (n != 0) return n;
    return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
  }

  static PatientSnapshot _snapshot(
    PortalStore store,
    PatientRecord? rec,
    String pid,
    Consent consent,
    List<Alert> alerts,
    DateTime now,
    DateTime first,
  ) {
    final from = _day(now).subtract(const Duration(days: window * 2 - 1));
    final items = store.observations(
      pid,
      codes: consent.codes,
      from: from,
      to: now,
    );
    final lastData = items.fold<DateTime?>(
      null,
      (a, o) => a == null || o.effective.isAfter(a) ? o.effective : a,
    );
    final days = <DateTime>{for (final o in items) _day(o.effective)};
    final coverage = [
      for (var i = 0; i < window; i++)
        days.contains(first.add(Duration(days: i))),
    ];
    final vitals = summarize(items, now);
    final signals = <Signal>[];

    final open = [
      for (final a in alerts)
        if (a.patientId == pid && a.open) a,
    ];
    final crit = open
        .where((a) => a.kind.severity == AlertSeverity.critical)
        .length;
    final warn = open.length - crit;
    if (crit > 0) {
      signals.add(
        Signal(
          SignalKind.criticalAlert,
          MonitorStatus.critical,
          n: crit,
          at: open.map((a) => a.created).reduce((a, b) => a.isAfter(b) ? a : b),
          vital: _alertVital(
            open.firstWhere((a) => a.kind.severity == AlertSeverity.critical),
          ),
        ),
      );
    }
    if (warn > 0) {
      signals.add(
        Signal(SignalKind.warningAlert, MonitorStatus.attention, n: warn),
      );
    }

    // Veri gelmiyor.
    final silent = lastData == null ? null : now.difference(lastData).inHours;
    if (lastData == null) {
      // Rıza yeni ve hiç veri yok: izlenecek.
      signals.add(const Signal(SignalKind.noData, MonitorStatus.watch));
    } else if (silent! >= noDataHours) {
      signals.add(
        Signal(
          SignalKind.noData,
          MonitorStatus.attention,
          n: silent,
          at: lastData,
        ),
      );
    }

    // Son 7 günde eşik dışı okumalar; egzersiz sırasındaki nabız sayılmaz.
    final since = now.subtract(const Duration(days: signalDays));
    final recent = [
      for (final o in items)
        if (!o.effective.isBefore(since)) o,
    ];
    final workouts = [
      for (final o in recent)
        if (o.code == 'workout') (o.effective, _end(o.resource) ?? o.effective),
    ];
    bool inWorkout(DateTime t) =>
        workouts.any((w) => !t.isBefore(w.$1) && !t.isAfter(w.$2));
    void threshold(
      SignalKind kind,
      Vital vital,
      bool Function(double) test, {
      required bool high,
      bool restOnly = false,
    }) {
      final hits = <(DateTime, double)>[];
      for (final o in recent) {
        if (o.code != vital.code) continue;
        final v = _value(o.resource);
        if (v == null || !test(v)) continue;
        if (restOnly && inWorkout(o.effective)) continue;
        hits.add((o.effective, v));
      }
      if (hits.isEmpty) return;
      final worst = hits.reduce(
        (a, b) => (high ? b.$2 > a.$2 : b.$2 < a.$2) ? b : a,
      );
      signals.add(
        Signal(
          kind,
          hits.length >= repeated
              ? MonitorStatus.attention
              : MonitorStatus.watch,
          n: hits.length,
          value: worst.$2,
          vital: vital,
          at: worst.$1,
        ),
      );
    }

    threshold(
      SignalKind.highHeartRate,
      Vital.heartRate,
      (v) => v > highHr,
      high: true,
      restOnly: true,
    );
    threshold(
      SignalKind.lowHeartRate,
      Vital.heartRate,
      (v) => v > 0 && v < lowHr,
      high: false,
    );
    threshold(SignalKind.lowSpo2, Vital.spo2, (v) => v < lowSpo2, high: false);
    threshold(
      SignalKind.fever,
      Vital.temperature,
      (v) => v >= feverFrom,
      high: true,
    );
    final bpHits = <(DateTime, double, double)>[];
    for (final o in recent) {
      if (o.code != Vital.bloodPressure.code) continue;
      final s = _component(o.resource, '8480-6');
      final d = _component(o.resource, '8462-4');
      if (s == null || d == null) continue;
      if (s >= systolicHigh || d >= diastolicHigh) {
        bpHits.add((o.effective, s, d));
      }
    }
    if (bpHits.isNotEmpty) {
      final worst = bpHits.reduce((a, b) => b.$2 > a.$2 ? b : a);
      signals.add(
        Signal(
          SignalKind.highBloodPressure,
          bpHits.length >= repeated
              ? MonitorStatus.attention
              : MonitorStatus.watch,
          n: bpHits.length,
          value: worst.$2,
          value2: worst.$3,
          vital: Vital.bloodPressure,
          at: worst.$1,
        ),
      );
    }

    // Kilo: 14 gün içindeki ilk ve son tartı.
    final weights = [
      for (final o in items)
        if (o.code == Vital.weight.code &&
            !o.effective.isBefore(now.subtract(const Duration(days: window))))
          if (_value(o.resource) case final v?) (o.effective, v),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    if (weights.length >= 2) {
      final delta = weights.last.$2 - weights.first.$2;
      if (delta.abs() >= weightKg) {
        signals.add(
          Signal(
            SignalKind.weightChange,
            MonitorStatus.attention,
            value: delta,
            n: weights.last.$1.difference(weights.first.$1).inDays,
            vital: Vital.weight,
            at: weights.last.$1,
          ),
        );
      }
    }

    // Dinlenik nabız (okumaların 10. yüzdeliği) haftadan haftaya.
    final rest = restingByWeek(items, now);
    if (rest != null && rest.$1 - rest.$2 >= restingRise) {
      signals.add(
        Signal(
          SignalKind.restingHrRise,
          MonitorStatus.watch,
          value: rest.$1 - rest.$2,
          value2: rest.$1,
          vital: Vital.heartRate,
        ),
      );
    }

    // Adım: haftalık günlük ortalama %30'dan fazla düştüyse.
    final steps = vitals[Vital.steps];
    if (steps?.thisWeek case final cur?) {
      final prev = steps!.lastWeek;
      if (prev != null && prev > 0) {
        final pct = (cur - prev) / prev * 100;
        if (pct <= -activityDropPct) {
          signals.add(
            Signal(
              SignalKind.activityDrop,
              MonitorStatus.watch,
              value: pct,
              value2: cur,
              vital: Vital.steps,
            ),
          );
        }
      }
    }

    // Uyum: rıza başladıktan sonraki günler sayılır.
    final consentDays = min(
      window,
      _day(now).difference(_day(consent.start)).inDays + 1,
    );
    final have = coverage.skip(window - consentDays).where((d) => d).length;
    if (consentDays >= 3 && have / consentDays < adherenceMin) {
      signals.add(
        Signal(
          SignalKind.lowAdherence,
          MonitorStatus.watch,
          n: have,
          total: consentDays,
        ),
      );
    }

    var openTasks = 0, overdue = 0;
    if (rec != null) {
      for (final e in store.careOf(rec.id)) {
        if (!e.open) continue;
        openTasks++;
        if (e.overdueAt(now)) overdue++;
      }
      if (overdue > 0) {
        signals.add(
          Signal(SignalKind.overdueTask, MonitorStatus.attention, n: overdue),
        );
      }
    }

    signals.sort((a, b) {
      final l = a.level.index.compareTo(b.level.index);
      return l != 0 ? l : a.kind.index.compareTo(b.kind.index);
    });
    final status = signals.isEmpty ? MonitorStatus.stable : signals.first.level;
    return PatientSnapshot(
      record: rec,
      patientId: pid,
      consent: consent,
      status: status,
      signals: signals,
      vitals: vitals,
      coverage: coverage,
      lastData: lastData,
      openCritical: crit,
      openWarning: warn,
      openTasks: openTasks,
      overdueTasks: overdue,
    );
  }

  static Vital? _alertVital(Alert a) => switch (a.kind) {
    AlertKind.spo2Low => Vital.spo2,
    AlertKind.heartRateHigh || AlertKind.heartRateLow => Vital.heartRate,
    AlertKind.bloodPressureCrisis => Vital.bloodPressure,
    AlertKind.fever => Vital.temperature,
    AlertKind.noData => null,
  };

  /// Son 7 ve önceki 7 günün dinlenik nabzı; ikisinde de en az 10 okuma
  /// yoksa null.
  static (double, double)? restingByWeek(
    List<StoredObservation> items,
    DateTime now,
  ) {
    final cut = now.subtract(const Duration(days: 7));
    final prevCut = now.subtract(const Duration(days: 14));
    final cur = <double>[], prev = <double>[];
    for (final o in items) {
      if (o.code != Vital.heartRate.code) continue;
      final v = _value(o.resource);
      if (v == null || v <= 0) continue;
      if (!o.effective.isBefore(cut)) {
        cur.add(v);
      } else if (!o.effective.isBefore(prevCut)) {
        prev.add(v);
      }
    }
    if (cur.length < 10 || prev.length < 10) return null;
    double p10(List<double> l) => (l..sort())[l.length ~/ 10];
    return (p10(cur), p10(prev));
  }

  /// Her türün son değeri ve günlük özeti.
  static Map<Vital, VitalSummary> summarize(
    List<StoredObservation> items,
    DateTime now,
  ) {
    final today = _day(now);
    final byVital = <Vital, List<StoredObservation>>{};
    for (final o in items) {
      final v = Vital.byCode(o.code);
      if (v != null) byVital.putIfAbsent(v, () => []).add(o);
    }
    final out = <Vital, VitalSummary>{};
    for (final e in byVital.entries) {
      final vital = e.key;
      final list = e.value..sort((a, b) => a.effective.compareTo(b.effective));
      final perDay = <int, List<double>>{};
      double? latest, latest2;
      DateTime? at;
      for (final o in list) {
        final double? v;
        double? v2;
        if (vital == Vital.bloodPressure) {
          v = _component(o.resource, '8480-6');
          v2 = _component(o.resource, '8462-4');
        } else {
          v = _value(o.resource);
        }
        if (v == null) continue;
        latest = v;
        latest2 = v2;
        at = o.effective;
        final ago = today.difference(_day(o.effective)).inDays;
        if (ago >= 0 && ago < 14) perDay.putIfAbsent(ago, () => []).add(v);
      }
      if (latest == null) continue;
      double agg(List<double> l) => vital.summed
          ? l.reduce((a, b) => a + b)
          : l.reduce((a, b) => a + b) / l.length;
      final daily = [
        for (var ago = 6; ago >= 0; ago--)
          perDay[ago] == null ? null : agg(perDay[ago]!),
      ];
      double? mean(int fromAgo, int toAgo, {bool skipToday = false}) {
        final vals = [
          for (var ago = fromAgo; ago <= toAgo; ago++)
            if (!(skipToday && ago == 0))
              if (perDay[ago] case final l?) agg(l),
        ];
        return vals.length < 3
            ? null
            : vals.reduce((a, b) => a + b) / vals.length;
      }

      // Toplanan türde bugün henüz bitmedi; karşılaştırmaya girmez.
      final summed = vital.summed;
      out[vital] = VitalSummary(
        vital: vital,
        latest: latest,
        latest2: latest2,
        latestAt: at!,
        daily: daily,
        thisWeek: summed ? mean(1, 7) : mean(0, 6),
        lastWeek: summed ? mean(8, 13) : mean(7, 13),
      );
    }
    return out;
  }

  static DateTime _day(DateTime t) {
    final l = t.toLocal();
    return DateTime(l.year, l.month, l.day);
  }
}

double? _value(Map<String, Object?> r) =>
    ((r['valueQuantity'] as Map?)?['value'] as num?)?.toDouble();

double? _component(Map<String, Object?> r, String code) {
  for (final c in (r['component'] as List?)?.cast<Map>() ?? const <Map>[]) {
    final coding = ((c['code'] as Map?)?['coding'] as List?)?.firstOrNull;
    if (coding is Map && coding['code'] == code) {
      return ((c['valueQuantity'] as Map?)?['value'] as num?)?.toDouble();
    }
  }
  return null;
}

DateTime? _end(Map<String, Object?> r) {
  final end = (r['effectivePeriod'] as Map?)?['end'];
  return end is String ? DateTime.tryParse(end) : null;
}

/// Panelin etkinlik akışındaki olay türleri.
enum ActivityKind {
  alertRaised,
  alertAcked,
  alertResolved,
  note,
  taskAdded,
  taskDone,
  consentStarted,
  recordCreated,
  dataReceived,
}

class ActivityEvent {
  const ActivityEvent(
    this.kind,
    this.time, {
    this.patientId,
    this.recordId,
    this.text,
    this.alert,
    this.n,
  });

  final ActivityKind kind;
  final DateTime time;
  final String? patientId;
  final String? recordId;

  /// Not ya da görev metni, uyarı notu.
  final String? text;
  final Alert? alert;

  /// Veri alımında son 24 saatteki ölçüm sayısı.
  final int? n;
}

/// Hekimin son [days] gündeki olayları, en yeni önce. Veri alımı her hasta
/// için tek olaydır: son verinin zamanı ve son 24 saatteki ölçüm sayısı.
List<ActivityEvent> activityFeed(
  PortalStore store,
  String ownerId,
  DateTime now, {
  int days = 14,
}) {
  final since = now.subtract(Duration(days: days));
  bool recent(DateTime t) => !t.isBefore(since) && !t.isAfter(now);
  final out = <ActivityEvent>[];
  for (final a in store.alertsOf(ownerId)) {
    if (recent(a.created)) {
      out.add(
        ActivityEvent(
          ActivityKind.alertRaised,
          a.created,
          patientId: a.patientId,
          alert: a,
        ),
      );
    }
    if (a.ackAt case final t? when recent(t)) {
      out.add(
        ActivityEvent(
          ActivityKind.alertAcked,
          t,
          patientId: a.patientId,
          alert: a,
          text: a.note,
        ),
      );
    } else if (a.resolvedAt case final t? when recent(t)) {
      out.add(
        ActivityEvent(
          ActivityKind.alertResolved,
          t,
          patientId: a.patientId,
          alert: a,
        ),
      );
    }
  }
  final records = store.recordsOf(ownerId);
  for (final rec in records) {
    if (recent(rec.created)) {
      out.add(
        ActivityEvent(
          ActivityKind.recordCreated,
          rec.created,
          recordId: rec.id,
          patientId: rec.patientId,
        ),
      );
    }
    for (final e in store.careOf(rec.id)) {
      if (e.kind == CareKind.note) {
        if (recent(e.created)) {
          out.add(
            ActivityEvent(
              ActivityKind.note,
              e.created,
              recordId: rec.id,
              patientId: rec.patientId,
              text: e.text,
            ),
          );
        }
      } else {
        if (recent(e.created)) {
          out.add(
            ActivityEvent(
              ActivityKind.taskAdded,
              e.created,
              recordId: rec.id,
              patientId: rec.patientId,
              text: e.text,
            ),
          );
        }
        if (e.doneAt case final t? when recent(t)) {
          out.add(
            ActivityEvent(
              ActivityKind.taskDone,
              t,
              recordId: rec.id,
              patientId: rec.patientId,
              text: e.text,
            ),
          );
        }
      }
    }
  }
  for (final k in store.consentsForActor(ownerId)) {
    if (recent(k.start)) {
      out.add(
        ActivityEvent(
          ActivityKind.consentStarted,
          k.start,
          patientId: k.patientId,
        ),
      );
    }
    if (!k.activeAt(now)) continue;
    final items = store.observations(
      k.patientId,
      codes: k.codes,
      from: since,
      to: now,
    );
    if (items.isEmpty) continue;
    final last = items
        .map((o) => o.effective)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final dayAgo = now.subtract(const Duration(hours: 24));
    out.add(
      ActivityEvent(
        ActivityKind.dataReceived,
        last,
        patientId: k.patientId,
        n: items.where((o) => o.effective.isAfter(dayAgo)).length,
      ),
    );
  }
  out.sort((a, b) => b.time.compareTo(a.time));
  return out;
}
