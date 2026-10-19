import 'package:flutter/material.dart';

import '../state/device_controller.dart';
import 'screens/health_screen.dart';
import 'screens/home_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/profile_screen.dart';

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

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    HealthScreen(),
    PlaceholderScreen(
      title: 'Egzersiz',
      description: 'Spor seçimi, canlı egzersiz ve egzersiz geçmişi sonraki adımda gelecek.',
    ),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
    );
  }
}
