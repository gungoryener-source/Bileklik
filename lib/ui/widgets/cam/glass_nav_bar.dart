import 'package:flutter/material.dart';

import '../../theme.dart';
import 'glass_card.dart';
import 'pressable.dart';

/// Alt menü öğesi.
typedef GlassNavItem = ({IconData icon, IconData activeIcon, String label});

/// İçeriğin üstünde yüzen cam alt menü; gerçek bulanıklık burada.
/// Yükseklik 70, köşe 35; kenarlardan 20, alttan güvenli alan + 10.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.semanticLabel,
  });

  static const height = 70.0;

  /// Kaydırılan içeriğin menünün altında kalmaması için gereken alt boşluk.
  ///
  /// Menü `extendBody: true` olan bir iskelette durur; iskelet gövdeye
  /// verdiği alt boşluğa menünün yüksekliğini zaten ekler.
  static double clearance(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 16;

  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Etiketler çok büyürse menü bozulur; büyütmeyi sınırla.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 10),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: semanticLabel,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: SizedBox(
              height: height,
              child: GlassCard(
                radius: 35,
                blur: true,
                baseColor: c.navBase,
                padding: const EdgeInsets.all(7),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _NavButton(
                            item: items[i],
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
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reduce = MediaQuery.of(context).disableAnimations;
    final color = active ? c.text : c.muted;
    final radius = BorderRadius.circular(28);
    return Pressable(
      semanticLabel: item.label,
      selected: active,
      onTap: onTap,
      child: AnimatedContainer(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: radius,
          // Seçili değilken aynı şekil saydam: geçiş yumuşak olsun.
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? [c.navActiveStart, c.navActiveEnd]
                : [
                    c.navActiveStart.withValues(alpha: 0),
                    c.navActiveEnd.withValues(alpha: 0),
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? c.navActiveGlow
                  : c.navActiveGlow.withValues(alpha: 0),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? item.activeIcon : item.icon, size: 22, color: color),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
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
