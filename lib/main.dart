import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/community.dart';
import 'data/connections.dart';
import 'data/health_platform.dart';
import 'data/health_store.dart';
import 'data/sqlite_health_store.dart';
import 'device/fake_device.dart';
import 'l10n/l10n.dart';
import 'state/app_settings.dart';
import 'state/device_controller.dart';
import 'ui/app_shell.dart';
import 'ui/format.dart';
import 'ui/screens/language_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Uygulama sistem çubuklarının altına uzanır; çubuklar saydam.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(camSystemOverlay);
  LicenseRegistry.addLicense(_fontLicense);
  final settings = await AppSettings.load();
  // Bileklik gelene kadar sahte cihaz kullanılır. Gerçek BLE katmanı
  // eklendiğinde yalnızca bu satır değişecek.
  final controller = DeviceController(
    FakeDevice(),
    store: await _openStore(),
    wearDetection: settings.wearDetection,
  );
  runApp(BileklikApp(controller: controller, settings: settings));
}

/// Manrope yazı tipinin lisansı "Lisanslar" sayfasında görünsün.
Stream<LicenseEntry> _fontLicense() async* {
  final text = await rootBundle.loadString('assets/fonts/Manrope-OFL.txt');
  yield LicenseEntryWithLineBreaks(const ['Manrope'], text);
}

/// Telefonda SQLite; web demosunda (sqflite web'de yok) ya da veritabanı
/// açılamazsa bellek. Açılamama durumu raporlanır, uygulama yine açılır.
Future<HealthStore> _openStore() async {
  if (kIsWeb) return MemoryHealthStore();
  try {
    return await SqliteHealthStore.open();
  } catch (e, s) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: e, stack: s, library: 'bileklik'),
    );
    return MemoryHealthStore();
  }
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

  static final _theme = buildTheme();

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
                  builder: (context, child) => LocaleSync(
                    child: DisplaySync(
                      clock: settings.clock,
                      units: settings.units,
                      child: child!,
                    ),
                  ),
                  // Tek tema: koyu Cam.
                  theme: _theme,
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
