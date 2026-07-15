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
