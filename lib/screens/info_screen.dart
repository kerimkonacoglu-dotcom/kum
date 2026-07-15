import 'package:flutter/material.dart';
import '../services/enigma_service.dart';

/// Cihaz bilgisi, ses seviyesi kaydırıcısı ve ekrana mesaj gönderme.
class InfoView extends StatefulWidget {
  final EnigmaService service;
  final DeviceInfo? info;
  const InfoView({super.key, required this.service, this.info});

  @override
  State<InfoView> createState() => _InfoViewState();
}

class _InfoViewState extends State<InfoView> {
  double _volume = 0;
  bool _muted = false;
  final _msg = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVolume();
  }

  Future<void> _loadVolume() async {
    try {
      final v = await widget.service.getVolume();
      setState(() {
        _volume = v.level.toDouble();
        _muted = v.muted;
      });
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    if (_msg.text.trim().isEmpty) return;
    try {
      await widget.service.sendMessage(_msg.text.trim());
      _msg.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesaj TV ekranına gönderildi')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _card(
          'Cihaz Bilgisi',
          widget.info == null
              ? const Text('Bu cihaz OpenWebif bilgisi vermiyor.',
                  style: TextStyle(color: Colors.white54))
              : Column(
                  children: [
                    _row('Model', widget.info!.model),
                    _row('Ad', widget.info!.name),
                    if (widget.info!.imageVersion.isNotEmpty)
                      _row('Yazılım', widget.info!.imageVersion),
                    if (widget.info!.webifVersion.isNotEmpty)
                      _row('OpenWebif', widget.info!.webifVersion),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        _card(
          'Ses Seviyesi',
          Column(
            children: [
              Row(
                children: [
                  Icon(_muted ? Icons.volume_off : Icons.volume_up,
                      color: _muted ? Colors.redAccent : null),
                  Expanded(
                    child: Slider(
                      value: _volume.clamp(0, 100),
                      max: 100,
                      divisions: 100,
                      label: _volume.round().toString(),
                      activeColor: const Color(0xFF2E7BE5),
                      onChanged: (v) => setState(() => _volume = v),
                      onChangeEnd: (v) =>
                          widget.service.setVolume(v.round()),
                    ),
                  ),
                  SizedBox(
                      width: 36,
                      child: Text('${_volume.round()}',
                          textAlign: TextAlign.end)),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  await widget.service.toggleMute();
                  _loadVolume();
                },
                icon: const Icon(Icons.volume_mute),
                label: const Text('Sessize al / aç'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _card(
          'TV Ekranına Mesaj',
          Column(
            children: [
              TextField(
                controller: _msg,
                decoration: const InputDecoration(
                  hintText: 'Ekranda gösterilecek metin',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sendMessage,
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7BE5)),
                  icon: const Icon(Icons.send),
                  label: const Text('Gönder'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2126),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white70)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.white54)),
            Flexible(
                child: Text(v,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      );
}
