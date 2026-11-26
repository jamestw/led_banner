import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/led_banner_config.dart';
import '../widgets/led_marquee_board.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({
    super.key,
    required this.initialConfig,
  });

  final LedBannerConfig initialConfig;

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  late LedBannerConfig _config;
  bool _isPaused = false;
  bool _showHud = false;
  bool _isTouchLocked = false;
  bool _isLandscape = true;
  bool _orientationInitialized = false;

  String? _statusBadge;
  Timer? _hudTimer;
  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    try {
      WakelockPlus.enable();
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orientationInitialized) return;
    _orientationInitialized = true;

    final size = MediaQuery.sizeOf(context);
    final isPhone = size.shortestSide < 600;
    if (isPhone) {
      _isLandscape = true;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      _isLandscape = size.width >= size.height;
    }
  }

  @override
  void dispose() {
    _hudTimer?.cancel();
    _badgeTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const []);
    try {
      WakelockPlus.disable();
    } catch (_) {}
    super.dispose();
  }

  void _toggleHud() {
    if (_isTouchLocked) {
      _flashBadge('已鎖定，請長按右下角解鎖');
      return;
    }
    setState(() => _showHud = !_showHud);
    _scheduleHudHide();
  }

  void _scheduleHudHide() {
    _hudTimer?.cancel();
    if (_showHud && !_isTouchLocked) {
      _hudTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _showHud) {
          setState(() => _showHud = false);
        }
      });
    }
  }

  void _flashBadge(String message) {
    _badgeTimer?.cancel();
    setState(() => _statusBadge = message);
    _badgeTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _statusBadge = null);
      }
    });
  }

  void _togglePause() {
    if (_isTouchLocked) return;
    setState(() => _isPaused = !_isPaused);
    _flashBadge(_isPaused ? '已暫停捲動' : '繼續播放');
    _scheduleHudHide();
  }

  void _toggleOrientation() {
    setState(() => _isLandscape = !_isLandscape);
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _flashBadge('橫向全螢幕');
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      _flashBadge('直向全螢幕');
    }
    _scheduleHudHide();
  }

  void _lockTouch() {
    _hudTimer?.cancel();
    setState(() {
      _isTouchLocked = true;
      _showHud = false;
    });
    _flashBadge('已啟用防誤觸鎖定');
  }

  void _unlockTouch() {
    setState(() {
      _isTouchLocked = false;
      _showHud = true;
    });
    _flashBadge('已解除螢幕鎖定');
    _scheduleHudHide();
  }

  Future<void> _showQuickEditTextDialog() async {
    _hudTimer?.cancel();
    final controller = TextEditingController(text: _config.text);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151925),
        title: const Text('快速修改文字'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: '輸入跑馬燈內容...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('確定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (updated != null && mounted) {
      setState(() {
        _config = _config.copyWith(text: updated);
      });
    }
    _scheduleHudHide();
  }

  void _handleVerticalDrag(DragUpdateDetails details, double screenWidth) {
    if (_isTouchLocked) return;
    final delta = -details.delta.dy;
    final isLeftHalf = details.globalPosition.dx < screenWidth * 0.5;
    if (isLeftHalf) {
      final nextBrightness =
          (_config.brightness + delta * 0.003).clamp(0.2, 1.0);
      setState(() {
        _config = _config.copyWith(brightness: nextBrightness);
      });
      _flashBadge('亮度 ${(nextBrightness * 100).round()}%');
    } else {
      final nextSpeed = (_config.scrollSpeed + delta * 0.03).clamp(0.0, 10.0);
      setState(() {
        _config = _config.copyWith(scrollSpeed: nextSpeed);
      });
      _flashBadge('速度 ${nextSpeed.toStringAsFixed(1)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_config);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (d) => _handleVerticalDrag(d, screenWidth),
          child: Stack(
            fit: StackFit.expand,
            children: [
              LedMarqueeBoard(
                config: _config,
                isPaused: _isPaused,
                onTap: _toggleHud,
                onDoubleTap: _togglePause,
              ),

              if (_statusBadge != null)
                IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        _statusBadge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

              if (_isTouchLocked)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: GestureDetector(
                      onLongPress: _unlockTouch,
                      onTap: () => _flashBadge('長按此鎖頭圖示解鎖'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, color: Colors.white70, size: 18),
                            SizedBox(width: 6),
                            Text(
                              '長按解鎖',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              if (_showHud && !_isTouchLocked) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _HudPillButton(
                            icon: Icons.arrow_back_rounded,
                            label: '返回編輯',
                            onTap: () => Navigator.of(context).pop(_config),
                          ),
                          const Spacer(),
                          _HudPillButton(
                            icon: Icons.edit_rounded,
                            label: '改字',
                            onTap: _showQuickEditTextDialog,
                          ),
                          const SizedBox(width: 10),
                          _HudPillButton(
                            icon: Icons.lock_outline_rounded,
                            label: '鎖定螢幕',
                            onTap: _lockTouch,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _HudIconAction(
                                    icon: _isPaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.pause_rounded,
                                    label: _isPaused ? '播放' : '暫停',
                                    active: _isPaused,
                                    onTap: _togglePause,
                                  ),
                                  _HudIconAction(
                                    icon: Icons.flip_rounded,
                                    label: '鏡像',
                                    active: _config.mirrorMode,
                                    onTap: () {
                                      setState(() {
                                        _config = _config.copyWith(
                                          mirrorMode: !_config.mirrorMode,
                                        );
                                      });
                                      _scheduleHudHide();
                                    },
                                  ),
                                  _HudIconAction(
                                    icon: Icons.flash_on_rounded,
                                    label: '閃爍',
                                    active: _config.blinkFrequency > 0,
                                    onTap: () {
                                      setState(() {
                                        _config = _config.copyWith(
                                          blinkFrequency:
                                              _config.blinkFrequency > 0
                                                  ? 0.0
                                                  : 2.0,
                                        );
                                      });
                                      _scheduleHudHide();
                                    },
                                  ),
                                  _HudIconAction(
                                    icon: Icons.screen_rotation_rounded,
                                    label: _isLandscape ? '切直向' : '切橫向',
                                    active: false,
                                    onTap: _toggleOrientation,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.58),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '提示：左側上下滑調亮度・右側上下滑調速度・雙擊暫停',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HudPillButton extends StatelessWidget {
  const _HudPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudIconAction extends StatelessWidget {
  const _HudIconAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF00F5D4) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
