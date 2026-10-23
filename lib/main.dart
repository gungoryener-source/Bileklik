import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'data/community.dart';
import 'data/connections.dart';
import 'data/feedback.dart';
import 'data/health_platform.dart';
import 'data/health_store.dart';
import 'data/plugin_health_platform.dart';
import 'data/portal.dart';
import 'data/secrets.dart';
import 'data/sqlite_health_store.dart';
import 'device/ble_transport.dart';
import 'device/fake_device.dart';
import 'device/transport.dart';
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
  // Web'de güvenli depo yok; demo zaten saklamaz.
  final SecretStore secrets = kIsWeb ? MemorySecretStore() : DeviceSecretStore();
  final settings = await AppSettings.load(secrets: secrets);
  final controller = DeviceController(
    await _transport(),
    store: await _openStore(secrets),
    wearDetection: settings.wearDetection,
  );
  final portal = _portal(settings, controller);
  runApp(
    BileklikApp(
      controller: controller,
      settings: settings,
      healthExport: _healthExport(controller),
      connections: portal?.connections,
      feedback: portal?.feedback,
      account: portal?.account,
    ),
  );
}

/// Portal adresi: `--dart-define=PORTAL_URL=https://portal.example/`.
/// Verilmezse hekim bağlantıları sahte sunucuyla çalışır.
const _portalUrl = String.fromEnvironment('PORTAL_URL');

/// Portal adresi varsa gerçek servisler ve yükleyici; yoksa null.
({
  ConnectionService connections,
  FeedbackService feedback,
  PortalAccountService account,
})?
_portal(
  AppSettings settings,
  DeviceController controller,
) {
  if (_portalUrl.isEmpty) return null;
  final base = Uri.parse(_portalUrl.endsWith('/') ? _portalUrl : '$_portalUrl/');
  final client = PortalClient(
    baseUrl: base,
    httpClient: http.Client(),
    credentials: settings,
  );
  final service = PortalConnectionService(client);
  // Uygulama açık kaldıkça yeni ölçümleri yükler.
  PortalUploader(client: client, connections: service, store: controller.store);
  unawaited(service.refresh().catchError((Object _) {}));
  return (
    connections: service,
    feedback: PortalFeedbackService(client),
    // Hesap geri yüklenince bağlantılar yeni hesaptan gelir.
    account: PortalAccountService(client, onRecovered: service.refresh),
  );
}

/// Demo kipi: `flutter run --dart-define=DEMO=true` sahte bileklik ve sahte
/// sağlık platformuyla çalışır (bileklik elde yokken). Web'de her zaman demo.
const _demo = bool.fromEnvironment('DEMO');

bool get _usesRealDevices =>
    !_demo &&
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Telefonda gerçek BLE, demoda ve web'de sahte cihaz.
Future<DeviceTransport> _transport() async => _usesRealDevices
    ? BleTransport(prefs: await SharedPreferences.getInstance())
    : FakeDevice();

/// Telefonda Health Connect / Apple Health'e gerçekten yazar; demoda null
/// (BileklikApp sahte platformu kullanır).
HealthExportService? _healthExport(DeviceController controller) =>
    _usesRealDevices
    ? HealthExportService(PluginHealthPlatform(), controller.store)
    : null;

/// Manrope yazı tipinin lisansı "Lisanslar" sayfasında görünsün.
Stream<LicenseEntry> _fontLicense() async* {
  final text = await rootBundle.loadString('assets/fonts/Manrope-OFL.txt');
  yield LicenseEntryWithLineBreaks(const ['Manrope'], text);
}

/// Telefonda şifreli SQLite (SQLCipher); web demosunda (sqflite web'de yok)
/// ya da veritabanı açılamazsa bellek. Açılamama durumu raporlanır, uygulama
/// yine açılır.
Future<HealthStore> _openStore(SecretStore secrets) async {
  if (kIsWeb) return MemoryHealthStore();
  try {
    return await SqliteHealthStore.openEncrypted(
      secrets,
      onKeyLost: () => FlutterError.reportError(
        FlutterErrorDetails(
          exception: StateError('veritabanı anahtarı yok; dosya yeniden kuruldu'),
          library: 'bileklik',
        ),
      ),
    );
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
    FeedbackService? feedback,
    this.account,
  }) : settings = settings ?? AppSettings.memory(),
       feedback = feedback ?? FakeFeedbackService(),
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
  final FeedbackService feedback;

  /// Portal hesabı (kurtarma kodu); yalnızca portal adresi verildiyse.
  final PortalAccountService? account;

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
              child: FeedbackScope(
                service: feedback,
                child: AccountScope(
                service: account,
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
        ),
      ),
    );
  }
}
