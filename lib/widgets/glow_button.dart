import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'pressable.dart';

/// Parlayan degrade ana eylem butonu ("Şimdi ölç" gibi).
class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;

  /// `null` ise buton pasif görünür.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final radius = BorderRadius.circular(24);
    return Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(16, 14, 20, 14),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.ctaStart, AppColors.ctaEnd],
            ),
            boxShadow: enabled
                ? const [
                    BoxShadow(
                      color: AppColors.ctaGlow,
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          // Üstte ışık, altta hafif gölge: 3D kabartma hissi.
          foregroundDecoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x38FFFFFF), Color(0x00FFFFFF), Color(0x1A000000)],
              stops: [0, 0.5, 1],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 8),
              Flexible(child: Text(label, style: AppText.button)),
            ],
          ),
        ),
      ),
    );
  }
}
