import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/community.dart';
import 'data/connections.dart';
import 'data/health_platform.dart';
import 'device/fake_device.dart';
import 'l10n/l10n.dart';
import 'state/app_settings.dart';
import 'state/device_controller.dart';
import 'ui/app_shell.dart';
import 'ui/screens/language_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  // Bileklik gelene kadar sahte cihaz kullanılır. Gerçek BLE katmanı
  // eklendiğinde yalnızca bu satır değişecek.
  final controller = DeviceController(FakeDevice());
  runApp(BileklikApp(controller: controller, settings: settings));
}

class BileklikApp extends StatelessWidget {
  BileklikApp({
    super.key,
    required this.controller,
    AppSettings? settings,
    CommunityService? community,
    ConnectionService? connections,
    HealthExportService? healthExport,
  }) : settings = settings ?? AppSettings.memory(),
       // Portal arka ucu gelene kadar sahte sunucular.
       community = community ?? FakeCommunityServer(),
       connections = connections ?? FakeConnectionServer(),
       healthExport =
           healthExport ??
           HealthExportService(
             FakeHealthPlatform(
               kind: defaultTargetPlatform == TargetPlatform.iOS
                   ? HealthPlatformKind.appleHealth
                   : HealthPlatformKind.healthConnect,
             ),
             controller.store,
           );

  final DeviceController controller;
  final AppSettings settings;
  final CommunityService community;
  final ConnectionService connections;
  final HealthExportService healthExport;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: settings,
      child: DeviceScope(
        controller: controller,
        child: CommunityScope(
          service: community,
          child: ConnectionScope(
            service: connections,
            child: HealthExportScope(
              service: healthExport,
              child: ListenableBuilder(
                listenable: settings,
                builder: (context, _) => MaterialApp(
                  onGenerateTitle: (context) => context.l10n.appTitle,
                  debugShowCheckedModeBanner: false,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  // Telefonun dili desteklenmiyorsa listenin ilki (İngilizce) seçilir.
                  supportedLocales: const [
                    Locale('en'),
                    Locale('tr'),
                    Locale('ar'),
                    Locale('de'),
                  ],
                  // null: telefonun dili.
                  locale: settings.locale,
                  builder: (context, child) => LocaleSync(child: child!),
                  theme: buildTheme(Brightness.light),
                  darkTheme: buildTheme(Brightness.dark),
                  themeMode: settings.themeMode,
                  // İlk açılışta dil seçilir; sonra Profil'den değişir.
                  home: settings.languageChosen
                      ? const AppShell()
                      : const LanguageScreen(firstRun: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
