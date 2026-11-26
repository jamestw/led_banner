import 'package:flutter/material.dart';

enum LedFontStyle {
  sans('無襯線'),
  mono('等寬像素'),
  serif('襯線體'),
  rounded('圓潤體');

  const LedFontStyle(this.label);
  final String label;
}

enum TextColorMode {
  solid('純色'),
  rainbow('彩虹'),
  gradient('漸層');

  const TextColorMode(this.label);
  final String label;
}

enum BackgroundEffect {
  solid('純色'),
  pulse('律動'),
  gradientWave('流光'),
  starfield('星光');

  const BackgroundEffect(this.label);
  final String label;
}

enum LedDotShape {
  circle('圓形'),
  square('方形'),
  diamond('菱形'),
  heart('愛心');

  const LedDotShape(this.label);
  final String label;
}

enum ScrollDirection {
  left('向左'),
  right('向右'),
  up('向上'),
  down('向下'),
  staticCenter('靜止');

  const ScrollDirection(this.label);
  final String label;
}

class LedBannerConfig {
  const LedBannerConfig({
    required this.text,
    required this.fontSizeFactor,
    required this.isBold,
    required this.isItalic,
    required this.fontStyle,
    required this.textColor,
    required this.textColorMode,
    required this.gradientEndColor,
    required this.backgroundColor,
    required this.backgroundEffect,
    required this.backgroundAccentColor,
    required this.ledMatrixEnabled,
    required this.dotShape,
    required this.dotDensity,
    required this.showUnlitDots,
    required this.glowIntensity,
    required this.direction,
    required this.scrollSpeed,
    required this.blinkFrequency,
    required this.mirrorMode,
    required this.showBorderFrame,
    required this.borderColor,
    required this.brightness,
  });

  factory LedBannerConfig.defaults() {
    return const LedBannerConfig(
      text: '✨ 全場一起嗨起來！ ✨',
      fontSizeFactor: 0.72,
      isBold: true,
      isItalic: false,
      fontStyle: LedFontStyle.sans,
      textColor: Color(0xFF00F5D4),
      textColorMode: TextColorMode.solid,
      gradientEndColor: Color(0xFFFF2E93),
      backgroundColor: Color(0xFF05070D),
      backgroundEffect: BackgroundEffect.solid,
      backgroundAccentColor: Color(0xFF28124D),
      ledMatrixEnabled: true,
      dotShape: LedDotShape.circle,
      dotDensity: 0.55,
      showUnlitDots: true,
      glowIntensity: 0.65,
      direction: ScrollDirection.left,
      scrollSpeed: 4.2,
      blinkFrequency: 0.0,
      mirrorMode: false,
      showBorderFrame: false,
      borderColor: Color(0xFFFF2E93),
      brightness: 1.0,
    );
  }

  final String text;
  final double fontSizeFactor;
  final bool isBold;
  final bool isItalic;
  final LedFontStyle fontStyle;
  final Color textColor;
  final TextColorMode textColorMode;
  final Color gradientEndColor;
  final Color backgroundColor;
  final BackgroundEffect backgroundEffect;
  final Color backgroundAccentColor;
  final bool ledMatrixEnabled;
  final LedDotShape dotShape;
  final double dotDensity;
  final bool showUnlitDots;
  final double glowIntensity;
  final ScrollDirection direction;
  final double scrollSpeed;
  final double blinkFrequency;
  final bool mirrorMode;
  final bool showBorderFrame;
  final Color borderColor;
  final double brightness;

  LedBannerConfig copyWith({
    String? text,
    double? fontSizeFactor,
    bool? isBold,
    bool? isItalic,
    LedFontStyle? fontStyle,
    Color? textColor,
    TextColorMode? textColorMode,
    Color? gradientEndColor,
    Color? backgroundColor,
    BackgroundEffect? backgroundEffect,
    Color? backgroundAccentColor,
    bool? ledMatrixEnabled,
    LedDotShape? dotShape,
    double? dotDensity,
    bool? showUnlitDots,
    double? glowIntensity,
    ScrollDirection? direction,
    double? scrollSpeed,
    double? blinkFrequency,
    bool? mirrorMode,
    bool? showBorderFrame,
    Color? borderColor,
    double? brightness,
  }) {
    return LedBannerConfig(
      text: text ?? this.text,
      fontSizeFactor: (fontSizeFactor ?? this.fontSizeFactor).clamp(0.35, 1.0),
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      fontStyle: fontStyle ?? this.fontStyle,
      textColor: textColor ?? this.textColor,
      textColorMode: textColorMode ?? this.textColorMode,
      gradientEndColor: gradientEndColor ?? this.gradientEndColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundEffect: backgroundEffect ?? this.backgroundEffect,
      backgroundAccentColor:
          backgroundAccentColor ?? this.backgroundAccentColor,
      ledMatrixEnabled: ledMatrixEnabled ?? this.ledMatrixEnabled,
      dotShape: dotShape ?? this.dotShape,
      dotDensity: (dotDensity ?? this.dotDensity).clamp(0.0, 1.0),
      showUnlitDots: showUnlitDots ?? this.showUnlitDots,
      glowIntensity: (glowIntensity ?? this.glowIntensity).clamp(0.0, 1.0),
      direction: direction ?? this.direction,
      scrollSpeed: (scrollSpeed ?? this.scrollSpeed).clamp(0.0, 10.0),
      blinkFrequency: (blinkFrequency ?? this.blinkFrequency).clamp(0.0, 6.0),
      mirrorMode: mirrorMode ?? this.mirrorMode,
      showBorderFrame: showBorderFrame ?? this.showBorderFrame,
      borderColor: borderColor ?? this.borderColor,
      brightness: (brightness ?? this.brightness).clamp(0.2, 1.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'fontSizeFactor': fontSizeFactor,
      'isBold': isBold,
      'isItalic': isItalic,
      'fontStyle': fontStyle.name,
      'textColor': textColor.toARGB32(),
      'textColorMode': textColorMode.name,
      'gradientEndColor': gradientEndColor.toARGB32(),
      'backgroundColor': backgroundColor.toARGB32(),
      'backgroundEffect': backgroundEffect.name,
      'backgroundAccentColor': backgroundAccentColor.toARGB32(),
      'ledMatrixEnabled': ledMatrixEnabled,
      'dotShape': dotShape.name,
      'dotDensity': dotDensity,
      'showUnlitDots': showUnlitDots,
      'glowIntensity': glowIntensity,
      'direction': direction.name,
      'scrollSpeed': scrollSpeed,
      'blinkFrequency': blinkFrequency,
      'mirrorMode': mirrorMode,
      'showBorderFrame': showBorderFrame,
      'borderColor': borderColor.toARGB32(),
      'brightness': brightness,
    };
  }

  factory LedBannerConfig.fromJson(Map<String, dynamic> json) {
    final fallback = LedBannerConfig.defaults();

    T parseEnum<T extends Enum>(List<T> values, dynamic raw, T def) {
      if (raw is String) {
        for (final value in values) {
          if (value.name == raw) return value;
        }
      }
      return def;
    }

    Color parseColor(dynamic raw, Color def) {
      if (raw is int) return Color(raw);
      return def;
    }

    double parseDouble(dynamic raw, double def, double min, double max) {
      if (raw is num) return raw.toDouble().clamp(min, max);
      return def;
    }

    return LedBannerConfig(
      text: json['text'] is String ? json['text'] as String : fallback.text,
      fontSizeFactor: parseDouble(
        json['fontSizeFactor'],
        fallback.fontSizeFactor,
        0.35,
        1.0,
      ),
      isBold: json['isBold'] is bool ? json['isBold'] as bool : fallback.isBold,
      isItalic: json['isItalic'] is bool
          ? json['isItalic'] as bool
          : fallback.isItalic,
      fontStyle: parseEnum(
        LedFontStyle.values,
        json['fontStyle'],
        fallback.fontStyle,
      ),
      textColor: parseColor(json['textColor'], fallback.textColor),
      textColorMode: parseEnum(
        TextColorMode.values,
        json['textColorMode'],
        fallback.textColorMode,
      ),
      gradientEndColor: parseColor(
        json['gradientEndColor'],
        fallback.gradientEndColor,
      ),
      backgroundColor: parseColor(
        json['backgroundColor'],
        fallback.backgroundColor,
      ),
      backgroundEffect: parseEnum(
        BackgroundEffect.values,
        json['backgroundEffect'],
        fallback.backgroundEffect,
      ),
      backgroundAccentColor: parseColor(
        json['backgroundAccentColor'],
        fallback.backgroundAccentColor,
      ),
      ledMatrixEnabled: json['ledMatrixEnabled'] is bool
          ? json['ledMatrixEnabled'] as bool
          : fallback.ledMatrixEnabled,
      dotShape: parseEnum(
        LedDotShape.values,
        json['dotShape'],
        fallback.dotShape,
      ),
      dotDensity: parseDouble(json['dotDensity'], fallback.dotDensity, 0.0, 1.0),
      showUnlitDots: json['showUnlitDots'] is bool
          ? json['showUnlitDots'] as bool
          : fallback.showUnlitDots,
      glowIntensity: parseDouble(
        json['glowIntensity'],
        fallback.glowIntensity,
        0.0,
        1.0,
      ),
      direction: parseEnum(
        ScrollDirection.values,
        json['direction'],
        fallback.direction,
      ),
      scrollSpeed: parseDouble(
        json['scrollSpeed'],
        fallback.scrollSpeed,
        0.0,
        10.0,
      ),
      blinkFrequency: parseDouble(
        json['blinkFrequency'],
        fallback.blinkFrequency,
        0.0,
        6.0,
      ),
      mirrorMode: json['mirrorMode'] is bool
          ? json['mirrorMode'] as bool
          : fallback.mirrorMode,
      showBorderFrame: json['showBorderFrame'] is bool
          ? json['showBorderFrame'] as bool
          : fallback.showBorderFrame,
      borderColor: parseColor(json['borderColor'], fallback.borderColor),
      brightness: parseDouble(
        json['brightness'],
        fallback.brightness,
        0.2,
        1.0,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LedBannerConfig &&
        other.text == text &&
        other.fontSizeFactor == fontSizeFactor &&
        other.isBold == isBold &&
        other.isItalic == isItalic &&
        other.fontStyle == fontStyle &&
        other.textColor == textColor &&
        other.textColorMode == textColorMode &&
        other.gradientEndColor == gradientEndColor &&
        other.backgroundColor == backgroundColor &&
        other.backgroundEffect == backgroundEffect &&
        other.backgroundAccentColor == backgroundAccentColor &&
        other.ledMatrixEnabled == ledMatrixEnabled &&
        other.dotShape == dotShape &&
        other.dotDensity == dotDensity &&
        other.showUnlitDots == showUnlitDots &&
        other.glowIntensity == glowIntensity &&
        other.direction == direction &&
        other.scrollSpeed == scrollSpeed &&
        other.blinkFrequency == blinkFrequency &&
        other.mirrorMode == mirrorMode &&
        other.showBorderFrame == showBorderFrame &&
        other.borderColor == borderColor &&
        other.brightness == brightness;
  }

  @override
  int get hashCode => Object.hashAll([
        text,
        fontSizeFactor,
        isBold,
        isItalic,
        fontStyle,
        textColor,
        textColorMode,
        gradientEndColor,
        backgroundColor,
        backgroundEffect,
        backgroundAccentColor,
        ledMatrixEnabled,
        dotShape,
        dotDensity,
        showUnlitDots,
        glowIntensity,
        direction,
        scrollSpeed,
        blinkFrequency,
        mirrorMode,
        showBorderFrame,
        borderColor,
        brightness,
      ]);
}

class BannerPreset {
  const BannerPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.config,
    required this.isBuiltIn,
    required this.savedAt,
  });

  final String id;
  final String name;
  final String category;
  final LedBannerConfig config;
  final bool isBuiltIn;
  final DateTime savedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'config': config.toJson(),
      'isBuiltIn': isBuiltIn,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory BannerPreset.fromJson(Map<String, dynamic> json) {
    final rawConfig = json['config'];
    return BannerPreset(
      id: json['id'] is String ? json['id'] as String : '',
      name: json['name'] is String ? json['name'] as String : '自訂樣式',
      category: json['category'] is String ? json['category'] as String : '收藏',
      config: rawConfig is Map<String, dynamic>
          ? LedBannerConfig.fromJson(rawConfig)
          : LedBannerConfig.defaults(),
      isBuiltIn: json['isBuiltIn'] is bool ? json['isBuiltIn'] as bool : false,
      savedAt: json['savedAt'] is String
          ? (DateTime.tryParse(json['savedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
