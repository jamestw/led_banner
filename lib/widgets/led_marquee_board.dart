import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/led_banner_config.dart';

class LedMarqueeBoard extends StatefulWidget {
  static bool isLightBackground(Color color) => color.computeLuminance() > 0.5;

  const LedMarqueeBoard({
    super.key,
    required this.config,
    this.isPaused = false,
    this.onTap,
    this.onDoubleTap,
    this.borderRadius = BorderRadius.zero,
  });

  final LedBannerConfig config;
  final bool isPaused;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final BorderRadius borderRadius;

  @override
  State<LedMarqueeBoard> createState() => _LedMarqueeBoardState();
}

class _LedMarqueeBoardState extends State<LedMarqueeBoard>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration? _lastTick;
  double _elapsedSeconds = 0.0;
  double _scrollOffsetUnits = 0.0;

  ui.Image? _cachedTile;
  LedDotShape? _cachedShape;
  int _cachedCellSize = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final prev = _lastTick;
    _lastTick = elapsed;
    if (prev == null) return;

    final dt = ((elapsed - prev).inMicroseconds / 1e6).clamp(0.0, 0.05);
    if (dt <= 0) return;

    _elapsedSeconds += dt;
    if (!widget.isPaused &&
        widget.config.direction != ScrollDirection.staticCenter &&
        widget.config.scrollSpeed > 0) {
      _scrollOffsetUnits += dt * (widget.config.scrollSpeed * 0.25);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant LedMarqueeBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.direction != widget.config.direction) {
      _scrollOffsetUnits = 0.0;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _cachedTile?.dispose();
    _cachedTile = null;
    super.dispose();
  }

  ui.Image? _ensureDotTile(LedDotShape shape, int cellSize) {
    if (!widget.config.ledMatrixEnabled) return null;
    if (_cachedTile != null &&
        _cachedShape == shape &&
        _cachedCellSize == cellSize) {
      return _cachedTile;
    }

    final previousTile = _cachedTile;
    final newTile = _buildDotTileImage(shape, cellSize);
    _cachedTile = newTile;
    _cachedShape = shape;
    _cachedCellSize = cellSize;

    if (previousTile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        previousTile.dispose();
      });
    }
    return newTile;
  }

  ui.Image _buildDotTileImage(LedDotShape shape, int cellSize) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = cellSize.toDouble();
    final center = Offset(size * 0.5, size * 0.5);
    final radius = size * 0.38;
    final paint = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;

    switch (shape) {
      case LedDotShape.circle:
        canvas.drawCircle(center, radius, paint);
      case LedDotShape.square:
        final side = radius * 1.85;
        final rect = Rect.fromCenter(center: center, width: side, height: side);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(size * 0.14)),
          paint,
        );
      case LedDotShape.diamond:
        final r = radius * 1.08;
        final path = Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r, center.dy)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r, center.dy)
          ..close();
        canvas.drawPath(path, paint);
      case LedDotShape.heart:
        final s = radius * 1.05;
        final path = Path()
          ..moveTo(center.dx, center.dy + s * 0.78)
          ..cubicTo(
            center.dx - s * 1.25,
            center.dy + s * 0.05,
            center.dx - s * 0.95,
            center.dy - s * 0.95,
            center.dx,
            center.dy - s * 0.3,
          )
          ..cubicTo(
            center.dx + s * 0.95,
            center.dy - s * 0.95,
            center.dx + s * 1.25,
            center.dy + s * 0.05,
            center.dx,
            center.dy + s * 0.78,
          )
          ..close();
        canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = picture.toImageSync(cellSize, cellSize);
    picture.dispose();
    return image;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardHeight = constraints.maxHeight.isFinite &&
                    constraints.maxHeight > 0
                ? constraints.maxHeight
                : 220.0;
            final divisor = 18.0 + widget.config.dotDensity * 30.0;
            final cellSize = (boardHeight / divisor).round().clamp(6, 28);
            final dotTile = _ensureDotTile(widget.config.dotShape, cellSize);

            return CustomPaint(
              painter: _LedBoardPainter(
                config: widget.config,
                elapsedSeconds: _elapsedSeconds,
                scrollOffsetUnits: _scrollOffsetUnits,
                dotTile: dotTile,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _Star {
  const _Star(this.nx, this.ny, this.size, this.phase, this.speed);
  final double nx;
  final double ny;
  final double size;
  final double phase;
  final double speed;
}

final List<_Star> _stars = List<_Star>.generate(44, (i) {
  final rng = math.Random(2026 + i * 37);
  return _Star(
    rng.nextDouble(),
    rng.nextDouble(),
    1.0 + rng.nextDouble() * 2.2,
    rng.nextDouble() * math.pi * 2,
    1.2 + rng.nextDouble() * 2.5,
  );
});

class _LedBoardPainter extends CustomPainter {
  _LedBoardPainter({
    required this.config,
    required this.elapsedSeconds,
    required this.scrollOffsetUnits,
    required this.dotTile,
  });

  final LedBannerConfig config;
  final double elapsedSeconds;
  final double scrollOffsetUnits;
  final ui.Image? dotTile;

  static final Float64List _identityMatrix = Matrix4.identity().storage;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.clipRect(bounds);

    _drawBackground(canvas, size, bounds);

    if (config.ledMatrixEnabled && config.showUnlitDots && dotTile != null) {
      final isLightBg = LedMarqueeBoard.isLightBackground(config.backgroundColor);
      final unlitShader = ui.ImageShader(
        dotTile!,
        TileMode.repeated,
        TileMode.repeated,
        _identityMatrix,
      );
      final unlitPaint = Paint()
        ..shader = unlitShader
        ..colorFilter = ColorFilter.mode(
          isLightBg
              ? Colors.black.withValues(alpha: 0.055)
              : Colors.white.withValues(alpha: 0.085),
          BlendMode.srcIn,
        );
      canvas.drawRect(bounds, unlitPaint);
    }

    canvas.save();
    if (config.mirrorMode) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    _drawMarqueeText(canvas, size, bounds);
    canvas.restore();

    if (config.showBorderFrame) {
      _drawChasingBorder(canvas, size);
    }

    if (config.brightness < 0.995) {
      final dimAlpha = (1.0 - config.brightness).clamp(0.0, 0.8);
      canvas.drawRect(
        bounds,
        Paint()..color = Colors.black.withValues(alpha: dimAlpha),
      );
    }

    canvas.restore();
  }

  void _drawBackground(Canvas canvas, Size size, Rect bounds) {
    switch (config.backgroundEffect) {
      case BackgroundEffect.solid:
        canvas.drawRect(bounds, Paint()..color = config.backgroundColor);
      case BackgroundEffect.pulse:
        final wave = (math.sin(elapsedSeconds * 2.4) + 1.0) * 0.5;
        final centerColor = Color.lerp(
          config.backgroundColor,
          config.backgroundAccentColor,
          0.25 + wave * 0.65,
        )!;
        final shader = ui.Gradient.radial(
          size.center(Offset.zero),
          size.longestSide * (0.45 + wave * 0.25),
          [centerColor, config.backgroundColor],
        );
        canvas.drawRect(bounds, Paint()..shader = shader);
      case BackgroundEffect.gradientWave:
        final t = (math.sin(elapsedSeconds * 1.4) + 1.0) * 0.5;
        final shader = ui.Gradient.linear(
          Offset(0, size.height * t),
          Offset(size.width, size.height * (1.0 - t)),
          [
            config.backgroundColor,
            config.backgroundAccentColor,
            config.backgroundColor,
          ],
          const [0.0, 0.5, 1.0],
        );
        canvas.drawRect(bounds, Paint()..shader = shader);
      case BackgroundEffect.starfield:
        canvas.drawRect(bounds, Paint()..color = config.backgroundColor);
        final isLightBg =
            LedMarqueeBoard.isLightBackground(config.backgroundColor);
        final starBase = isLightBg
            ? (config.backgroundAccentColor.computeLuminance() > 0.7
                ? const Color(0xFF334155)
                : config.backgroundAccentColor)
            : Color.lerp(Colors.white, config.backgroundAccentColor, 0.35)!;
        final starPaint = Paint();
        for (final star in _stars) {
          final alpha =
              ((math.sin(elapsedSeconds * star.speed + star.phase) + 1.0) *
                      0.5)
                  .clamp(0.12, 0.95);
          starPaint.color = starBase.withValues(alpha: alpha);
          canvas.drawCircle(
            Offset(star.nx * size.width, star.ny * size.height),
            star.size,
            starPaint,
          );
        }
    }
  }

  void _drawMarqueeText(Canvas canvas, Size size, Rect bounds) {
    final rawText = config.text;
    final isPlaceholder = rawText.trim().isEmpty;
    final displayText = isPlaceholder ? '請輸入跑馬燈文字' : rawText;

    final isHorizontal = config.direction == ScrollDirection.left ||
        config.direction == ScrollDirection.right;
    final normalizedText =
        isHorizontal ? displayText.replaceAll('\n', '  ') : displayText;

    final fontSize =
        (size.height * config.fontSizeFactor * 0.72).clamp(16.0, size.height * 0.92);

    final blinkAlpha = _computeBlinkAlpha();
    if (blinkAlpha <= 0.01) return;

    final fontFamily = _resolveFontFamily(config.fontStyle);
    final textShader = _buildTextShader(size, blinkAlpha, isPlaceholder);
    final solidColor = isPlaceholder
        ? config.textColor.withValues(alpha: 0.35 * blinkAlpha)
        : config.textColor.withValues(alpha: blinkAlpha);
    final isLightBg = LedMarqueeBoard.isLightBackground(config.backgroundColor);

    if (isLightBg) {
      List<Shadow>? textShadows;
      if (!isPlaceholder && config.glowIntensity > 0.02) {
        final isLightText = config.textColorMode == TextColorMode.solid &&
            config.textColor.computeLuminance() > 0.55;
        if (isLightText) {
          textShadows = [
            Shadow(
              color: Colors.black.withValues(
                alpha: ((0.45 + config.glowIntensity * 0.35) * blinkAlpha)
                    .clamp(0.0, 0.85),
              ),
              offset: const Offset(0, 1.5),
              blurRadius: 3.0 + config.glowIntensity * 4.0,
            ),
          ];
        } else {
          textShadows = [
            Shadow(
              color: Colors.black.withValues(
                alpha: ((0.12 + config.glowIntensity * 0.16) * blinkAlpha)
                    .clamp(0.0, 0.45),
              ),
              offset: Offset(0, math.max(1.0, fontSize * 0.022)),
              blurRadius: 2.0 + config.glowIntensity * 4.0,
            ),
          ];
        }
      }

      final mainPainter = _layoutTextPainter(
        normalizedText,
        fontSize,
        fontFamily,
        color: textShader == null ? solidColor : null,
        foreground: textShader != null ? (Paint()..shader = textShader) : null,
        shadows: textShadows,
        maxWidth: isHorizontal ? double.infinity : size.width * 0.9,
      );
      _paintScrolledCopies(canvas, size, mainPainter);

      if (config.ledMatrixEnabled && dotTile != null) {
        _drawLightSignboardGrid(canvas, size, dotTile!.width.toDouble());
      }
      return;
    }

    // Outer ambient bloom pass (unmasked) for realistic LED light bleed.
    if (config.glowIntensity > 0.02 && !isPlaceholder) {
      final bloomAlpha = (config.glowIntensity * 0.32 * blinkAlpha).clamp(0.0, 1.0);
      final bloomPaint = Paint()
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          6.0 + config.glowIntensity * 16.0,
        );
      if (textShader != null) {
        bloomPaint.shader = _buildTextShader(size, bloomAlpha, false);
      } else {
        bloomPaint.color = config.textColor.withValues(alpha: bloomAlpha);
      }

      final bloomPainter = _layoutTextPainter(
        normalizedText,
        fontSize,
        fontFamily,
        foreground: bloomPaint,
        maxWidth: isHorizontal ? double.infinity : size.width * 0.9,
      );
      _paintScrolledCopies(canvas, size, bloomPainter);
    }

    final mainPainter = _layoutTextPainter(
      normalizedText,
      fontSize,
      fontFamily,
      color: textShader == null ? solidColor : null,
      foreground: textShader != null ? (Paint()..shader = textShader) : null,
      maxWidth: isHorizontal ? double.infinity : size.width * 0.9,
    );

    if (config.ledMatrixEnabled && dotTile != null) {
      canvas.saveLayer(bounds, Paint());

      // Inner LED core glow inside the dot mask.
      if (config.glowIntensity > 0.05 && !isPlaceholder) {
        final innerGlowPaint = Paint()
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            2.0 + config.glowIntensity * 6.0,
          );
        if (textShader != null) {
          innerGlowPaint.shader = _buildTextShader(
            size,
            (0.6 * blinkAlpha).clamp(0.0, 1.0),
            false,
          );
        } else {
          innerGlowPaint.color =
              config.textColor.withValues(alpha: 0.6 * blinkAlpha);
        }
        final innerGlowPainter = _layoutTextPainter(
          normalizedText,
          fontSize,
          fontFamily,
          foreground: innerGlowPaint,
          maxWidth: isHorizontal ? double.infinity : size.width * 0.9,
        );
        _paintScrolledCopies(canvas, size, innerGlowPainter);
      }

      _paintScrolledCopies(canvas, size, mainPainter);

      final maskShader = ui.ImageShader(
        dotTile!,
        TileMode.repeated,
        TileMode.repeated,
        _identityMatrix,
      );
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = maskShader
          ..blendMode = BlendMode.dstIn,
      );
      canvas.restore();
    } else {
      _paintScrolledCopies(canvas, size, mainPainter);
    }
  }

  void _drawLightSignboardGrid(Canvas canvas, Size size, double step) {
    if (step <= 1.0) return;
    final gridPaint = Paint()
      ..color = config.backgroundColor.withValues(alpha: 0.22)
      ..strokeWidth = 1.0
      ..isAntiAlias = false;

    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  TextPainter _layoutTextPainter(
    String text,
    double fontSize,
    String? fontFamily, {
    Color? color,
    Paint? foreground,
    List<Shadow>? shadows,
    required double maxWidth,
  }) {
    assert(color == null || foreground == null);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: config.isBold ? FontWeight.w800 : FontWeight.w400,
      fontStyle: config.isItalic ? FontStyle.italic : FontStyle.normal,
      fontFamily: fontFamily,
      height: 1.12,
      letterSpacing: config.fontStyle == LedFontStyle.mono ? 2.0 : 0.8,
      color: foreground == null ? color : null,
      foreground: foreground,
      shadows: shadows,
    );

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    tp.layout(minWidth: 0, maxWidth: maxWidth);
    return tp;
  }

  void _paintScrolledCopies(Canvas canvas, Size size, TextPainter tp) {
    final textW = tp.width;
    final textH = tp.height;
    if (textW <= 0 || textH <= 0) return;

    final offsetPx = scrollOffsetUnits * size.height;

    switch (config.direction) {
      case ScrollDirection.staticCenter:
        tp.paint(
          canvas,
          Offset((size.width - textW) * 0.5, (size.height - textH) * 0.5),
        );
      case ScrollDirection.left:
      case ScrollDirection.right:
        final gap = size.width * 0.3 + tp.preferredLineHeight * 0.6;
        final cycle = textW + gap;
        final shift = offsetPx % cycle;
        final startX = config.direction == ScrollDirection.left
            ? (size.width * 0.14) - shift
            : (size.width * 0.14) + shift;
        final y = (size.height - textH) * 0.5;
        final minK = ((-textW - startX) / cycle).floor() - 1;
        final maxK = ((size.width + textW - startX) / cycle).ceil() + 1;
        for (int k = minK; k <= maxK; k++) {
          final x = startX + k * cycle;
          if (x + textW >= -4 && x <= size.width + 4) {
            tp.paint(canvas, Offset(x, y));
          }
        }
      case ScrollDirection.up:
      case ScrollDirection.down:
        final vGap = size.height * 0.35 + tp.preferredLineHeight * 0.5;
        final vCycle = textH + vGap;
        final shift = offsetPx % vCycle;
        final startY = config.direction == ScrollDirection.up
            ? (size.height - textH) * 0.5 - shift
            : (size.height - textH) * 0.5 + shift;
        final x = (size.width - textW) * 0.5;
        final minK = ((-textH - startY) / vCycle).floor() - 1;
        final maxK = ((size.height + textH - startY) / vCycle).ceil() + 1;
        for (int k = minK; k <= maxK; k++) {
          final y = startY + k * vCycle;
          if (y + textH >= -4 && y <= size.height + 4) {
            tp.paint(canvas, Offset(x, y));
          }
        }
    }
  }

  double _computeBlinkAlpha() {
    if (config.blinkFrequency <= 0.01) return 1.0;
    final wave =
        (math.sin(elapsedSeconds * config.blinkFrequency * math.pi * 2) + 1.0) *
            0.5;
    return (0.12 + 0.88 * wave).clamp(0.12, 1.0);
  }

  String? _resolveFontFamily(LedFontStyle style) {
    switch (style) {
      case LedFontStyle.sans:
        return null;
      case LedFontStyle.mono:
        return 'monospace';
      case LedFontStyle.serif:
        return 'serif';
      case LedFontStyle.rounded:
        return 'sans-serif-rounded';
    }
  }

  Shader? _buildTextShader(Size size, double alpha, bool isPlaceholder) {
    if (isPlaceholder) return null;
    switch (config.textColorMode) {
      case TextColorMode.solid:
        return null;
      case TextColorMode.rainbow:
        final shift = (elapsedSeconds * 140.0) % math.max(size.width, 200.0);
        final span = math.max(size.width * 0.9, 240.0);
        final colors = [
          const Color(0xFFFF2E93),
          const Color(0xFFFF8A00),
          const Color(0xFFFFE600),
          const Color(0xFF39FF14),
          const Color(0xFF00F5D4),
          const Color(0xFF38BDF8),
          const Color(0xFFA855F7),
          const Color(0xFFFF2E93),
        ].map((c) => c.withValues(alpha: alpha)).toList();
        return ui.Gradient.linear(
          Offset(shift, 0),
          Offset(shift + span, 0),
          colors,
          const [0.0, 0.14, 0.28, 0.43, 0.58, 0.72, 0.86, 1.0],
          TileMode.repeated,
        );
      case TextColorMode.gradient:
        return ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height * 0.4),
          [
            config.textColor.withValues(alpha: alpha),
            config.gradientEndColor.withValues(alpha: alpha),
          ],
        );
    }
  }

  void _drawChasingBorder(Canvas canvas, Size size) {
    final margin = math.max(6.0, size.shortestSide * 0.025);
    final bulbRadius = (size.shortestSide * 0.016).clamp(2.5, 6.0);
    final spacing = bulbRadius * 4.2;

    final left = margin;
    final top = margin;
    final right = size.width - margin;
    final bottom = size.height - margin;
    if (right <= left || bottom <= top) return;

    final points = <Offset>[];
    for (double x = left; x < right; x += spacing) {
      points.add(Offset(x, top));
    }
    for (double y = top; y < bottom; y += spacing) {
      points.add(Offset(right, y));
    }
    for (double x = right; x > left; x -= spacing) {
      points.add(Offset(x, bottom));
    }
    for (double y = bottom; y > top; y -= spacing) {
      points.add(Offset(left, y));
    }

    final phase = elapsedSeconds * 9.0;
    final paint = Paint();
    final glowPaint = Paint()
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, bulbRadius * 2.2);
    final isLightBg = LedMarqueeBoard.isLightBackground(config.backgroundColor);
    final needsBorderStroke =
        isLightBg && config.borderColor.computeLuminance() > 0.65;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < points.length; i++) {
      final wave = (math.sin((i - phase) * 1.1) + 1.0) * 0.5;
      final alpha = 0.2 + 0.8 * wave;
      final pt = points[i];
      final radius = bulbRadius * (0.75 + 0.3 * wave);

      if (wave > 0.55) {
        glowPaint.color = config.borderColor.withValues(alpha: alpha * 0.55);
        canvas.drawCircle(pt, bulbRadius * 1.4, glowPaint);
      }

      paint.color = config.borderColor.withValues(alpha: alpha);
      canvas.drawCircle(pt, radius, paint);

      if (needsBorderStroke) {
        strokePaint.color = Colors.black.withValues(alpha: 0.28 * alpha);
        canvas.drawCircle(pt, radius, strokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LedBoardPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.scrollOffsetUnits != scrollOffsetUnits ||
        oldDelegate.dotTile != dotTile;
  }
}
