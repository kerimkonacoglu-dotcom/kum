import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/device_store.dart';
import 'device_form_screen.dart';
import 'remote_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = DeviceStore();
  List<Device> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final list = await _store.load();
    if (!mounted) return;
    setState(() {
      _devices = list;
      _loading = false;
    });
  }

  Future<void> _addOrEdit([Device? device]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DeviceFormScreen(device: device)),
    );
    if (result == true) _reload();
  }

  Future<void> _connect(Device device) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RemoteScreen(device: device),
      ),
    );
  }

  Future<void> _delete(Device device) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cihazı sil'),
        content: Text('"${device.name}" silinsin mi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil')),
        ],
      ),
    );
    if (ok == true) {
      await _store.delete(device.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _devices.isEmpty
                      ? _emptyState()
                      : _deviceList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        backgroundColor: const Color(0xFF2E7BE5),
        icon: const Icon(Icons.add),
        label: const Text('Cihaz Ekle'),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Ayarlar',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
          Image.asset('assets/logo.png', height: 100),
          const SizedBox(height: 8),
          const Text(
            'Uzaktan Kumanda',
            style: TextStyle(
                fontSize: 14,
                letterSpacing: 2,
                color: Colors.white54,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.settings_remote, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text('Henüz cihaz eklenmedi',
              style: TextStyle(color: Colors.white54)),
          SizedBox(height: 4),
          Text('Alttaki butondan alıcını ekle',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _deviceList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: _devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final d = _devices[i];
        return Card(
          color: const Color(0xFF1C2126),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF2E7BE5),
              child: Icon(Icons.satellite_alt, color: Colors.white),
            ),
            title: Text(d.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${d.host}:${d.port}',
                style: const TextStyle(color: Colors.white54)),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _addOrEdit(d);
                if (v == 'delete') _delete(d);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                PopupMenuItem(value: 'delete', child: Text('Sil')),
              ],
            ),
            onTap: () => _connect(d),
          ),
        );
      },
    );
  }
}
