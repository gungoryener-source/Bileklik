import 'package:flutter/material.dart';

import 'cam/cam.dart';

/// Başlıklı, tek seçimli cam alt sayfa. Seçim yapılınca kapanır ve seçilen
/// değeri döner; dışına dokunulursa null.
Future<T?> showChoiceSheet<T>({
  required BuildContext context,
  required String title,
  required List<(T, String)> options,
  required T current,
}) {
  return showCamSheet<T>(
    context: context,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          RadioGroup<T>(
            groupValue: current,
            onChanged: (v) => Navigator.of(sheet).pop(v),
            child: Column(
              children: [
                for (final (value, label) in options)
                  RadioListTile<T>(
                    value: value,
                    minTileHeight: 56,
                    title: Text(label),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
