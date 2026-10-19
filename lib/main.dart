import 'package:flutter/material.dart';

import 'device/fake_device.dart';
import 'state/app_settings.dart';
import 'state/device_controller.dart';
import 'ui/app_shell.dart';
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
  BileklikApp({super.key, required this.controller, AppSettings? settings})
    : settings = settings ?? AppSettings.memory();

  final DeviceController controller;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: settings,
      child: DeviceScope(
        controller: controller,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => MaterialApp(
            title: 'Bileklik',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: settings.themeMode,
            home: const AppShell(),
          ),
        ),
      ),
    );
  }
}
