import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../theme.dart';

/// Ana Sayfa kartı: başlık, sonda ok (RTL'de ok kendiliğinden döner); kartın tamamı dokunulabilir.
class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.title,
    required this.child,
    this.onTap,
  });

  final String title;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.colors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (onTap != null)
                      Icon(Icons.chevron_right, color: context.colors.muted),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Büyük değer ve altında soluk birim/etiket hapı.
class BigValue extends StatelessWidget {
  const BigValue(this.value, {super.key, this.caption});

  final String? value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value ?? context.l10n.noValue,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              // Tire işareti eşit genişlikli rakamlarla aralıklı görünür.
              fontFeatures: [if (value != null) FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              caption!,
              style: TextStyle(color: context.colors.muted, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

/// Kartın altındaki 2-3 küçük değerlik satır.
class MiniStats extends StatelessWidget {
  const MiniStats(this.items, {super.key});

  /// (değer, etiket) çiftleri; değer null ise "--" yazılır.
  final List<(String?, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (value, label) in items)
            Expanded(
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value ?? context.l10n.noValue,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [
                          if (value != null) FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.colors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Veri yokken kullanıcıya ne yapacağını söyleyen satır.
class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: context.colors.outline),
          ),
          child: Icon(icon, size: 20, color: context.colors.muted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: context.colors.muted, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
