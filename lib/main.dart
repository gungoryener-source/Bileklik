import 'package:flutter/material.dart';

import 'device/fake_device.dart';
import 'state/device_controller.dart';
import 'ui/app_shell.dart';
import 'ui/theme.dart';

void main() {
  // Bileklik gelene kadar sahte cihaz kullanılır. Gerçek BLE katmanı
  // eklendiğinde yalnızca bu satır değişecek.
  final controller = DeviceController(FakeDevice());
  runApp(BileklikApp(controller: controller));
}

class BileklikApp extends StatelessWidget {
  const BileklikApp({super.key, required this.controller});

  final DeviceController controller;

  @override
  Widget build(BuildContext context) {
    return DeviceScope(
      controller: controller,
      child: MaterialApp(
        title: 'Bileklik',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AppShell(),
      ),
    );
  }
}
