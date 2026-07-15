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
