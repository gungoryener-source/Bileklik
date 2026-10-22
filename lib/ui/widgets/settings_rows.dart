import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';
import 'cam/cam.dart';

/// Bileklik ayar ekranlarının (otomatik ölçüm, hatırlatıcılar) ortak satırları.

/// Ayar satırı: solda ad, sağda seçili değer ve ok; dokununca seçici açılır.
class SettingsValueRow extends StatelessWidget {
  const SettingsValueRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label, value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListTile(
      minTileHeight: 52,
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 12),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.4,
            ),
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.chevron_right, color: colors.muted),
        ],
      ),
      onTap: onTap,
    );
  }
}

/// Haftanın günleri; sıra dilin hafta başlangıcına göre.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    super.key,
    required this.isSelected,
    required this.onChanged,
  });

  /// [weekday] DateTime biçiminde (1 pazartesi ... 7 pazar).
  final bool Function(int weekday) isSelected;
  final void Function(int weekday, bool on) onChanged;

  @override
  Widget build(BuildContext context) {
    // 0 pazar, 1 pazartesi; DateTime gün numarasına çevrilir (7 pazar).
    final first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final days = [for (var i = 0; i < 7; i++) (first + i) % 7]
        .map((d) => d == 0 ? 7 : d)
        .toList();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final day in days)
          FilterChip(
            label: Text(weekdayShort(day)),
            tooltip: weekdayLong(day),
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            selected: isSelected(day),
            onSelected: (v) => onChanged(day, v),
          ),
      ],
    );
  }
}

/// Bağlı değil ya da ayar okunamadı: açıklama ve tek düğme.
class SettingsNotice extends StatelessWidget {
  const SettingsNotice({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.watch_off_outlined, size: 40, color: context.colors.muted),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        GlowButton(onTap: onTap, label: action),
      ],
    ),
  );
}
