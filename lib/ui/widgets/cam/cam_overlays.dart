import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Bulanık cam diyalog: arkadaki ekran bulanıklaşır, diyalog yarı saydam
/// cam olarak üstte durur. [showDialog] yerine kullanılır.
Future<T?> showCamDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final c = context.colors;
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: c.scrim,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: builder(ctx),
    ),
  );
}

/// Bulanık cam alt sayfa. [showModalBottomSheet] yerine kullanılır; içerik
/// uzunsa kaydırılır.
Future<T?> showCamSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0x00000000),
    barrierColor: c.scrim,
    elevation: 0,
    builder: (ctx) => _GlassSheet(child: builder(ctx)),
  );
}

class _GlassSheet extends StatelessWidget {
  const _GlassSheet({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const radius = BorderRadius.vertical(top: Radius.circular(32));
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          // Taban rengi ve parlaklık ayrı katmanlarda: BoxDecoration'da
          // degrade verilince renk yok sayılır.
          child: DecoratedBox(
            decoration: BoxDecoration(color: c.floating, borderRadius: radius),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border(top: BorderSide(color: c.glassBorder)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.glassSheenStart, c.glassSheenEnd],
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 10, bottom: 14),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: c.offline,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
