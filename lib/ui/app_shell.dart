import 'package:flutter/material.dart';

import '../data/community.dart';
import '../data/connections.dart';
import '../data/feedback.dart';
import '../data/health_platform.dart';
import '../data/portal.dart';
import '../l10n/l10n.dart';

import '../state/app_settings.dart';
import '../state/device_controller.dart';
import 'screens/exercise_screen.dart';
import 'screens/health_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/cam/cam.dart';

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

/// Uygulama tercihlerini (dil) ekranlara taşır.
class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

/// Sağlık topluluğu sunucusunu (gruplar, davetler, izinler) ekranlara taşır.
class CommunityScope extends InheritedNotifier<CommunityService> {
  const CommunityScope({
    super.key,
    required CommunityService service,
    required super.child,
  }) : super(notifier: service);

  static CommunityService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CommunityScope>()!.notifier!;

  /// Topluluk yoksa (bazı testler) null.
  static CommunityService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CommunityScope>()?.notifier;
}

/// Hekim ve araştırma kurumu bağlantılarını ekranlara taşır.
class ConnectionScope extends InheritedNotifier<ConnectionService> {
  const ConnectionScope({
    super.key,
    required ConnectionService service,
    required super.child,
  }) : super(notifier: service);

  static ConnectionService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ConnectionScope>()!.notifier!;
}

/// Geri bildirim gönderen servisi ekranlara taşır.
class FeedbackScope extends InheritedWidget {
  const FeedbackScope({super.key, required this.service, required super.child});

  final FeedbackService service;

  static FeedbackService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FeedbackScope>()!.service;

  @override
  bool updateShouldNotify(FeedbackScope old) => service != old.service;
}

/// Portal hesabı servisi; portal adresi verilmediyse null.
class AccountScope extends InheritedWidget {
  const AccountScope({super.key, required this.service, required super.child});

  final PortalAccountService? service;

  static PortalAccountService? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AccountScope>()?.service;

  @override
  bool updateShouldNotify(AccountScope old) => service != old.service;
}

/// Telefonun sağlık platformuna (Health Connect / Apple Health) aktarımı
/// ekranlara taşır.
class HealthExportScope extends InheritedNotifier<HealthExportService> {
  const HealthExportScope({
    super.key,
    required HealthExportService service,
    required super.child,
  }) : super(notifier: service);

  static HealthExportService of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<HealthExportScope>()!
      .notifier!;
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
    final l = context.l10n;
    return CamScaffold(
      // Menü içeriğin üstünde yüzer; içerik altından kayar ve bulanık görünür.
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: GlassNavBar(
        semanticLabel: l.navSemantics,
        selectedIndex: _index,
        onSelected: _select,
        items: [
          (icon: Icons.home_outlined, activeIcon: Icons.home, label: l.navHome),
          (
            icon: Icons.favorite_border,
            activeIcon: Icons.favorite,
            label: l.navHealth,
          ),
          (
            icon: Icons.directions_run_outlined,
            activeIcon: Icons.directions_run,
            label: l.navExercise,
          ),
          (
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: l.navProfile,
          ),
        ],
      ),
    );
  }
}
