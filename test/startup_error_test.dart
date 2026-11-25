import 'package:bileklik/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('açılış hatası metni ve kopyalama düğmesi görünür', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      StartupErrorApp(error: StateError('veritabanı açılamadı')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Uygulama başlatılamadı'), findsOneWidget);
    expect(find.text('Hatayı kopyala'), findsOneWidget);
    expect(find.textContaining('veritabanı açılamadı'), findsOneWidget);
  });
}
