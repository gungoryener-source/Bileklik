part of 'panel.dart';

/// Panelin ortak bileşenleri: simgeler, avatar, durum rozeti, küçük ve
/// büyük grafikler, sayfalama, boş durum, göreli zaman ve ölçüm biçimleri.
/// Bütün sayfalar bunları kullanır; renkler `panel_style.dart` tokenlarından.
extension _PanelUi on PanelApi {
  static String _h(String s) => PanelApi._h(s);

  /// Çizgi simgeler (24x24, metin rengini alır).
  static const icons = {
    'overview': 'M3 13h8V3H3zM13 21h8V11h-8zM3 21h8v-6H3zM13 3v6h8V3z',
    'patients':
        'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75',
    'alerts':
        'M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.73 21a2 2 0 0 1-3.46 0',
    'activity': 'M22 12h-4l-3 9L9 3l-3 9H2',
    'newPatient':
        'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM19 8v6M22 11h-6',
    'account':
        'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68 1.65 1.65 0 0 0 10 3.17V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z',
    'search': 'M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM21 21l-4.35-4.35',
    'chevron': 'M9 18l6-6-6-6',
    'globe':
        'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18',
    'menu': 'M3 6h18M3 12h18M3 18h18',
    'plus': 'M12 5v14M5 12h14',
    'key':
        'M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.78 7.78 5.5 5.5 0 0 1 7.78-7.78zM15.5 7.5l3 3L22 7l-3-3',
    'report':
        'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8zM14 2v6h6M16 13H8M16 17H8M10 9H8',
    'note': 'M12 20h9M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4z',
    'check': 'M20 6L9 17l-5-5',
    'link':
        'M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71',
    'data': 'M21 12h-4l-3 9L8 3l-3 9H1',
    'clock': 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 6v6l4 2',
    'trend': 'M23 6l-9.5 9.5-5-5L1 18M17 6h6v6',
    'gap': 'M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM4.93 4.93l14.14 14.14',
    'repeat':
        'M17 1l4 4-4 4M3 11V9a4 4 0 0 1 4-4h14M7 23l-4-4 4-4M21 13v2a4 4 0 0 1-4 4H3',
    'calendar':
        'M19 4H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2zM16 2v4M8 2v4M3 10h18',
    'inbox':
        'M22 12h-6l-2 3h-4l-2-3H2M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z',
    'shield': 'M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z',
    'code': 'M16 18l6-6-6-6M8 6l-6 6 6 6',
  };

  static String icon(String name, {int size = 18}) =>
      '<svg width="$size" height="$size" viewBox="0 0 24 24" fill="none" '
      'stroke="currentColor" stroke-width="1.9" stroke-linecap="round" '
      'stroke-linejoin="round" aria-hidden="true"><path d="${icons[name]}"/></svg>';

  /// Addan sabit bir renk tonu; kırmızı ve sarı tonlar durum renklerine
  /// ayrıldığı için kullanılmaz.
  static int _hue(String s) {
    const hues = [168, 190, 205, 222, 248, 268, 150, 132, 182, 236];
    var h = 0;
    for (final c in s.runes) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return hues[h % hues.length];
  }

  static String avatar(PatientSnapshot p, {bool large = false}) {
    final ring = switch (p.status) {
      MonitorStatus.critical => ' ring-critical',
      MonitorStatus.attention => ' ring-attention',
      _ => '',
    };
    final cls = 'avatar${large ? ' lg' : ''}$ring';
    if (p.record == null) {
      return '<span class="$cls anon" aria-hidden="true">${icon('key', size: large ? 24 : 16)}</span>';
    }
    return '<span class="$cls" style="--h:${_hue(p.record!.name)}" aria-hidden="true">'
        '${_h(PanelApi._initials(p.record!.name))}</span>';
  }

  static String statusBadge(MonitorText m, MonitorStatus s) =>
      '<span class="status st-${s.name}">${_h(m['st.${s.name}'])}</span>';

  /// Hasta sayfasının adresi: veri varsa izlem, yoksa kayıt.
  static String patientHref(PatientSnapshot p) =>
      p.patientId != null && p.consent != null
      ? '/panel/patients/${_h(Uri.encodeComponent(p.patientId!))}'
      : '/panel/records/${_h(Uri.encodeComponent(p.record!.id))}';

  /// Avatar, ad ve alt satır (dosya no, yaş, cinsiyet ya da takma kimlik).
  String ident(MonitorText m, ClinicText c, PatientSnapshot p, DateTime now) {
    final rec = p.record;
    final String sub;
    if (rec == null) {
      sub = m['unlinkedSub'];
    } else {
      final age = rec.ageAt(now);
      sub = [
        if (rec.fileNo != null) rec.fileNo!,
        if (age != null) c.f('ageYears', {'n': age}),
        if (rec.sex != null) _sexLabel(c, rec.sex),
      ].join(' · ');
    }
    final name = rec == null
        ? '<a href="${patientHref(p)}" dir="ltr">${_h(p.displayName)}</a>'
        : '<a href="${patientHref(p)}">${_h(rec.name)}</a>';
    return '<div class="ident">${avatar(p)}<div class="names">$name'
        '<span${rec?.fileNo != null ? ' dir="auto"' : ''}>${_h(sub.isEmpty ? '—' : sub)}</span></div></div>';
  }

  /// "12 dk önce" gibi göreli zaman; tam zaman `title` içinde.
  static String ago(MonitorText m, PanelText t, DateTime at, DateTime now) {
    final d = now.difference(at);
    final String s;
    if (d.inMinutes < 1) {
      s = m['agoNow'];
    } else if (d.inMinutes < 60) {
      s = m.f('agoMin', {'n': d.inMinutes});
    } else if (d.inHours < 48) {
      s = m.f('agoHour', {'n': d.inHours});
    } else {
      s = m.f('agoDay', {'n': d.inDays});
    }
    return '<time datetime="${at.toUtc().toIso8601String()}" title="${_h(PanelApi._dateTime(t, at))}">${_h(s)}</time>';
  }

  /// Yüzde: dile göre işaretin yeri (%97 / 97% / 97٪ / 97 %).
  static String pct(MonitorText m, num v) =>
      m.f('pctFmt', {'v': v is int ? v : v.round()});

  /// Bir ölçümün değeri birimiyle.
  static String vitalValue(
    PanelText t,
    ClinicText c,
    MonitorText m,
    Vital v,
    double value, [
    double? value2,
  ]) => switch (v) {
    Vital.bloodPressure =>
      '${value.round()}/${(value2 ?? 0).round()} ${c['u.mmHg']}',
    Vital.spo2 => pct(m, value),
    Vital.sleep => t.duration(value.round()),
    Vital.temperature || Vital.weight =>
      '${t.number((value * 10).round() / 10)} ${c[v == Vital.weight ? 'u.kg' : 'u.cel']}',
    Vital.heartRate => '${value.round()} ${c['u.bpm']}',
    Vital.hrv => '${value.round()} ${c['u.ms']}',
    Vital.respiration => '${value.round()} ${c['u.perMin']}',
    Vital.stress => '${value.round()}',
    Vital.steps => '${value.round()} ${c['u.steps']}',
  };

  /// Değer ve birim ayrı (büyük yazılan kartlar için).
  static (String, String) vitalParts(
    PanelText t,
    ClinicText c,
    MonitorText m,
    Vital v,
    double value, [
    double? value2,
  ]) => switch (v) {
    Vital.bloodPressure => (
      '${value.round()}/${(value2 ?? 0).round()}',
      c['u.mmHg'],
    ),
    Vital.spo2 => (pct(m, value), ''),
    Vital.sleep => (t.duration(value.round()), ''),
    Vital.temperature => (t.number((value * 10).round() / 10), c['u.cel']),
    Vital.weight => (t.number((value * 10).round() / 10), c['u.kg']),
    Vital.heartRate => ('${value.round()}', c['u.bpm']),
    Vital.hrv => ('${value.round()}', c['u.ms']),
    Vital.respiration => ('${value.round()}', c['u.perMin']),
    Vital.stress => ('${value.round()}', c['u.score']),
    Vital.steps => ('${value.round()}', c['u.steps']),
  };

  static String vitalLabel(PanelText t, Vital v) =>
      t.codeLabels[v.code] ?? v.name;

  /// Tarama eşikleri dışında mı (kehribar) ya da uyarı kuralı düzeyinde mi
  /// (kırmızı). Eşikler [MonitorBoard] ve [AlertRules] ile aynı.
  int flagOf(Vital v, double value, [double? value2]) {
    final r = _engine.rules;
    switch (v) {
      case Vital.heartRate:
        if (value > r.heartRateAbove || value < r.heartRateBelow) return 2;
        return value > MonitorBoard.highHr || value < MonitorBoard.lowHr
            ? 1
            : 0;
      case Vital.spo2:
        return value < r.spo2Below ? 2 : 0;
      case Vital.bloodPressure:
        final d = value2 ?? 0;
        if (value >= r.systolicCrisis || d >= r.diastolicCrisis) return 2;
        return value >= MonitorBoard.systolicHigh ||
                d >= MonitorBoard.diastolicHigh
            ? 1
            : 0;
      case Vital.temperature:
        return value >= r.feverFrom ? 1 : 0;
      case Vital.respiration:
        return value > PatientReport.tachypneaAbove ? 1 : 0;
      default:
        return 0;
    }
  }

  /// Ölçümün tarama aralığı (grafikte yeşil bant); yoksa null.
  static (double, double)? refRange(Vital v) => switch (v) {
    Vital.heartRate => (MonitorBoard.lowHr, MonitorBoard.highHr),
    Vital.spo2 => (MonitorBoard.lowSpo2, 100),
    Vital.temperature => (35.5, MonitorBoard.feverFrom),
    Vital.respiration => (10, PatientReport.tachypneaAbove),
    _ => null,
  };

  /// Son 7 günün küçük çizgisi; veri olmayan gün çizgiyi böler.
  static String spark(
    List<double?> daily, {
    String cls = '',
    String label = '',
    int w = 120,
    int h = 30,
  }) {
    final vals = [for (final v in daily) ?v];
    if (vals.length < 2) {
      return '<svg class="spark $cls" viewBox="0 0 $w $h" aria-hidden="true">'
          '<line x1="0" y1="${h / 2}" x2="$w" y2="${h / 2}" stroke="currentColor" stroke-opacity=".25" stroke-dasharray="3 3"/></svg>';
    }
    var lo = vals.reduce(min), hi = vals.reduce(max);
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final n = daily.length;
    String x(int i) => (i / (n - 1) * w).toStringAsFixed(1);
    String y(double v) =>
        (h - 3 - (v - lo) / (hi - lo) * (h - 6)).toStringAsFixed(1);
    final segs = <List<String>>[];
    var cur = <String>[];
    for (var i = 0; i < n; i++) {
      final v = daily[i];
      if (v == null) {
        if (cur.isNotEmpty) segs.add(cur);
        cur = [];
        continue;
      }
      cur.add('${x(i)},${y(v)}');
    }
    if (cur.isNotEmpty) segs.add(cur);
    var lastI = n - 1;
    while (daily[lastI] == null) {
      lastI--;
    }
    final b = StringBuffer(
      '<svg class="spark $cls" viewBox="0 0 $w $h" preserveAspectRatio="none" '
      'role="img" aria-label="${_h(label)}">',
    );
    for (final s in segs) {
      if (s.length == 1) {
        final p = s.single.split(',');
        b.write('<circle class="pt" cx="${p[0]}" cy="${p[1]}" r="1.6"/>');
      } else {
        b.write('<polyline class="ln" points="${s.join(' ')}"/>');
      }
    }
    b.write(
      '<circle class="pt" cx="${x(lastI)}" cy="${y(daily[lastI]!)}" r="2.4"/></svg>',
    );
    return b.toString();
  }

  /// Zaman serisi grafiği. [series] her biri (zaman, değer, alt, üst)
  /// noktalarıdır; alt/üst verilirse günlük aralık bandı çizilir. Eşik
  /// dışı noktalar [flag] ile işaretlenir; her noktanın üzerine gelince
  /// zamanı ve değeri görünür (SVG `title`).
  String timeChart({
    required List<List<(DateTime, double, double?, double?)>> series,
    required List<String> classes,
    required DateTime from,
    required DateTime to,
    required String Function(double) fmt,
    required String Function(DateTime) when,
    required String Function(DateTime) tick,
    required List<DateTime> ticks,
    required String label,
    int Function(int series, double v)? flag,
    (double, double)? ref,
    List<double> refLines = const [],
    bool bars = false,
    Duration? gap,
    double? floor,
    double w = 860,
    double h = 260,
  }) {
    const l = 46.0, r = 14.0, top = 12.0, bot = 28.0;
    final all = <double>[
      for (final s in series)
        for (final p in s) ...[p.$2, ?p.$3, ?p.$4],
      if (ref != null) ...[ref.$1, ref.$2],
      ...refLines,
    ];
    if (all.isEmpty) return '';
    var lo = all.reduce(min), hi = all.reduce(max);
    if (bars || floor != null) lo = min(lo, floor ?? 0);
    if (hi - lo < 1e-9) {
      hi += 1;
      lo -= bars ? 0 : 1;
    }
    // Okunur aralıklar: 1, 2, 2,5 ya da 5'in katları.
    final raw = (hi - lo) / 4;
    final mag = pow(10, (log(raw) / ln10).floor()).toDouble();
    final step = [
      1.0,
      2.0,
      2.5,
      5.0,
      10.0,
    ].map((k) => k * mag).firstWhere((s) => s >= raw, orElse: () => 10 * mag);
    lo = (lo / step).floor() * step;
    hi = (hi / step).ceil() * step;
    final span = to.difference(from).inMilliseconds.toDouble();
    double x(DateTime t) =>
        l +
        (t.difference(from).inMilliseconds / span).clamp(0, 1) * (w - l - r);
    double y(double v) => top + (1 - (v - lo) / (hi - lo)) * (h - top - bot);
    String f(double v) => v.toStringAsFixed(1);

    final b = StringBuffer(
      '<svg class="chart" viewBox="0 0 ${w.toInt()} ${h.toInt()}" role="img" '
      'aria-label="${_h(label)}" dir="ltr">',
    );
    if (ref != null) {
      final y1 = y(min(ref.$2, hi)), y2 = y(max(ref.$1, lo));
      b.write(
        '<rect class="ref" x="$l" y="${f(y1)}" width="${f(w - l - r)}" height="${f(max(0, y2 - y1))}"/>',
      );
    }
    for (var v = lo; v <= hi + step / 2; v += step) {
      final yy = f(y(v));
      b.write(
        '<line class="grid" x1="$l" x2="${w - r}" y1="$yy" y2="$yy"/>'
        '<text x="${l - 8}" y="$yy" dy="4" text-anchor="end">${_h(fmt(v))}</text>',
      );
    }
    for (final rl in refLines) {
      final yy = f(y(rl));
      b.write(
        '<line class="refline" x1="$l" x2="${w - r}" y1="$yy" y2="$yy"/>',
      );
    }
    for (final t in ticks) {
      final xx = f(x(t));
      b.write(
        '<line class="grid" x1="$xx" x2="$xx" y1="$top" y2="${h - bot}" stroke-opacity=".5"/>'
        '<text x="$xx" y="${h - 8}" text-anchor="middle">${_h(tick(t))}</text>',
      );
    }
    b.write(
      '<line class="axis" x1="$l" x2="${w - r}" y1="${h - bot}" y2="${h - bot}"/>',
    );
    for (var si = 0; si < series.length; si++) {
      final s = series[si];
      final cls = classes[si];
      if (s.isEmpty) continue;
      b.write('<g class="$cls">');
      if (bars) {
        final bw = max(2.0, (w - l - r) / max(1, s.length) * .6);
        final slot =
            (w - l - r) /
            max(
              1,
              to.difference(from).inDays +
                  (to.difference(from).inHours % 24 == 0 ? 0 : 1),
            );
        final width = min(bw, slot * .7);
        for (final p in s) {
          final xx = x(p.$1) + slot / 2 - width / 2;
          final yy = y(p.$2);
          b.write(
            '<rect class="bar" x="${f(xx)}" y="${f(yy)}" width="${f(width)}" height="${f(max(1, y(lo) - yy))}" rx="2">'
            '<title>${_h('${when(p.$1)}: ${fmt(p.$2)}')}</title></rect>',
          );
        }
        b.write('</g>');
        continue;
      }
      // Aralık bandı (günlük en düşük–en yüksek).
      if (s.any((p) => p.$3 != null && p.$4 != null)) {
        final up = [
          for (final p in s)
            if (p.$4 != null) '${f(x(p.$1))},${f(y(p.$4!))}',
        ];
        final down = [
          for (final p in s.reversed)
            if (p.$3 != null) '${f(x(p.$1))},${f(y(p.$3!))}',
        ];
        b.write(
          '<polygon class="band" points="${[...up, ...down].join(' ')}"/>',
        );
      }
      // Çizgi: aradaki boşluk [gap]'ten uzunsa bölünür.
      var seg = <String>[];
      DateTime? prev;
      void flush() {
        if (seg.length > 1) {
          b.write('<polyline class="line" points="${seg.join(' ')}"/>');
        }
        seg = [];
      }

      for (final p in s) {
        if (prev != null && gap != null && p.$1.difference(prev) > gap) flush();
        seg.add('${f(x(p.$1))},${f(y(p.$2))}');
        prev = p.$1;
      }
      flush();
      final dense = s.length > 60;
      for (final p in s) {
        final fl = flag?.call(si, p.$2) ?? 0;
        final cls2 = fl == 2
            ? ' crit'
            : fl == 1
            ? ' out'
            : '';
        final rad = fl > 0
            ? 3.6
            : dense
            ? 1.6
            : 2.6;
        final tip = p.$3 != null && p.$4 != null && p.$3 != p.$4
            ? '${when(p.$1)}: ${fmt(p.$2)} (${fmt(p.$3!)}–${fmt(p.$4!)})'
            : '${when(p.$1)}: ${fmt(p.$2)}';
        b.write(
          '<circle class="pt$cls2" cx="${f(x(p.$1))}" cy="${f(y(p.$2))}" r="$rad"><title>${_h(tip)}</title></circle>',
        );
      }
      b.write('</g>');
    }
    b.write('</svg>');
    return b.toString();
  }

  /// Boş durum: simge, başlık, açıklama ve isteğe bağlı eylem.
  static String empty(
    String iconName,
    String title,
    String body, {
    String action = '',
  }) =>
      '<div class="empty">${icon(iconName, size: 28)}<strong>${_h(title)}</strong>'
      '<p>${_h(body)}</p>$action</div>';

  /// Sayfa numaraları; [href] sayfa numarasından adres üretir.
  static String pager(
    MonitorText m,
    int page,
    int pages,
    int total,
    int per,
    String Function(int) href,
  ) {
    if (total == 0) return '';
    final first = (page - 1) * per + 1;
    final last = min(page * per, total);
    final links = StringBuffer();
    String item(int p, String text, {String? aria}) => p < 1 || p > pages
        ? '<span class="pg off" aria-hidden="true">$text</span>'
        : p == page
        ? '<span class="pg" aria-current="page">$text</span>'
        : '<a href="${href(p)}"${aria == null ? '' : ' aria-label="${_h(aria)}"'}>$text</a>';
    links.write(item(page - 1, '‹', aria: m['prevPage']));
    for (var p = 1; p <= pages; p++) {
      if (pages > 7 && (p - page).abs() > 1 && p != 1 && p != pages) {
        if ((p - page).abs() == 2) links.write('<span class="pg off">…</span>');
        continue;
      }
      links.write(item(p, '$p'));
    }
    links.write(item(page + 1, '›', aria: m['nextPage']));
    return '<div class="pager"><span>${_h(m.f('showing', {'a': first, 'b': last, 'n': total}))}</span>'
        '<nav aria-label="${_h(m['pagination'])}">$links</nav></div>';
  }

  /// Bir sinyalin başlığı ve dayanağı (ekranda iki satır).
  (String, String) signalText(
    PanelText t,
    ClinicText c,
    MonitorText m,
    Signal s,
  ) {
    String n(double? v) => v == null ? '—' : t.number((v * 10).round() / 10);
    final title = m['sig.${s.kind.name}'];
    final String why;
    switch (s.kind) {
      case SignalKind.criticalAlert:
      case SignalKind.warningAlert:
        why = m.f('why.alerts', {'n': s.n ?? 0});
      case SignalKind.noData:
        why = s.n == null ? m['why.noDataYet'] : m.f('why.noData', {'n': s.n!});
      case SignalKind.highHeartRate:
        why = m.f('why.highHr', {
          'n': s.n!,
          'days': MonitorBoard.signalDays,
          'th': MonitorBoard.highHr.round(),
          'max': s.value!.round(),
        });
      case SignalKind.lowHeartRate:
        why = m.f('why.lowHr', {
          'n': s.n!,
          'days': MonitorBoard.signalDays,
          'th': MonitorBoard.lowHr.round(),
          'min': s.value!.round(),
        });
      case SignalKind.lowSpo2:
        why = m.f('why.lowSpo2', {
          'n': s.n!,
          'days': MonitorBoard.signalDays,
          'th': pct(m, MonitorBoard.lowSpo2),
          'min': pct(m, s.value!),
        });
      case SignalKind.highBloodPressure:
        why = m.f('why.highBp', {
          'n': s.n!,
          'days': MonitorBoard.signalDays,
          'max': '${s.value!.round()}/${s.value2!.round()}',
        });
      case SignalKind.fever:
        why = m.f('why.fever', {
          'n': s.n!,
          'days': MonitorBoard.signalDays,
          'max': n(s.value),
        });
      case SignalKind.weightChange:
        why = m.f('why.weight', {
          'd': '${s.value! > 0 ? '+' : '−'}${n(s.value!.abs())}',
          'days': max(1, s.n ?? 0),
        });
      case SignalKind.restingHrRise:
        why = m.f('why.resting', {
          'd': '+${s.value!.round()}',
          'v': s.value2!.round(),
        });
      case SignalKind.activityDrop:
        why = m.f('why.activity', {
          'p': pct(m, s.value!.abs()),
          'v': s.value2!.round(),
        });
      case SignalKind.lowAdherence:
        why = m.f('why.adherence', {'n': s.n!, 'total': s.total!});
      case SignalKind.overdueTask:
        why = m.f('why.tasks', {'n': s.n!});
    }
    return (title, why);
  }

  /// 14 günlük uyum noktaları ve oranı.
  static String adherence(MonitorText m, PatientSnapshot p) {
    final a = p.adherence;
    if (a == null) return '<span class="faint">—</span>';
    final dots = [
      for (final d in p.coverage) '<i${d ? ' class="on"' : ''}></i>',
    ].join();
    return '<span class="adh${a < MonitorBoard.adherenceMin ? ' low' : ''}" '
        'title="${_h(m.f('adhTitle', {'n': p.adherenceDays, 'total': p.coverage.length}))}">'
        '<span class="dots" aria-hidden="true">$dots</span><b>${_h(pct(m, a * 100))}</b></span>';
  }
}
