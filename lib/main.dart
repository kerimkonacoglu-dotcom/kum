import 'package:flutter/material.dart';
import 'services/settings.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.load();
  runApp(const MediaTiviApp());
}

class MediaTiviApp extends StatelessWidget {
  const MediaTiviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Settings.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'media tivi Kumanda',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF2E7BE5),
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xFF2E7BE5),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121417),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF1C2126),
              indicatorColor: const Color(0xFF2E7BE5).withOpacity(0.25),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
