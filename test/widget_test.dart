import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:led_banner/data/presets.dart';
import 'package:led_banner/main.dart';
import 'package:led_banner/models/led_banner_config.dart';
import 'package:led_banner/screens/playback_screen.dart';
import 'package:led_banner/widgets/led_marquee_board.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpFrames(WidgetTester tester, {int count = 10}) async {
    for (int i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  test('LedBannerConfig and BannerPreset JSON round-trip', () {
    const original = LedBannerConfig(
      text: '測試應援 🎤✨',
      fontSizeFactor: 0.85,
      isBold: false,
      isItalic: true,
      fontStyle: LedFontStyle.mono,
      textColor: Color(0xFFFF2E93),
      textColorMode: TextColorMode.gradient,
      gradientEndColor: Color(0xFF38BDF8),
      backgroundColor: Color(0xFF0D0B21),
      backgroundEffect: BackgroundEffect.starfield,
      backgroundAccentColor: Color(0xFFA855F7),
      ledMatrixEnabled: true,
      dotShape: LedDotShape.heart,
      dotDensity: 0.72,
      showUnlitDots: false,
      glowIntensity: 0.9,
      direction: ScrollDirection.up,
      scrollSpeed: 7.5,
      blinkFrequency: 2.5,
      mirrorMode: true,
      showBorderFrame: true,
      borderColor: Color(0xFFFFD60A),
      brightness: 0.75,
    );

    final decoded = LedBannerConfig.fromJson(original.toJson());
    expect(decoded, equals(original));

    final preset = BannerPreset(
      id: 'p1',
      name: '自訂',
      category: '收藏',
      config: original,
      isBuiltIn: false,
      savedAt: DateTime(2026, 5, 1, 12, 30),
    );
    final decodedPreset = BannerPreset.fromJson(preset.toJson());
    expect(decodedPreset.id, 'p1');
    expect(decodedPreset.name, '自訂');
    expect(decodedPreset.config, equals(original));
  });

  testWidgets('EditorScreen renders on phone size and switches tabs & presets',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LedBannerApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('LED 跑馬燈'), findsOneWidget);
    expect(find.text('文字'), findsOneWidget);
    expect(find.text('燈效'), findsOneWidget);
    expect(find.text('動態'), findsOneWidget);
    expect(find.text('模板'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '台北小巨蛋見！');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('台北小巨蛋見！'), findsOneWidget);

    await tester.tap(find.text('燈效'));
    await pumpFrames(tester);
    expect(find.text('LED 點陣顆粒效果'), findsOneWidget);

    await tester.tap(find.text('動態'));
    await pumpFrames(tester);
    expect(find.text('滾動方向'), findsOneWidget);

    await tester.tap(find.text('模板'));
    await pumpFrames(tester);
    expect(find.text('機場接機'), findsOneWidget);

    await tester.tap(find.text('機場接機'));
    await pumpFrames(tester, count: 4);
    expect(find.textContaining('歡迎來到台灣'), findsWidgets);
  });

  testWidgets('EditorScreen renders tablet studio layout without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LedBannerApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('全螢幕播放'), findsOneWidget);
    expect(find.text('鏡像翻轉'), findsOneWidget);
    expect(find.text('跑馬燈邊框'), findsOneWidget);
  });

  testWidgets('PlaybackScreen HUD, pause, and touch-lock flow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: PlaybackScreen(initialConfig: LedBannerConfig.defaults()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Tap to show HUD (wait past kDoubleTapTimeout ~300ms)
    await tester.tap(find.byType(PlaybackScreen));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('返回編輯'), findsOneWidget);
    expect(find.text('鎖定螢幕'), findsOneWidget);

    // Pause playback
    await tester.tap(find.text('暫停'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('播放'), findsOneWidget);

    // Enable touch lock
    await tester.tap(find.text('鎖定螢幕'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('長按解鎖'), findsOneWidget);
    expect(find.text('返回編輯'), findsNothing);

    // Long press to unlock
    await tester.longPress(find.text('長按解鎖'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('返回編輯'), findsOneWidget);

    // Wait out badge/HUD timers cleanly before test disposal
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
      'Palettes include bright backgrounds & dark text and bright preset works',
      (WidgetTester tester) async {
    expect(bgColorPalette.any((c) => c.computeLuminance() < 0.2), isTrue);
    expect(bgColorPalette.any((c) => c.computeLuminance() > 0.65), isTrue);
    expect(neonColorPalette.any((c) => c.computeLuminance() < 0.2), isTrue);

    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const LedBannerApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('模板'));
    await pumpFrames(tester);

    await tester.scrollUntilVisible(
      find.text('明亮公告'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('明亮公告'));
    await pumpFrames(tester, count: 4);

    expect(find.textContaining('請往這邊排隊'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Bright background clarity optimization renders black text and emoji cleanly',
      (WidgetTester tester) async {
    expect(LedMarqueeBoard.isLightBackground(const Color(0xFFFFFFFF)), isTrue);
    expect(LedMarqueeBoard.isLightBackground(const Color(0xFFFFF176)), isTrue);
    expect(LedMarqueeBoard.isLightBackground(const Color(0xFFFFD6E7)), isTrue);
    expect(LedMarqueeBoard.isLightBackground(const Color(0xFF05070D)), isFalse);
    expect(LedMarqueeBoard.isLightBackground(const Color(0xFF0D0B21)), isFalse);

    const config = LedBannerConfig(
      text: '📢 測試清晰度 ✨',
      fontSizeFactor: 0.72,
      isBold: true,
      isItalic: false,
      fontStyle: LedFontStyle.sans,
      textColor: Color(0xFF111827),
      textColorMode: TextColorMode.solid,
      gradientEndColor: Color(0xFFFF4D4D),
      backgroundColor: Color(0xFFFFFFFF),
      backgroundEffect: BackgroundEffect.starfield,
      backgroundAccentColor: Color(0xFFFFF176),
      ledMatrixEnabled: true,
      dotShape: LedDotShape.circle,
      dotDensity: 0.65,
      showUnlitDots: true,
      glowIntensity: 0.8,
      direction: ScrollDirection.left,
      scrollSpeed: 3.6,
      blinkFrequency: 0.0,
      mirrorMode: false,
      showBorderFrame: true,
      borderColor: Color(0xFFFFF176),
      brightness: 1.0,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 300,
            child: LedMarqueeBoard(config: config),
          ),
        ),
      ),
    );
    await pumpFrames(tester, count: 5);
    expect(tester.takeException(), isNull);
  });
}
