import 'dart:io';

/// Wake-on-LAN sihirli paketi göndererek cihazı açar.
/// Cihazın MAC adresi ve WOL desteği gerekir.
class Wol {
  static Future<bool> wake(String mac) async {
    final packet = _magicPacket(mac);
    if (packet == null) return false;
    try {
      final socket =
          await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(packet, InternetAddress('255.255.255.255'), 9);
      socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<int>? _magicPacket(String mac) {
    final clean = mac.replaceAll(RegExp('[^0-9a-fA-F]'), '');
    if (clean.length != 12) return null;
    final macBytes = <int>[
      for (var i = 0; i < 12; i += 2)
        int.parse(clean.substring(i, i + 2), radix: 16)
    ];
    return [
      ...List.filled(6, 0xFF),
      for (var i = 0; i < 16; i++) ...macBytes,
    ];
  }
}
