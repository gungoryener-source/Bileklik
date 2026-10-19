import 'package:flutter/material.dart';

import '../theme.dart';

/// Etiket ve büyük değerden oluşan kart; değer sığmazsa küçülür.
class StatTile extends StatelessWidget {
  const StatTile(this.label, this.value, {super.key, this.unit = ''});

  final String label;
  final String? value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final v = value ?? '--';
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.colors.muted),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                unit.isEmpty ? v : '$v $unit',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
