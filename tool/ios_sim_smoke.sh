#!/usr/bin/env bash
# iOS simülatöründe açılış denemesi (CI: .github/workflows/ios.yml).
# Kullanım: tool/ios_sim_smoke.sh <simülatör UDID> <etiket>
# Uygulamayı kurar, açar, 30 sn bekler; hâlâ çalışıyorsa geçer. Ekran
# görüntüsü, uygulama çıktısı ve varsa çökme raporu ios-sim/ altına yazılır.
set -uo pipefail

UDID="$1"
LABEL="$2"
BUNDLE_ID="${BUNDLE_ID:-com.bileklik.bileklik}"
APP=build/ios/iphonesimulator/Runner.app
OUT=ios-sim
mkdir -p "$OUT"

xcrun simctl uninstall "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl install "$UDID" "$APP"
# Bluetooth ve sağlık izinleri simülatörde sorulmaz ya da yok sayılır.
xcrun simctl launch --terminate-running-process \
  --stdout="$PWD/$OUT/$LABEL-cikti.log" --stderr="$PWD/$OUT/$LABEL-cikti.log" \
  "$UDID" "$BUNDLE_ID"

sleep 30
xcrun simctl io "$UDID" screenshot "$OUT/$LABEL.png"

if xcrun simctl spawn "$UDID" launchctl list | grep -q "UIKitApplication:$BUNDLE_ID"; then
  echo "Uygulama ($LABEL) 30 sn sonra çalışıyor."
  ok=1
else
  echo "::error::Uygulama ($LABEL) simülatörde kapandı."
  ok=0
fi

if grep -q "EXCEPTION CAUGHT BY" "$OUT/$LABEL-cikti.log" 2>/dev/null; then
  echo "::warning::Flutter hata yakaladı ($LABEL); ayrıntı $OUT/$LABEL-cikti.log"
  grep -A12 "EXCEPTION CAUGHT BY" "$OUT/$LABEL-cikti.log" | head -60
fi

xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
if [ "$ok" = 0 ]; then
  cp ~/Library/Logs/DiagnosticReports/Runner* "$OUT/" 2>/dev/null || true
  tail -80 "$OUT/$LABEL-cikti.log" 2>/dev/null
  exit 1
fi
