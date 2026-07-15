
# Flutter/Dart
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies
pubspec.lock

# Android
android/local.properties
android/.gradle/
android/app/debug/
android/app/profile/
android/app/release/

# IDE
.idea/
.vscode/
*.iml

# Hazir APK'yi alma (2 yol)

Bu paket TAM bir Flutter projesidir (android/ klasoru, gradle wrapper,
ikonlar dahil). Dogrudan derlenir.

## Yol 1 - GitHub uzerinden (bilgisayara kurulum gerekmez)

1. github.com'da ucretsiz hesap ac, yeni repository olustur.
2. Bu klasordeki TUM dosya ve klasorleri repoya yukle
   (gizli .github ve android klasorleri dahil - hepsi olmali).
   Add file -> Upload files -> hepsini surukle -> Commit.
3. "Actions" sekmesine gec; "APK Derle" isi otomatik baslar (~5-8 dk).
4. Is yesil tik alinca ustune tikla -> altta "Artifacts" -> "media-tivi-apk"
   indir -> icinden app-release.apk cikar.
5. APK'yi telefona at, "bilinmeyen kaynaklara izin ver" deyip kur.

## Yol 2 - Kendi bilgisayarinda (Flutter kuruluysa)

    flutter pub get
    flutter build apk --release
    # cikti: build/app/outputs/flutter-apk/app-release.apk

iOS de istersen (Mac gerekir):
    flutter create . --platforms=ios
    flutter build ios

## Notlar

- APK debug anahtariyla imzalanir; kendi telefonuna kurulur.
  Play Store icin ayri imzalama (keystore) gerekir.
- Ilk acilista uygulama mikrofon izni ister (sesli komut icin).
- Uygulama HTTP kullanir; cleartext izni manifest'te zaten acik.

# media tivi - Uydu/IPTV Kumanda (TAM PROJE)

Linux tabanli uydu/IPTV kutularini (Sungate Titan 4K, Hiremco Turbo, VIP Box,
ayrica Enigma2: Vu+/Zgemma/Dreambox vb.) IP uzerinden yoneten Flutter uygulamasi.

Bu paket TAM projedir: android/ klasoru, gradle wrapper ve markali ikonlar dahil.
Dogrudan derlenir. APK almak icin APK_NASIL_ALINIR.md'ye bak.

## Klasor yapisi

    android/                 tam Android projesi (gradle, manifest, ikonlar)
      app/
        build.gradle
        src/main/AndroidManifest.xml   (izinler + cleartext hazir)
        src/main/kotlin/.../MainActivity.kt
        src/main/res/mipmap-*/ic_launcher.png  (media tivi ikonu)
      build.gradle, settings.gradle, gradle.properties
      gradle/wrapper/                  gradle-wrapper.jar dahil
      gradlew, gradlew.bat
    lib/                     Dart kaynak kodu
      main.dart
      models/device.dart
      services/  (enigma_service, device_store, favorites_store,
                  voice_commands, wol, settings, rc_codes)
      screens/   (home, device_form, remote, channels, info,
                  web_panel, voice_sheet, settings)
    assets/                  logo + ikon kaynaklari
    pubspec.yaml
    .github/workflows/build-apk.yml   otomatik APK derleme
    .gitignore

## Ozellikler

- Web Panel: cihazin kendi web arayuzunu (http://IP/) uygulama icinde acar
  (GX RCU'nun yaptigi yontem - her Linux kutuda calisir)
- Tam kumanda: yon+OK, renkli tuslar, rakamlar, medya tuslari
- Dokunmatik mod: kaydirarak yon, dokunarak OK
- Sesli komut (Turkce): "sesi ac", "kanal yukari", "menu", "23", "kapat"...
- Kanal listesi + favoriler (yildizla) + arama
- EPG: anlik kanal + su an oynayan program
- Ses kaydiricisi, TV ekranina mesaj, ekran goruntusu (paylasilabilir)
- Wake-on-LAN: MAC girilirse kapali cihazi acar
- Coklu cihaz kaydi, ayarlar (tema + titresim)
- media tivi markasi: app ikonu + ana ekran logosu

## Teknik

- Paket adi: com.mediativi.uydu_kumanda
- minSdk 21, targetSdk/compileSdk 34
- Flutter 3.24.x, AGP 8.1, Gradle 8.3, Kotlin 1.9
- Not: Burada derleyici olmadigindan flutter analyze calistirilamadi.
  Ilk derlemede uyari cikarsa Actions logunu paylas.

name: uydu_kumanda
description: media tivi - Linux uydu/IPTV alıcısı uzaktan kumanda uygulaması.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  shared_preferences: ^2.2.0
  webview_flutter: ^4.4.0
  speech_to_text: ^6.6.0
  share_plus: ^7.2.2
  path_provider: ^2.1.2

dev_dependencies:
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/logo.png
