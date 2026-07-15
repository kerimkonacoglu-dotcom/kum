import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/device.dart';
import '../services/enigma_service.dart';
import '../services/rc_codes.dart';
import '../services/settings.dart';
import '../services/voice_commands.dart';
import '../services/wol.dart';
import 'channels_screen.dart';
import 'info_screen.dart';
import 'web_panel_screen.dart';
import 'voice_sheet.dart';

class RemoteScreen extends StatefulWidget {
  final Device device;
  const RemoteScreen({super.key, required this.device});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  late final EnigmaService service = EnigmaService(widget.device);
  int _tab = 0;
  NowPlaying? _now;
  DeviceInfo? _info;

  @override
  void initState() {
    super.initState();
    _loadInfo();
    _refreshNow();
  }

  Future<void> _loadInfo() async {
    try {
      final i = await service.info();
      if (mounted) setState(() => _info = i);
    } catch (_) {}
  }

  Future<void> _refreshNow() async {
    try {
      final n = await service.nowPlaying();
      if (mounted) setState(() => _now = n);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_now?.channel ?? widget.device.name,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis),
            if (_now?.nowTitle.isNotEmpty ?? false)
              Text(_now!.nowTitle,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.white60),
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sesli komut',
            onPressed: _voice,
            icon: const Icon(Icons.mic),
          ),
          IconButton(
            tooltip: 'Ekran görüntüsü',
            onPressed: _screenshot,
            icon: const Icon(Icons.photo_camera),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _refreshNow,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          WebPanelView(device: widget.device),
          _RemotePad(service: service, device: widget.device),
          ChannelsView(service: service, onZap: _refreshNow),
          InfoView(service: service, info: _info),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.language), label: 'Web Panel'),
          NavigationDestination(
              icon: Icon(Icons.settings_remote), label: 'Kumanda'),
          NavigationDestination(icon: Icon(Icons.list), label: 'Kanallar'),
          NavigationDestination(icon: Icon(Icons.info_outline), label: 'Bilgi'),
        ],
      ),
    );
  }

  Future<void> _voice() async {
    // Sesli komutta kanal adı eşleştirmek için ilk buketin kanallarını dene
    List<ServiceRef> chans = const [];
    try {
      final b = await service.bouquets();
      if (b.isNotEmpty) chans = await service.channels(b.first.reference);
    } catch (_) {}
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2126),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => VoiceSheet(
        commands: VoiceCommands(service, channels: chans),
      ),
    );
  }

  Future<void> _screenshot() async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ekran görüntüsü alınıyor...')));
    try {
      final Uint8List bytes = await service.screenshot();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                  child: InteractiveViewer(child: Image.memory(bytes))),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => _shareShot(bytes),
                      icon: const Icon(Icons.share),
                      label: const Text('Paylaş'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kapat'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görüntü alınamadı')));
    }
  }

  Future<void> _shareShot(Uint8List bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ekran.jpg');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {}
  }
}

/// Fiziksel kumanda düzeni.
class _RemotePad extends StatefulWidget {
  final EnigmaService service;
  final Device device;
  const _RemotePad({required this.service, required this.device});

  @override
  State<_RemotePad> createState() => _RemotePadState();
}

class _RemotePadState extends State<_RemotePad> {
  bool _touchpad = false;
  EnigmaService get service => widget.service;

  Future<void> _send(int code) async {
    if (Settings.haptics) HapticFeedback.lightImpact();
    try {
      await service.sendKey(code);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          _topRow(context),
          const SizedBox(height: 16),
          _colorRow(),
          const SizedBox(height: 16),
          _modeToggle(),
          const SizedBox(height: 16),
          _touchpad ? _touchPad() : _dPad(),
          const SizedBox(height: 20),
          _rockers(),
          const SizedBox(height: 20),
          _numberPad(),
          const SizedBox(height: 20),
          _mediaRow(),
        ],
      ),
    );
  }

  Widget _modeToggle() => SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
              value: false,
              icon: Icon(Icons.gamepad),
              label: Text('Tuşlar')),
          ButtonSegment(
              value: true,
              icon: Icon(Icons.touch_app),
              label: Text('Dokunmatik')),
        ],
        selected: {_touchpad},
        onSelectionChanged: (s) => setState(() => _touchpad = s.first),
      );

  /// Kaydırmalı dokunmatik kumanda alanı.
  Widget _touchPad() {
    return GestureDetector(
      onTap: () => _send(RcCodes.ok),
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity == null) return;
        _send(d.primaryVelocity! < 0 ? RcCodes.up : RcCodes.down);
      },
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity == null) return;
        _send(d.primaryVelocity! < 0 ? RcCodes.left : RcCodes.right);
      },
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: const Color(0xFF1C2126),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe, size: 40, color: Colors.white38),
              SizedBox(height: 8),
              Text('Kaydır: yön · Dokun: OK',
                  style: TextStyle(color: Colors.white38)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topRow(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circle(Icons.power_settings_new, () => _powerMenu(context),
              color: const Color(0xFFE53935)),
          _circle(Icons.volume_off, () => service.toggleMute()),
          _circle(Icons.tv, () => _send(RcCodes.tv)),
          _circle(Icons.radio, () => _send(RcCodes.radio)),
          _circle(Icons.subtitles, () => _send(RcCodes.subtitle)),
        ],
      );

  Future<void> _powerMenu(BuildContext context) async {
    final choice = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.device.mac != null)
            ListTile(
                leading: const Icon(Icons.power, color: Colors.greenAccent),
                title: const Text('Cihazı Aç (Wake-on-LAN)'),
                onTap: () => Navigator.pop(context, 100)),
          ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: const Text('Standby (aç/kapa)'),
              onTap: () => Navigator.pop(context, 0)),
          ListTile(
              leading: const Icon(Icons.power_settings_new),
              title: const Text('Tam kapat'),
              onTap: () => Navigator.pop(context, 1)),
          ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Yeniden başlat'),
              onTap: () => Navigator.pop(context, 2)),
          ListTile(
              leading: const Icon(Icons.wb_sunny),
              title: const Text('Uyandır'),
              onTap: () => Navigator.pop(context, 4)),
        ]),
      ),
    );
    if (choice == null) return;
    if (choice == 100) {
      final ok = await Wol.wake(widget.device.mac!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? 'Açma sinyali gönderildi'
                : 'WOL gönderilemedi (MAC adresini kontrol edin)')));
      }
      return;
    }
    try {
      await service.setPowerState(choice);
    } catch (_) {}
  }

  Widget _colorRow() {
    Widget bar(Color c, int code) => Expanded(
          child: GestureDetector(
            onTap: () => _send(code),
            child: Container(
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(6)),
            ),
          ),
        );
    return Row(children: [
      bar(const Color(0xFFE53935), RcCodes.red),
      bar(const Color(0xFF43A047), RcCodes.green),
      bar(const Color(0xFFFDD835), RcCodes.yellow),
      bar(const Color(0xFF1E88E5), RcCodes.blue),
    ]);
  }

  Widget _dPad() => Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: const BoxDecoration(
              color: Color(0xFF1C2126), shape: BoxShape.circle),
          child: Stack(alignment: Alignment.center, children: [
            Align(
                alignment: Alignment.topCenter,
                child: IconButton(
                    onPressed: () => _send(RcCodes.up),
                    icon: const Icon(Icons.keyboard_arrow_up, size: 34))),
            Align(
                alignment: Alignment.bottomCenter,
                child: IconButton(
                    onPressed: () => _send(RcCodes.down),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 34))),
            Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                    onPressed: () => _send(RcCodes.left),
                    icon: const Icon(Icons.keyboard_arrow_left, size: 34))),
            Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    onPressed: () => _send(RcCodes.right),
                    icon: const Icon(Icons.keyboard_arrow_right, size: 34))),
            GestureDetector(
              onTap: () => _send(RcCodes.ok),
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                    color: Color(0xFFE57A29), shape: BoxShape.circle),
                child: const Center(
                    child: Text('OK',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18))),
              ),
            ),
          ]),
        ),
      );

  Widget _rockers() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _rocker('SES', Icons.add, Icons.remove, () => service.volumeUp(),
              () => service.volumeDown()),
          Column(children: [
            _labelBtn(Icons.menu, 'Menü', () => _send(RcCodes.menu)),
            const SizedBox(height: 8),
            _labelBtn(Icons.info_outline, 'Info', () => _send(RcCodes.info)),
            const SizedBox(height: 8),
            _labelBtn(Icons.exit_to_app, 'Çıkış', () => _send(RcCodes.exit)),
          ]),
          _rocker('KANAL', Icons.keyboard_arrow_up, Icons.keyboard_arrow_down,
              () => _send(RcCodes.channelUp),
              () => _send(RcCodes.channelDown)),
        ],
      );

  Widget _rocker(String label, IconData top, IconData bottom,
          VoidCallback onTop, VoidCallback onBottom) =>
      Container(
        decoration: BoxDecoration(
            color: const Color(0xFF1C2126),
            borderRadius: BorderRadius.circular(30)),
        child: Column(children: [
          IconButton(onPressed: onTop, icon: Icon(top, size: 28)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.white54)),
          IconButton(onPressed: onBottom, icon: Icon(bottom, size: 28)),
        ]),
      );

  Widget _numberPad() {
    final codes = [
      RcCodes.key1, RcCodes.key2, RcCodes.key3,
      RcCodes.key4, RcCodes.key5, RcCodes.key6,
      RcCodes.key7, RcCodes.key8, RcCodes.key9,
    ];
    return Column(children: [
      for (var r = 0; r < 3; r++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var c = 0; c < 3; c++)
                _numButton('${r * 3 + c + 1}', codes[r * 3 + c]),
            ],
          ),
        ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _labelBtn(Icons.text_fields, 'Text', () => _send(RcCodes.text)),
          _numButton('0', RcCodes.key0),
          _labelBtn(Icons.audiotrack, 'Ses', () => _send(RcCodes.audio)),
        ],
      ),
    ]);
  }

  Widget _numButton(String label, int code) => GestureDetector(
        onTap: () => _send(code),
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
              color: Color(0xFF1C2126), shape: BoxShape.circle),
          child: Center(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w500))),
        ),
      );

  Widget _mediaRow() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circle(Icons.fast_rewind, () => _send(RcCodes.rewind)),
          _circle(Icons.play_arrow, () => _send(RcCodes.play)),
          _circle(Icons.pause, () => _send(RcCodes.pause)),
          _circle(Icons.stop, () => _send(RcCodes.stop)),
          _circle(Icons.fast_forward, () => _send(RcCodes.fastForward)),
          _circle(Icons.fiber_manual_record, () => _send(RcCodes.record),
              color: const Color(0xFFE53935)),
        ],
      );

  Widget _circle(IconData icon, VoidCallback onTap, {Color? color}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
              color: Color(0xFF1C2126), shape: BoxShape.circle),
          child: Icon(icon, color: color ?? Colors.white, size: 24),
        ),
      );

  Widget _labelBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                color: Color(0xFF1C2126), shape: BoxShape.circle),
            child: Icon(icon, size: 22),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.white54)),
        ]),
      );
}
