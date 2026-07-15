import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/device_store.dart';
import '../services/enigma_service.dart';

class DeviceFormScreen extends StatefulWidget {
  final Device? device;
  const DeviceFormScreen({super.key, this.device});

  @override
  State<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _user;
  late final TextEditingController _pass;
  late final TextEditingController _mac;
  final _store = DeviceStore();
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final d = widget.device;
    _name = TextEditingController(text: d?.name ?? '');
    _host = TextEditingController(text: d?.host ?? '');
    _port = TextEditingController(text: (d?.port ?? 80).toString());
    _user = TextEditingController(text: d?.username ?? '');
    _pass = TextEditingController(text: d?.password ?? '');
    _mac = TextEditingController(text: d?.mac ?? '');
  }

  Device _build() => Device(
        id: widget.device?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name.text.trim().isEmpty ? 'Alıcı' : _name.text.trim(),
        host: _host.text.trim(),
        port: int.tryParse(_port.text.trim()) ?? 80,
        username: _user.text.trim().isEmpty ? null : _user.text.trim(),
        password: _pass.text.isEmpty ? null : _pass.text,
        mac: _mac.text.trim().isEmpty ? null : _mac.text.trim(),
      );

  Future<void> _test() async {
    if (_host.text.trim().isEmpty) {
      setState(() => _testResult = 'Önce IP girin');
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final info = await EnigmaService(_build()).connect();
      setState(() => _testResult = 'Bağlandı: ${info.model}');
    } catch (_) {
      setState(() => _testResult = 'Bağlanılamadı');
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (_host.text.trim().isEmpty) {
      setState(() => _testResult = 'IP adresi zorunlu');
      return;
    }
    await _store.upsert(_build());
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.device == null ? 'Cihaz Ekle' : 'Cihazı Düzenle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field(_name, 'Cihaz adı', Icons.label, hint: 'ör. Salon Alıcısı'),
            const SizedBox(height: 12),
            _field(_host, 'IP adresi', Icons.lan,
                hint: '192.168.1.50', keyboard: TextInputType.url),
            const SizedBox(height: 12),
            _field(_port, 'Port', Icons.settings_ethernet,
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_user, 'Kullanıcı (ops.)', Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                  child: _field(_pass, 'Şifre (ops.)', Icons.lock,
                      obscure: true)),
            ]),
            const SizedBox(height: 12),
            _field(_mac, 'MAC adresi (ops. - WOL için)', Icons.settings_ethernet,
                hint: 'AA:BB:CC:DD:EE:FF'),
            if (_testResult != null) ...[
              const SizedBox(height: 16),
              Text(_testResult!,
                  style: TextStyle(
                      color: _testResult!.startsWith('Bağlandı')
                          ? Colors.greenAccent
                          : Colors.orangeAccent)),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _testing ? null : _test,
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.wifi_tethering),
              label: const Text('Bağlantıyı Test Et'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7BE5),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.save),
              label: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {String? hint,
      bool obscure = false,
      TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
