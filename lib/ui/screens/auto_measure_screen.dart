import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../device/protocol/settings.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/choice_sheet.dart';
import '../widgets/settings_rows.dart';

/// Otomatik ölçüm ayarları (0x2A/0x2B): nabız, SpO2 ve HRV için aralık,
/// saat dilimi ve günler. Her değişiklik hemen bilekliğe yazılır; bileklik
/// kabul etmezse eski ayar geri gelir.
class AutoMeasureScreen extends StatelessWidget {
  const AutoMeasureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final colors = context.colors;
    final configs = c.autoMeasure;

    Widget body;
    if (!c.isConnected) {
      body = SettingsNotice(
        text: l.autoMeasureNotConnected,
        action: l.autoMeasureConnect,
        onTap: c.connect,
      );
    } else if (configs.isEmpty && c.settingsFailed) {
      body = SettingsNotice(
        text: l.autoMeasureLoadFailed,
        action: l.autoMeasureRetry,
        onTap: c.reloadDeviceSettings,
      );
    } else if (configs.isEmpty) {
      body = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      body = Column(
        children: [
          for (final t in AutoMeasureType.values)
            if (configs[t] case final cfg?)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TypeCard(cfg),
              ),
        ],
      );
    }

    return CamScaffold(
      appBar: AppBar(title: Text(l.autoMeasureTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 16),
              child: Text(
                l.autoMeasureIntro,
                style: TextStyle(color: colors.muted),
              ),
            ),
            body,
          ],
        ),
      ),
    );
  }
}

/// Ölçüm türünün kartı: anahtar, açıksa aralık, saatler ve günler.
class _TypeCard extends StatelessWidget {
  const _TypeCard(this.config);
  final AutoMeasureConfig config;

  MetricType get _metric => switch (config.type) {
    AutoMeasureType.heartRate => MetricType.heartRate,
    AutoMeasureType.spo2 => MetricType.spo2,
    AutoMeasureType.hrv => MetricType.hrv,
  };

  Future<void> _save(BuildContext context, AutoMeasureConfig next) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final ok = await DeviceScope.of(context).saveAutoMeasure(next);
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.autoMeasureSaveFailed)));
    }
  }

  void _say(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickInterval(BuildContext context) async {
    final l = context.l10n;
    final picked = await showChoiceSheet<int>(
      context: context,
      title: l.autoMeasureInterval,
      current: config.intervalMinutes,
      options: [
        for (final m in AutoMeasureConfig.intervalChoices)
          (m, intervalText(l, m)),
      ],
    );
    if (picked == null || picked == config.intervalMinutes) return;
    if (!context.mounted) return;
    await _save(context, config.copyWith(intervalMinutes: picked));
  }

  Future<void> _pickTime(BuildContext context, {required bool start}) async {
    final l = context.l10n;
    final current = start ? config.startMinute : config.endMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      helpText: start ? l.autoMeasureStart : l.autoMeasureEnd,
    );
    if (picked == null || !context.mounted) return;
    final minute = picked.hour * 60 + picked.minute;
    final other = start ? config.endMinute : config.startMinute;
    if (minute == other) {
      _say(context, l.autoMeasureSameTime);
      return;
    }
    if (minute == current) return;
    await _save(
      context,
      start
          ? config.copyWith(startMinute: minute)
          : config.copyWith(endMinute: minute),
    );
  }

  Future<void> _toggleDay(BuildContext context, int weekday, bool on) async {
    final next = config.withDay(weekday, on);
    if (next.weekdays == 0) {
      _say(context, context.l10n.autoMeasureNoDays);
      return;
    }
    await _save(context, next);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final metric = _metric;
    final on = config.enabled;
    final reduce = MediaQuery.of(context).disableAnimations;

    final summary = on
        ? '${intervalText(l, config.intervalMinutes)} · '
              '${hoursText(l, config)}'
        : l.autoMeasureOff;

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: 16,
              end: 12,
            ),
            secondary: Icon(metric.icon, color: metric.color),
            title: Text(
              metric.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(summary, style: TextStyle(color: colors.muted)),
            value: on,
            onChanged: (v) => _save(context, config.copyWith(enabled: v)),
          ),
          AnimatedSize(
            duration: reduce
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional.topStart,
            child: !on
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(height: 1, color: colors.grid),
                      SettingsValueRow(
                        label: l.autoMeasureInterval,
                        value: intervalText(l, config.intervalMinutes),
                        onTap: () => _pickInterval(context),
                      ),
                      SettingsValueRow(
                        label: l.autoMeasureStart,
                        value: ltr(minuteOfDay(config.startMinute)),
                        onTap: () => _pickTime(context, start: true),
                      ),
                      SettingsValueRow(
                        label: l.autoMeasureEnd,
                        value: endText(l, config),
                        onTap: () => _pickTime(context, start: false),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          8,
                          16,
                          4,
                        ),
                        child: Text(
                          l.autoMeasureDays,
                          style: TextStyle(color: colors.muted),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          12,
                          0,
                          12,
                          12,
                        ),
                        child: WeekdayPicker(
                          isSelected: config.hasDay,
                          onChanged: (day, v) => _toggleDay(context, day, v),
                        ),
                      ),
                      if (config.type == AutoMeasureType.heartRate)
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            0,
                            16,
                            12,
                          ),
                          child: Text(
                            l.autoMeasureSleepNote,
                            style: TextStyle(color: colors.muted, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// "30 dakikada bir" ya da "2 saatte bir".
String intervalText(AppLocalizations l, int minutes) =>
    minutes >= 60 && minutes % 60 == 0
    ? l.autoMeasureEveryHours(minutes ~/ 60)
    : l.autoMeasureEveryMinutes(minutes);

/// "Tüm gün" ya da "08:00 – 22:00".
String hoursText(AppLocalizations l, AutoMeasureConfig c) => c.allDay
    ? l.autoMeasureAllDay
    : ltr('${minuteOfDay(c.startMinute)} – ${minuteOfDay(c.endMinute)}');

/// Bitiş başlangıçtan önceyse gece yarısını geçen dilim: "(ertesi gün)".
/// Bilekliğin gece yarısını geçen dilimi desteklediği PDF'te yazmıyor;
/// gerçek cihazda doğrulanacak.
String endText(AppLocalizations l, AutoMeasureConfig c) {
  final time = ltr(minuteOfDay(c.endMinute));
  return c.endMinute < c.startMinute ? l.autoMeasureNextDay(time) : time;
}
