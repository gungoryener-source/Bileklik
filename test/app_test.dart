import 'dart:math';

import 'package:bileklik/device/fake_device.dart';
import 'package:bileklik/main.dart';
import 'package:bileklik/state/device_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sahte bilekliğe bağlanınca canlı değerler görünür', (
    tester,
  ) async {
    final device = FakeDevice(
      random: Random(3),
      realtimeInterval: const Duration(seconds: 1),
    );
    final controller = DeviceController(device);
    await tester.pumpWidget(BileklikApp(controller: controller));

    expect(find.text('Bağlı değil'), findsOneWidget);
    await tester.runAsync(() async {
      await controller.connect().catchError((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.textContaining('Bağlı ·'), findsOneWidget);
    expect(find.text('Egzersize başla'), findsOneWidget);
    expect(controller.live, isNotNull);

    await tester.runAsync(() async {
      await controller.disconnect();
    });
    device.dispose();
  });
}
