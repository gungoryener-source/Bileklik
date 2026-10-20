import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../widgets/glass_card.dart';

/// Henüz yapılmamış sekmeler için geçici ekran.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    this.bottomPadding = 120,
  });

  final String title;
  final IconData icon;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
            child: Semantics(header: true, child: Text(title, style: AppText.title)),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Column(
              children: [
                Icon(icon, size: 40, color: const Color(0xB3FFFFFF)),
                const SizedBox(height: 12),
                Text('Bu ekran yakında', style: AppText.cardLabel),
                const SizedBox(height: 4),
                Text(
                  'Cam tasarım diliyle hazırlanacak.',
                  textAlign: TextAlign.center,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
