import 'package:flutter/material.dart';
import '../services/settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Tema',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Koyu'),
            value: ThemeMode.dark,
            groupValue: Settings.themeMode.value,
            onChanged: _setTheme,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Açık'),
            value: ThemeMode.light,
            groupValue: Settings.themeMode.value,
            onChanged: _setTheme,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Sistem'),
            value: ThemeMode.system,
            groupValue: Settings.themeMode.value,
            onChanged: _setTheme,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Titreşim'),
            subtitle: const Text('Tuşlara basınca titreşim'),
            value: Settings.haptics,
            onChanged: (v) async {
              await Settings.setHaptics(v);
              setState(() {});
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('media tivi Kumanda'),
            subtitle: Text('Sürüm 1.0.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _setTheme(ThemeMode? m) async {
    if (m == null) return;
    await Settings.setTheme(m);
    setState(() {});
  }
}
