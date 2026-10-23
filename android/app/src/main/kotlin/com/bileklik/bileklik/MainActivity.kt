package com.bileklik.bileklik

import io.flutter.embedding.android.FlutterFragmentActivity

// health eklentisi Health Connect izinlerini registerForActivityResult ile
// ister; bunun için FlutterFragmentActivity gerekir.
class MainActivity : FlutterFragmentActivity() {
    // Health Connect izin ekranındaki "neden" bağlantısı ve Android 14+ izin
    // kullanımı ekranı uygulamayı gizlilik politikasıyla açar
    // (lib/ui/screens/privacy_screen.dart).
    override fun getInitialRoute(): String? = when (intent?.action) {
        "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE",
        "android.intent.action.VIEW_PERMISSION_USAGE" -> "/privacy"
        else -> super.getInitialRoute()
    }
}
