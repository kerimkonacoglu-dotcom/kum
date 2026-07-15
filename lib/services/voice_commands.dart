import 'enigma_service.dart';
import 'rc_codes.dart';

/// Sesli komut metnini işleyip cihazda ilgili aksiyonu çalıştırır.
/// Türkçe anahtar kelimelere göre eşleştirir.
class VoiceCommands {
  final EnigmaService service;
  final List<ServiceRef> channels;
  VoiceCommands(this.service, {this.channels = const []});

  /// Metni işler, yapılan işlemi açıklayan bir metin döndürür.
  Future<String> handle(String rawText) async {
    final t = rawText.toLowerCase().trim();
    if (t.isEmpty) return 'Komut algılanamadı';

    bool has(List<String> words) => words.any((w) => t.contains(w));

    // --- Güç ---
    if (has(['kapat', 'kapan', 'uyku', 'standby'])) {
      await service.setPowerState(0);
      return 'Cihaz standby';
    }

    // --- Sessize alma ---
    if (has(['sessiz', 'mute'])) {
      await service.toggleMute();
      return 'Sessiz açık/kapalı';
    }

    // --- Ses ---
    if (has(['ses']) &&
        has(['aç', 'yükselt', 'artır', 'arttır', 'yukarı'])) {
      for (var i = 0; i < 3; i++) await service.volumeUp();
      return 'Ses yükseltildi';
    }
    if (has(['ses']) && has(['kıs', 'azalt', 'düşür', 'aşağı', 'kis'])) {
      for (var i = 0; i < 3; i++) await service.volumeDown();
      return 'Ses kısıldı';
    }

    // --- Kanal yukarı/aşağı ---
    if (has(['kanal']) && has(['sonraki', 'yukarı', 'ileri', 'artır'])) {
      await service.sendKey(RcCodes.channelUp);
      return 'Sonraki kanal';
    }
    if (has(['kanal']) && has(['önceki', 'aşağı', 'geri', 'azalt'])) {
      await service.sendKey(RcCodes.channelDown);
      return 'Önceki kanal';
    }

    // --- Yön / seçim ---
    if (has(['tamam', 'seç', 'onayla', 'ok'])) {
      await service.sendKey(RcCodes.ok);
      return 'OK';
    }
    if (has(['menü', 'menu'])) {
      await service.sendKey(RcCodes.menu);
      return 'Menü';
    }
    if (has(['geri', 'çıkış', 'cikis'])) {
      await service.sendKey(RcCodes.exit);
      return 'Çıkış';
    }
    if (has(['yukarı'])) {
      await service.sendKey(RcCodes.up);
      return 'Yukarı';
    }
    if (has(['aşağı'])) {
      await service.sendKey(RcCodes.down);
      return 'Aşağı';
    }
    if (has(['sola', 'sol'])) {
      await service.sendKey(RcCodes.left);
      return 'Sol';
    }
    if (has(['sağa', 'sağ'])) {
      await service.sendKey(RcCodes.right);
      return 'Sağ';
    }
    if (has(['bilgi', 'info'])) {
      await service.sendKey(RcCodes.info);
      return 'Bilgi';
    }

    // --- Kanal adına göre geçiş ---
    if (channels.isNotEmpty) {
      final match = _matchChannel(t);
      if (match != null) {
        await service.zap(match.reference);
        return '${match.name} kanalına geçildi';
      }
    }

    // --- Kanal numarası ---
    final digits = RegExp(r'\d+').firstMatch(t.replaceAll(' ', ''))?.group(0);
    if (digits != null && digits.isNotEmpty) {
      for (final ch in digits.split('')) {
        await service.sendKey(_digitKey(ch));
      }
      await service.sendKey(RcCodes.ok);
      return '$digits numarasına geçildi';
    }

    return 'Anlaşılamadı: "$rawText"';
  }

  ServiceRef? _matchChannel(String text) {
    for (final c in channels) {
      final name = c.name.toLowerCase();
      if (name.length >= 3 && text.contains(name)) return c;
    }
    return null;
  }

  int _digitKey(String d) {
    switch (d) {
      case '1':
        return RcCodes.key1;
      case '2':
        return RcCodes.key2;
      case '3':
        return RcCodes.key3;
      case '4':
        return RcCodes.key4;
      case '5':
        return RcCodes.key5;
      case '6':
        return RcCodes.key6;
      case '7':
        return RcCodes.key7;
      case '8':
        return RcCodes.key8;
      case '9':
        return RcCodes.key9;
      default:
        return RcCodes.key0;
    }
  }
}
