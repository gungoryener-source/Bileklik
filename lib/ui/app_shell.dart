import 'package:flutter/material.dart';

import '../state/device_controller.dart';
import 'screens/exercise_screen.dart';
import 'screens/health_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';

/// Ekranlara cihaz durumunu taşır; durum değişince dinleyenler yeniden çizilir.
class DeviceScope extends InheritedNotifier<DeviceController> {
  const DeviceScope({
    super.key,
    required DeviceController controller,
    required super.child,
  }) : super(notifier: controller);

  static DeviceController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeviceScope>()!.notifier!;
}

/// Alt menü: Ana Sayfa, Sağlık, Egzersiz, Profil.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Sekme sırası: 0 Ana Sayfa, 1 Sağlık, 2 Egzersiz, 3 Profil.
  static void selectTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_AppShellState>()?._select(index);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  static const _pages = [
    HomeScreen(),
    HealthScreen(),
    ExerciseScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _pages),
      ),
      // Yüzen görünümlü menü: kenarlardan boşluklu, yuvarlak köşeli; içerik
      // menünün altında kalmaz çünkü Scaffold ona kendi yerini ayırır.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.outline),
              borderRadius: BorderRadius.circular(28),
            ),
            child: NavigationBar(
              height: 68,
              backgroundColor: AppColors.surface,
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Ana Sayfa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Sağlık',
                ),
                NavigationDestination(
                  icon: Icon(Icons.directions_run_outlined),
                  selectedIcon: Icon(Icons.directions_run),
                  label: 'Egzersiz',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
