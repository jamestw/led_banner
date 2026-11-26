import 'package:flutter/material.dart';

import 'screens/editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LedBannerApp());
}

class LedBannerApp extends StatelessWidget {
  const LedBannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00F5D4);
    const secondary = Color(0xFFFF2E93);
    const scaffoldBg = Color(0xFF0B0D14);
    const surfaceBg = Color(0xFF151925);

    final colorScheme = const ColorScheme.dark(
      primary: primary,
      onPrimary: Color(0xFF031714),
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surfaceBg,
      onSurface: Colors.white,
    );

    return MaterialApp(
      title: 'LED 跑馬燈',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: scaffoldBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: scaffoldBg,
          elevation: 0,
          centerTitle: false,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: primary,
          thumbColor: primary,
          inactiveTrackColor: Colors.white12,
          overlayColor: primary.withValues(alpha: 0.16),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF1D2333),
          selectedColor: primary.withValues(alpha: 0.22),
          side: const BorderSide(color: Colors.white12),
          labelStyle: const TextStyle(fontSize: 13),
        ),
      ),
      home: const EditorScreen(),
    );
  }
}
