import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme.dart';

/// Profil ve topluluk menülerinin ortak parçaları.

/// Grup başlığı.
class MenuHeader extends StatelessWidget {
  const MenuHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(4, 24, 4, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: context.colors.muted, fontWeight: FontWeight.w600),
    ),
  );
}

/// Kenarlı kart içinde, aralarında ince çizgi olan satırlar.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: context.colors.outline),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              indent: 72,
              endIndent: 16,
              color: context.colors.outline,
            ),
          children[i],
        ],
      ],
    ),
  );
}

class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.soon = false,
    this.large = false,
    this.badge = 0,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Sağda (Arapçada solda) gösterilen değer; varsa ok çizilmez.
  final String? value;
  final VoidCallback? onTap;
  final bool soon;
  final bool large;

  /// Okunmamış sayısı; sıfırdan büyükse okun yanında rozet çizilir.
  final int badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = large ? 48.0 : 40.0;
    final Widget? trailing = value != null
        ? Text(value!, style: TextStyle(color: colors.muted))
        : soon
        ? const SoonChip()
        : onTap != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge > 0) Badge(label: Text('$badge')),
              Icon(Icons.chevron_right, color: colors.muted),
            ],
          )
        : null;
    return ListTile(
      minTileHeight: large ? 76 : 60,
      contentPadding: const EdgeInsetsDirectional.only(start: 16, end: 12),
      leading: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: large ? colors.glow : colors.surfaceHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: large ? 26 : 22,
          color: large ? colors.accent : colors.text,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: large ? FontWeight.w600 : FontWeight.w500,
          fontSize: large ? 17 : 15,
          color: soon ? colors.muted : colors.text,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: TextStyle(color: colors.muted)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class SoonChip extends StatelessWidget {
  const SoonChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: context.colors.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      context.l10n.comingSoon,
      style: TextStyle(color: context.colors.muted, fontSize: 12),
    ),
  );
}
