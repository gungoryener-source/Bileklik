import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'glass_card.dart';
import 'pressable.dart';

/// İçeriğin üstünde yüzen cam alt menü. Gerçek bulanıklık yalnızca burada.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  /// Yaklaşık yükseklik; içerik alt boşluğu hesaplanırken kullanılır.
  static const double height = 70;

  static const items = <(IconData, String)>[
    (Icons.home_rounded, 'Ana ekran'),
    (Icons.show_chart_rounded, 'Etkinlik'),
    (Icons.nightlight_round, 'Uyku'),
    (Icons.person_outline_rounded, 'Profil'),
  ];

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // Menü etiketleri çok büyürse menü bozulur; büyütmeyi sınırla.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Ana menü',
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            boxShadow: const [
              BoxShadow(
                color: Color(0x73000000),
                blurRadius: 36,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: GlassCard(
            radius: 35,
            blur: true,
            baseColor: AppColors.navBase,
            padding: const EdgeInsets.all(7),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _NavItem(
                        icon: items[i].$1,
                        label: items[i].$2,
                        active: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  static final _activeDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(27),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.navActiveStart, AppColors.navActiveEnd],
    ),
    boxShadow: const [
      BoxShadow(color: AppColors.navActiveGlow, blurRadius: 20, offset: Offset(0, 8)),
    ],
  );

  // Aynı şekil, saydam renkler: geçiş animasyonu yumuşak olsun diye.
  static final _idleDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(27),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x007B5CFF), Color(0x00D9225F)],
    ),
    boxShadow: const [
      BoxShadow(color: Color(0x009646FF), blurRadius: 20, offset: Offset(0, 8)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final color = active ? AppColors.textPrimary : AppColors.textMuted;
    return Pressable(
      semanticLabel: label,
      selected: active,
      onTap: onTap,
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: active ? _activeDecoration : _idleDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppText.navLabel.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
