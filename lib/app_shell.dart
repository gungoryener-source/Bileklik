import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models/daily_summary.dart';
import 'screens/home_screen.dart';
import 'screens/placeholder_screen.dart';
import 'theme/app_colors.dart';
import 'widgets/aurora_background.dart';
import 'widgets/glass_nav_bar.dart';

/// Uygulama kabuğu: aurora zemin, sekmeler ve yüzen cam alt menü.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  // TODO: JCV8 bileklik bağlantısı yapılınca gerçek veriyle değiştir.
  final DailySummary _summary = DailySummary.sample;
  final BandStatus _band = const BandStatus(connected: true, batteryPercent: 78);

  void _comingSoon(String feature, double bottomMargin) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature yakında'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(20, 0, 20, bottomMargin),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final navBottom = math.max(bottomInset, 12.0) + 10;
    final contentBottom = GlassNavBar.height + navBottom + 24;
    final snackMargin = GlassNavBar.height + navBottom + 12;

    return Scaffold(
      backgroundColor: AppColors.bgMid,
      body: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          Positioned.fill(
            child: IndexedStack(
              index: _tab,
              children: [
                HomeScreen(
                  summary: _summary,
                  band: _band,
                  bottomPadding: contentBottom,
                  onMeasure: () => _comingSoon('Nabız ölçümü', snackMargin),
                  onWorkout: () => _comingSoon('Antrenman', snackMargin),
                  onSync: () => _comingSoon('Senkronizasyon', snackMargin),
                ),
                PlaceholderScreen(
                  title: 'Etkinlik',
                  icon: Icons.show_chart_rounded,
                  bottomPadding: contentBottom,
                ),
                PlaceholderScreen(
                  title: 'Uyku',
                  icon: Icons.nightlight_round,
                  bottomPadding: contentBottom,
                ),
                PlaceholderScreen(
                  title: 'Profil',
                  icon: Icons.person_outline_rounded,
                  bottomPadding: contentBottom,
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: navBottom,
            child: GlassNavBar(
              selectedIndex: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
          ),
        ],
      ),
    );
  }
}
