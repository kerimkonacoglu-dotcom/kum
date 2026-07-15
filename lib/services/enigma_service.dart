import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/device.dart';

/// Enigma2 alıcısını OpenWebif HTTP API üzerinden yöneten servis.
class EnigmaService {
  final Device device;
  EnigmaService(this.device);

  Uri _uri(String path, [Map<String, String>? query]) => Uri(
        scheme: 'http',
        host: device.host,
        port: device.port,
        path: path,
        queryParameters: query,
      );

  Map<String, String> get _headers {
    final u = device.username;
    if (u != null && u.isNotEmpty) {
      final creds = base64Encode(utf8.encode('$u:${device.password ?? ''}'));
      return {'authorization': 'Basic $creds'};
    }
    return {};
  }

  Future<http.Response> _get(String path, [Map<String, String>? query]) =>
      http
          .get(_uri(path, query), headers: _headers)
          .timeout(const Duration(seconds: 7));

  // --- Basit XML yardımcıları (RegExp tabanlı) ---
  static String _tag(String xml, String tag) =>
      RegExp('<$tag>(.*?)</$tag>', dotAll: true)
          .firstMatch(xml)
          ?.group(1)
          ?.trim() ??
      '';

  static List<String> _blocks(String xml, String tag) => RegExp(
        '<$tag>(.*?)</$tag>',
        dotAll: true,
      ).allMatches(xml).map((m) => m.group(1) ?? '').toList();

  // --- Bağlantı & bilgi ---
  Future<DeviceInfo> connect() async {
    final res = await _get('/web/about');
    if (res.statusCode == 401) throw Exception('Kimlik doğrulama gerekli');
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return DeviceInfo.fromXml(res.body);
  }

  Future<DeviceInfo> info() async {
    final res = await _get('/web/about');
    return DeviceInfo.fromXml(res.body);
  }

  // --- Tuş gönderme ---
  Future<void> sendKey(int command) async {
    await _get('/web/remotecontrol', {'command': command.toString()});
  }

  // --- Güç ---
  /// 0=Standby aç/kapa, 1=Deep standby, 2=Reboot, 3=Enigma restart, 4=Wakeup
  Future<void> setPowerState(int newState) async {
    await _get('/web/powerstate', {'newstate': newState.toString()});
  }

  // --- Ses ---
  Future<void> volumeUp() => _get('/web/vol', {'set': 'up'});
  Future<void> volumeDown() => _get('/web/vol', {'set': 'down'});
  Future<void> toggleMute() => _get('/web/vol', {'set': 'mute'});
  Future<void> setVolume(int level) => _get('/web/vol', {'set': 'set$level'});

  Future<VolumeInfo> getVolume() async {
    final res = await _get('/web/vol');
    return VolumeInfo.fromXml(res.body);
  }

  // --- Ekrana mesaj ---
  Future<void> sendMessage(String text,
      {int type = 2, int timeout = 8}) async {
    await _get('/web/message', {
      'text': text,
      'type': type.toString(),
      'timeout': timeout.toString(),
    });
  }

  // --- Anlık kanal + EPG (şimdi/sonra) ---
  Future<NowPlaying> nowPlaying() async {
    final res = await _get('/web/getcurrent');
    final xml = res.body;
    // Servis bilgisi (e2service içindeki e2servicename)
    final serviceBlocks = _blocks(xml, 'e2service');
    final name =
        serviceBlocks.isNotEmpty ? _tag(serviceBlocks.first, 'e2servicename') : '';
    // EPG: e2eventnow / e2eventnext bloklarındaki e2eventname
    final nowBlocks = _blocks(xml, 'e2eventnow');
    final nextBlocks = _blocks(xml, 'e2eventnext');
    final nowTitle =
        nowBlocks.isNotEmpty ? _tag(nowBlocks.first, 'e2eventname') : '';
    final nextTitle =
        nextBlocks.isNotEmpty ? _tag(nextBlocks.first, 'e2eventname') : '';
    return NowPlaying(
      channel: name.isEmpty ? 'Bilinmiyor' : name,
      nowTitle: nowTitle,
      nextTitle: nextTitle,
    );
  }

  // --- Buketler (kanal grupları) ---
  Future<List<ServiceRef>> bouquets() async {
    final res = await _get('/web/getservices');
    return _parseServices(res.body);
  }

  // --- Bir buketin kanalları ---
  Future<List<ServiceRef>> channels(String bouquetRef) async {
    final res = await _get('/web/getservices', {'sRef': bouquetRef});
    return _parseServices(res.body);
  }

  List<ServiceRef> _parseServices(String xml) {
    return _blocks(xml, 'e2service').map((b) {
      return ServiceRef(
        reference: _tag(b, 'e2servicereference'),
        name: _tag(b, 'e2servicename'),
      );
    }).where((s) => s.name.isNotEmpty && !s.name.startsWith('---')).toList();
  }

  // --- Kanala geç ---
  Future<void> zap(String serviceRef) async {
    await _get('/web/zap', {'sRef': serviceRef});
  }

  // --- Ekran görüntüsü ---
  Future<Uint8List> screenshot({int width = 720}) async {
    final res = await _get('/grab', {'format': 'jpg', 'r': width.toString()});
    return res.bodyBytes;
  }
}

class DeviceInfo {
  final String name;
  final String model;
  final String imageVersion;
  final String webifVersion;

  DeviceInfo({
    required this.name,
    required this.model,
    this.imageVersion = '',
    this.webifVersion = '',
  });

  factory DeviceInfo.fromXml(String xml) {
    String pick(String t) =>
        RegExp('<$t>(.*?)</$t>').firstMatch(xml)?.group(1)?.trim() ?? '';
    final model = pick('e2model');
    final name = pick('e2name');
    return DeviceInfo(
      name: name.isNotEmpty ? name : 'Enigma2',
      model: model.isNotEmpty ? model : 'Uydu Alıcısı',
      imageVersion: pick('e2imageversion'),
      webifVersion: pick('e2webifversion'),
    );
  }
}

class VolumeInfo {
  final int level;
  final bool muted;
  VolumeInfo({required this.level, required this.muted});

  factory VolumeInfo.fromXml(String xml) {
    final lvl = RegExp(r'<e2current>(\d+)</e2current>').firstMatch(xml);
    final mute = RegExp(r'<e2ismuted>(.*?)</e2ismuted>').firstMatch(xml);
    return VolumeInfo(
      level: int.tryParse(lvl?.group(1) ?? '0') ?? 0,
      muted: (mute?.group(1)?.toLowerCase().trim() ?? '') == 'true',
    );
  }
}

class NowPlaying {
  final String channel;
  final String nowTitle;
  final String nextTitle;
  NowPlaying({
    required this.channel,
    required this.nowTitle,
    required this.nextTitle,
  });
}

class ServiceRef {
  final String reference;
  final String name;
  ServiceRef({required this.reference, required this.name});
}
