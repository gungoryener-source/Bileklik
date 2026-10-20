# Bileklik

JCV8 bileklik için iOS ve Android sağlık uygulaması (Flutter).

## İlk kurulum

Repoda henüz `android/` ve `ios/` klasörleri yok. Bir kez şunu çalıştır:

```
flutter create . --project-name bileklik --platforms=android,ios --org com.sirketadi
flutter pub get
flutter run
```

`flutter create .` mevcut dosyalara (`lib/`, `test/`, `pubspec.yaml`) dokunmaz, yalnızca eksik platform dosyalarını ekler. `--org` yerine kendi alan adını yaz (uygulama kimliği bundan oluşur).

Android release sürümü için `android/app/src/main/AndroidManifest.xml` içine internet izni ekle (Manrope yazı tipi ilk açılışta indiriliyor):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Yapı

- `lib/theme/`: renkler (`AppColors`), yazı stilleri (`AppText`), tema
- `lib/widgets/`: cam tasarım bileşenleri (kart, buton, alt menü, 3D çizimler)
- `lib/screens/`: ekranlar
- `lib/models/`: veri modelleri
- `lib/app_shell.dart`: zemin, sekmeler ve alt menü

## Kontrol

```
flutter analyze
flutter test
```
