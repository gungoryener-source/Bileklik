import 'package:flutter/material.dart';

import '../../device/protocol/reminders.dart';
import '../../l10n/l10n.dart';
import '../app_shell.dart';
import '../format.dart';
import '../theme.dart';
import '../widgets/cam/cam.dart';
import '../widgets/choice_sheet.dart';
import '../widgets/settings_rows.dart';

/// Hatırlatıcılar: ilaç ve su saatleri (0x23/0x57) ile hareketsizlik
/// uyarısı (0x25/0x26). Bileklik ekransız olduğu için hatırlatma titreşimle
/// gelir. Her değişiklik hemen bilekliğe yazılır; olmazsa eski hal kalır.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = DeviceScope.of(context);
    final l = context.l10n;
    final reminders = c.reminders;
    final sedentary = c.sedentary;

    final List<Widget> body;
    if (!c.isConnected) {
      body = [
        SettingsNotice(
          text: l.remindersNotConnected,
          action: l.autoMeasureConnect,
          onTap: c.connect,
        ),
      ];
    } else if (reminders == null && c.remindersFailed) {
      body = [
        SettingsNotice(
          text: l.remindersLoadFailed,
          action: l.autoMeasureRetry,
          onTap: c.reloadDeviceSettings,
        ),
      ];
    } else if (reminders == null) {
      body = const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else {
      final full = reminders.length >= Reminder.maxCount;
      body = [
        _KindCard(kind: ReminderKind.medication, all: reminders),
        const SizedBox(height: 12),
        _KindCard(kind: ReminderKind.water, all: reminders),
        // Başka uygulamanın yazdığı çalar saatler korunur ve burada görünür.
        if (reminders.any((r) => r.kind == ReminderKind.alarm)) ...[
          const SizedBox(height: 12),
          _KindCard(kind: ReminderKind.alarm, all: reminders),
        ],
        if (full)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 12, 4, 0),
            child: Text(
              l.remindersFull(Reminder.maxCount),
              style: TextStyle(color: context.colors.muted),
            ),
          ),
        if (sedentary != null) ...[
          const SizedBox(height: 12),
          _SedentaryCard(sedentary),
        ],
      ];
    }

    return CamScaffold(
      appBar: AppBar(title: Text(l.remindersTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 16),
              child: Text(
                l.remindersIntro,
                style: TextStyle(color: context.colors.muted),
              ),
            ),
            ...body,
          ],
        ),
      ),
    );
  }
}

/// Bir hatırlatıcı türünün başlığı, rengi ve ikonu.
extension ReminderLook on ReminderKind {
  String label(AppLocalizations l) => switch (this) {
    ReminderKind.medication => l.reminderMedication,
    ReminderKind.water => l.reminderWater,
    ReminderKind.alarm => l.reminderAlarm,
  };

  IconData get icon => switch (this) {
    ReminderKind.medication => Icons.medication_outlined,
    ReminderKind.water => Icons.water_drop_outlined,
    ReminderKind.alarm => Icons.alarm,
  };

  OrbPalette get palette => switch (this) {
    ReminderKind.medication => CamArt.orbViolet,
    ReminderKind.water => CamArt.orbCyan,
    ReminderKind.alarm => CamArt.orbAmber,
  };
}

/// "Her gün", "Hafta içi", "Hafta sonu" ya da kısa gün adları.
String weekdaysText(AppLocalizations l, int mask) {
  final m = mask & 0x7F;
  if (m == 0x7F) return l.autoMeasureEveryDay;
  if (m == 0x3E) return l.reminderWeekdays;
  if (m == 0x41) return l.reminderWeekend;
  return [
    for (var d = 1; d <= 7; d++)
      if (m & (1 << (d % 7)) != 0) weekdayShort(d),
  ].join(', ');
}

/// "45 dakika", "1 saat", "1 sa 30 dk".
String durationText(AppLocalizations l, int minutes) {
  if (minutes < 60) return l.sedentaryMinutes(minutes);
  if (minutes % 60 == 0) return l.sedentaryHours(minutes ~/ 60);
  return l.sedentaryHoursMinutes(minutes ~/ 60, minutes % 60);
}

void _say(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Listeyi bilekliğe yazar; tür ve saate göre sıralı tutar.
Future<void> _saveAll(BuildContext context, List<Reminder> next) async {
  final l = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final sorted = [...next]
    ..sort((a, b) {
      final k = a.kind.index.compareTo(b.kind.index);
      return k != 0 ? k : a.minuteOfDay.compareTo(b.minuteOfDay);
    });
  final ok = await DeviceScope.of(context).saveReminders(sorted);
  if (!ok) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l.remindersSaveFailed)));
  }
}

/// Bir türün kartı: başlık, saat satırları ve "ekle" düğmesi.
class _KindCard extends StatelessWidget {
  const _KindCard({required this.kind, required this.all});

  final ReminderKind kind;
  final List<Reminder> all;

  Future<void> _edit(BuildContext context, Reminder? current) async {
    final result = await showCamSheet<_SheetResult>(
      context: context,
      builder: (_) => _ReminderSheet(kind: kind, initial: current),
    );
    if (result == null || !context.mounted) return;
    final rest = [...all];
    if (current != null) rest.remove(current);
    final value = result.value;
    if (value == null) {
      await _saveAll(context, rest);
      return;
    }
    final clash = rest.any(
      (r) => r.kind == value.kind && r.minuteOfDay == value.minuteOfDay,
    );
    if (clash) {
      _say(context, context.l10n.reminderDuplicate);
      return;
    }
    await _saveAll(context, [...rest, value]);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final items = all.where((r) => r.kind == kind).toList()
      ..sort((a, b) => a.minuteOfDay.compareTo(b.minuteOfDay));
    final full = all.length >= Reminder.maxCount;
    final addLabel = switch (kind) {
      ReminderKind.medication => l.reminderAddMedication,
      ReminderKind.water => l.reminderAddWater,
      ReminderKind.alarm => null,
    };
    final empty = switch (kind) {
      ReminderKind.medication => l.reminderEmptyMedication,
      ReminderKind.water => l.reminderEmptyWater,
      ReminderKind.alarm => '',
    };

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Orb(palette: kind.palette, size: 40, icon: kind.icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      kind.label(l),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty && empty.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
              child: Text(empty, style: TextStyle(color: colors.muted)),
            ),
          for (final r in items)
            _ReminderRow(
              reminder: r,
              onTap: () => _edit(context, r),
              onToggle: (v) {
                final i = all.indexOf(r);
                final next = [...all]..[i] = r.copyWith(enabled: v);
                _saveAll(context, next);
              },
            ),
          if (addLabel != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: full ? null : () => _edit(context, null),
                  icon: const Icon(Icons.add),
                  label: Text(addLabel),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.reminder,
    required this.onTap,
    required this.onToggle,
  });

  final Reminder reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final r = reminder;
    final time = ltr(minuteOfDay(r.minuteOfDay));
    final days = weekdaysText(l, r.weekdays);
    final label = r.label.trim();
    return ListTile(
      minTileHeight: 64,
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 8),
      onTap: onTap,
      title: Text(
        time,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
          color: r.enabled ? colors.text : colors.muted,
        ),
      ),
      subtitle: Text(
        label.isEmpty ? days : '${isolate(label)} · $days',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colors.muted),
      ),
      trailing: Semantics(
        label: '${r.kind.label(l)} $time',
        child: Switch(value: r.enabled, onChanged: onToggle),
      ),
    );
  }
}

/// Alt sayfanın sonucu: [value] null ise hatırlatıcı silinir.
class _SheetResult {
  const _SheetResult(this.value);
  final Reminder? value;
}

/// Yeni hatırlatıcı ya da düzenleme: saat, (ilaçta) ad ve günler.
class _ReminderSheet extends StatefulWidget {
  const _ReminderSheet({required this.kind, this.initial});

  final ReminderKind kind;
  final Reminder? initial;

  @override
  State<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends State<_ReminderSheet> {
  late Reminder _value =
      widget.initial ??
      Reminder(
        kind: widget.kind,
        minuteOfDay: widget.kind == ReminderKind.water ? 10 * 60 : 9 * 60,
      );
  late final _label = TextEditingController(text: _value.label);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _value.minuteOfDay ~/ 60,
        minute: _value.minuteOfDay % 60,
      ),
      helpText: context.l10n.reminderTime,
    );
    if (picked == null || !mounted) return;
    setState(
      () => _value = _value.copyWith(
        minuteOfDay: picked.hour * 60 + picked.minute,
      ),
    );
  }

  void _toggleDay(int day, bool on) {
    final next = _value.withDay(day, on);
    if (next.weekdays == 0) {
      _say(context, context.l10n.autoMeasureNoDays);
      return;
    }
    setState(() => _value = next);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.colors;
    final editing = widget.initial != null;
    final title = editing
        ? l.reminderEdit
        : widget.kind == ReminderKind.water
        ? l.reminderNewWater
        : l.reminderNewMedication;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: SettingsValueRow(
              label: l.reminderTime,
              value: ltr(minuteOfDay(_value.minuteOfDay)),
              onTap: _pickTime,
            ),
          ),
          if (widget.kind == ReminderKind.medication) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              maxLength: 24,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.reminderLabel,
                hintText: l.reminderLabelHint,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(l.autoMeasureDays, style: TextStyle(color: colors.muted)),
          const SizedBox(height: 8),
          WeekdayPicker(isSelected: _value.hasDay, onChanged: _toggleDay),
          const SizedBox(height: 20),
          GlowButton(
            label: l.reminderSave,
            onTap: () => Navigator.of(context)
                .pop(_SheetResult(_value.copyWith(label: _label.text.trim()))),
          ),
          if (editing) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(const _SheetResult(null)),
              icon: Icon(Icons.delete_outline, color: colors.danger),
              label: Text(
                l.reminderDelete,
                style: TextStyle(color: colors.danger),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hareketsizlik uyarısı: anahtar, süre, saat dilimi ve günler.
class _SedentaryCard extends StatelessWidget {
  const _SedentaryCard(this.config);
  final SedentaryConfig config;

  Future<void> _save(BuildContext context, SedentaryConfig next) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await DeviceScope.of(context).saveSedentary(next);
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l.remindersSaveFailed)));
    }
  }

  Future<void> _pickInterval(BuildContext context) async {
    final l = context.l10n;
    final picked = await showChoiceSheet<int>(
      context: context,
      title: l.sedentaryInterval,
      current: config.intervalMinutes,
      options: [
        for (final m in SedentaryConfig.intervalChoices)
          (m, durationText(l, m)),
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

  Future<void> _toggleDay(BuildContext context, int day, bool on) async {
    final next = config.withDay(day, on);
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
    final on = config.enabled;
    final reduce = MediaQuery.of(context).disableAnimations;
    // Bitiş başlangıçtan önceyse gece yarısını geçen dilim; bileklikte
    // desteklendiği gerçek cihazda doğrulanacak.
    final end = ltr(minuteOfDay(config.endMinute));
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
            secondary: const ExcludeSemantics(
              child: Orb(
                palette: CamArt.orbLime,
                size: 40,
                icon: Icons.directions_walk,
              ),
            ),
            title: Text(
              l.sedentaryTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              on
                  ? l.sedentarySubtitle(durationText(l, config.intervalMinutes))
                  : l.autoMeasureOff,
              style: TextStyle(color: colors.muted),
            ),
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
                        label: l.sedentaryInterval,
                        value: durationText(l, config.intervalMinutes),
                        onTap: () => _pickInterval(context),
                      ),
                      SettingsValueRow(
                        label: l.autoMeasureStart,
                        value: ltr(minuteOfDay(config.startMinute)),
                        onTap: () => _pickTime(context, start: true),
                      ),
                      SettingsValueRow(
                        label: l.autoMeasureEnd,
                        value: config.endMinute < config.startMinute
                            ? l.autoMeasureNextDay(end)
                            : end,
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
                          8,
                        ),
                        child: WeekdayPicker(
                          isSelected: config.hasDay,
                          onChanged: (d, v) => _toggleDay(context, d, v),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          16,
                          0,
                          16,
                          12,
                        ),
                        child: Text(
                          l.sedentaryNote(config.minSteps),
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

/// Cihaz ekranındaki satırın alt yazısı: "3 hatırlatıcı" gibi.
String? remindersSummary(BuildContext context) {
  final c = DeviceScope.of(context);
  final l = context.l10n;
  final list = c.reminders;
  if (list == null) return c.remindersFailed ? l.remindersLoadFailed : null;
  final on = list.where((r) => r.enabled).length;
  return c.sedentary?.enabled ?? false
      ? l.reminderCountSedentary(on)
      : l.reminderCount(on);
}
