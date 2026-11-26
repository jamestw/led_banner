import 'dart:async';

import 'package:flutter/material.dart';

import '../data/presets.dart';
import '../models/led_banner_config.dart';
import '../services/banner_storage.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/led_marquee_board.dart';
import 'playback_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    this.storage,
  });

  final BannerStorage? storage;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  late final BannerStorage _storage;
  late final TabController _tabController;
  late final TextEditingController _textController;

  LedBannerConfig _config = LedBannerConfig.defaults();
  List<BannerPreset> _favorites = [];
  List<BannerPreset> _history = [];
  bool _previewPaused = false;
  bool _userModifiedBeforeLoad = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? BannerStorage();
    _tabController = TabController(length: 4, vsync: this);
    _textController = TextEditingController(text: _config.text);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final loadedConfig = await _storage.loadLastConfig();
    final loadedFavorites = await _storage.loadFavorites();
    final loadedHistory = await _storage.loadHistory();
    if (!mounted) return;
    setState(() {
      if (!_userModifiedBeforeLoad) {
        _config = loadedConfig;
        _textController.text = loadedConfig.text;
      }
      _favorites = loadedFavorites;
      _history = loadedHistory;
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _updateConfig(LedBannerConfig next, {bool syncTextField = false}) {
    _userModifiedBeforeLoad = true;
    setState(() {
      _config = next;
      if (syncTextField && _textController.text != next.text) {
        _textController.value = TextEditingValue(
          text: next.text,
          selection: TextSelection.collapsed(offset: next.text.length),
        );
      }
    });
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 350), () {
      _storage.saveLastConfig(_config);
    });
  }

  void _insertEmoji(String emoji) {
    final text = _textController.text;
    final selection = _textController.selection;
    final start =
        selection.isValid && selection.start >= 0 ? selection.start : text.length;
    final end =
        selection.isValid && selection.end >= 0 ? selection.end : text.length;
    final updated = text.replaceRange(start, end, emoji);
    _textController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    _updateConfig(_config.copyWith(text: updated));
  }

  Future<void> _openFullScreen() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final updatedHistory = await _storage.recordHistory(_config);
    if (mounted) {
      setState(() => _history = updatedHistory);
    }
    if (!mounted) return;
    final returned = await Navigator.of(context).push<LedBannerConfig>(
      MaterialPageRoute(
        builder: (_) => PlaybackScreen(initialConfig: _config),
      ),
    );
    if (returned != null && mounted) {
      _updateConfig(returned, syncTextField: true);
    }
  }

  Future<void> _saveFavoriteDialog() async {
    final defaultName = _config.text.trim().isEmpty
        ? '自訂樣式'
        : (_config.text.trim().length > 14
            ? _config.text.trim().substring(0, 14)
            : _config.text.trim());
    final controller = TextEditingController(text: defaultName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151925),
        title: const Text('儲存到我的收藏'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '樣式名稱',
            hintText: '例如：偶像演唱會應援',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;

    final preset = BannerPreset(
      id: 'fav_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      category: '收藏',
      config: _config,
      isBuiltIn: false,
      savedAt: DateTime.now(),
    );
    final updated = [preset, ..._favorites];
    setState(() => _favorites = updated);
    await _storage.saveFavorites(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已收藏「$name」')),
    );
  }

  Future<void> _deleteFavorite(String id) async {
    final updated = _favorites.where((e) => e.id != id).toList();
    setState(() => _favorites = updated);
    await _storage.saveFavorites(updated);
  }

  void _applyPreset(BannerPreset preset) {
    _updateConfig(preset.config, syncTextField: true);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已套用「${preset.name}」'),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _pickCustomColor({
    required String title,
    required Color current,
    required ValueChanged<Color> onSelected,
    List<Color>? swatches,
  }) async {
    final chosen = await showColorPickerDialog(
      context,
      initialColor: current,
      title: title,
      swatches: swatches,
    );
    if (chosen != null) {
      onSelected(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideAppBar = MediaQuery.sizeOf(context).width >= 520;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_circle, color: Color(0xFF00F5D4)),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'LED 跑馬燈',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: '重設預設值',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                _updateConfig(
                  LedBannerConfig.defaults(),
                  syncTextField: true,
                );
              },
            ),
            IconButton(
              tooltip: '儲存樣式到收藏',
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: _saveFavoriteDialog,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _openFullScreen,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(isWideAppBar ? '全螢幕播放' : '播放'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTabletLayout = constraints.maxWidth >= 840;
              if (isTabletLayout) {
                return _buildTabletLayout();
              }
              return _buildPhoneLayout();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildPreviewCard(isExpanded: true),
                ),
                const SizedBox(height: 12),
                _buildQuickActionStrip(),
                const SizedBox(height: 12),
                _buildTextInputCard(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 9,
            child: _buildInspectorPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 152,
            child: _buildPreviewCard(isExpanded: false),
          ),
          const SizedBox(height: 10),
          _buildTextInputCard(),
          const SizedBox(height: 10),
          Expanded(
            child: _buildInspectorPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard({required bool isExpanded}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _config.textColor.withValues(alpha: 0.14),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          LedMarqueeBoard(
            config: _config,
            isPaused: _previewPaused,
            borderRadius: BorderRadius.circular(17),
            onTap: _openFullScreen,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniPreviewButton(
                  icon: _previewPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  tooltip: _previewPaused ? '繼續預覽' : '暫停預覽',
                  onTap: () => setState(() => _previewPaused = !_previewPaused),
                ),
                const SizedBox(width: 6),
                _MiniPreviewButton(
                  icon: Icons.fullscreen_rounded,
                  tooltip: '全螢幕',
                  onTap: _openFullScreen,
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            bottom: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpanded ? '點擊看板進入全螢幕模式' : '點擊預覽全螢幕',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionStrip() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          selected: _previewPaused,
          avatar: Icon(
            _previewPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            size: 18,
          ),
          label: Text(_previewPaused ? '繼續預覽' : '暫停預覽'),
          onSelected: (v) => setState(() => _previewPaused = v),
        ),
        FilterChip(
          selected: _config.mirrorMode,
          avatar: const Icon(Icons.flip_rounded, size: 18),
          label: const Text('鏡像翻轉'),
          onSelected: (v) => _updateConfig(_config.copyWith(mirrorMode: v)),
        ),
        FilterChip(
          selected: _config.showBorderFrame,
          avatar: const Icon(Icons.border_outer_rounded, size: 18),
          label: const Text('跑馬燈邊框'),
          onSelected: (v) =>
              _updateConfig(_config.copyWith(showBorderFrame: v)),
        ),
        FilterChip(
          selected: _config.blinkFrequency > 0,
          avatar: const Icon(Icons.flash_on_rounded, size: 18),
          label: const Text('閃爍特效'),
          onSelected: (v) => _updateConfig(
            _config.copyWith(blinkFrequency: v ? 2.0 : 0.0),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151925),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            onChanged: (value) => _updateConfig(_config.copyWith(text: value)),
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              hintText: '輸入想顯示的文字、應援口號或 Emoji...',
              isDense: true,
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.text_fields_rounded, size: 20),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      tooltip: '清除文字',
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _textController.clear();
                        _updateConfig(_config.copyWith(text: ''));
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: quickEmojis.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final emoji = quickEmojis[index];
                return ActionChip(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  label: Text(emoji, style: const TextStyle(fontSize: 15)),
                  onPressed: () => _insertEmoji(emoji),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorPanel() {
    return Material(
      color: const Color(0xFF151925),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            dividerColor: Colors.white10,
            tabs: const [
              Tab(icon: Icon(Icons.title_rounded, size: 18), text: '文字'),
              Tab(icon: Icon(Icons.blur_on_rounded, size: 18), text: '燈效'),
              Tab(icon: Icon(Icons.animation_rounded, size: 18), text: '動態'),
              Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: '模板'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextTab(),
                _buildLedEffectsTab(),
                _buildMotionAndBgTab(),
                _buildPresetsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _SectionTitle('字型風格'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: LedFontStyle.values.map((style) {
            return ChoiceChip(
              label: Text(style.label),
              selected: _config.fontStyle == style,
              onSelected: (_) =>
                  _updateConfig(_config.copyWith(fontStyle: style)),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _SliderRow(
          label: '字體大小',
          valueText: '${(_config.fontSizeFactor * 100).round()}%',
          value: _config.fontSizeFactor,
          min: 0.35,
          max: 1.0,
          onChanged: (v) => _updateConfig(_config.copyWith(fontSizeFactor: v)),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('粗體'),
              selected: _config.isBold,
              onSelected: (v) => _updateConfig(_config.copyWith(isBold: v)),
            ),
            FilterChip(
              label: const Text('斜體'),
              selected: _config.isItalic,
              onSelected: (v) => _updateConfig(_config.copyWith(isItalic: v)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle('文字色彩模式'),
        Wrap(
          spacing: 8,
          children: TextColorMode.values.map((mode) {
            return ChoiceChip(
              label: Text(mode.label),
              selected: _config.textColorMode == mode,
              onSelected: (_) =>
                  _updateConfig(_config.copyWith(textColorMode: mode)),
            );
          }).toList(),
        ),
        if (_config.textColorMode != TextColorMode.rainbow) ...[
          const SizedBox(height: 14),
          _ColorSwatchRow(
            title: _config.textColorMode == TextColorMode.gradient
                ? '漸層起點色'
                : '文字顏色',
            selectedColor: _config.textColor,
            palette: neonColorPalette,
            onSelect: (c) => _updateConfig(_config.copyWith(textColor: c)),
            onCustomTap: () => _pickCustomColor(
              title: '選擇文字顏色',
              current: _config.textColor,
              onSelected: (c) => _updateConfig(_config.copyWith(textColor: c)),
            ),
          ),
        ],
        if (_config.textColorMode == TextColorMode.gradient) ...[
          const SizedBox(height: 14),
          _ColorSwatchRow(
            title: '漸層終點色',
            selectedColor: _config.gradientEndColor,
            palette: neonColorPalette,
            onSelect: (c) =>
                _updateConfig(_config.copyWith(gradientEndColor: c)),
            onCustomTap: () => _pickCustomColor(
              title: '選擇漸層終點色',
              current: _config.gradientEndColor,
              onSelected: (c) =>
                  _updateConfig(_config.copyWith(gradientEndColor: c)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLedEffectsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('LED 點陣顆粒效果'),
          subtitle: const Text('模擬真實 LED 燈珠排列'),
          value: _config.ledMatrixEnabled,
          onChanged: (v) =>
              _updateConfig(_config.copyWith(ledMatrixEnabled: v)),
        ),
        if (_config.ledMatrixEnabled) ...[
          _SectionTitle('燈珠形狀'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LedDotShape.values.map((shape) {
              return ChoiceChip(
                label: Text(shape.label),
                selected: _config.dotShape == shape,
                onSelected: (_) =>
                    _updateConfig(_config.copyWith(dotShape: shape)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _SliderRow(
            label: '點陣密度',
            valueText: '${(_config.dotDensity * 100).round()}%',
            value: _config.dotDensity,
            min: 0.0,
            max: 1.0,
            onChanged: (v) => _updateConfig(_config.copyWith(dotDensity: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('顯示未點亮底格'),
            value: _config.showUnlitDots,
            onChanged: (v) =>
                _updateConfig(_config.copyWith(showUnlitDots: v)),
          ),
        ],
        const Divider(height: 24, color: Colors.white10),
        _SliderRow(
          label: '霓虹發光',
          valueText: '${(_config.glowIntensity * 100).round()}%',
          value: _config.glowIntensity,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => _updateConfig(_config.copyWith(glowIntensity: v)),
        ),
        _SliderRow(
          label: '閃爍頻率',
          valueText: _config.blinkFrequency <= 0.05
              ? '關閉'
              : '${_config.blinkFrequency.toStringAsFixed(1)} Hz',
          value: _config.blinkFrequency,
          min: 0.0,
          max: 6.0,
          onChanged: (v) =>
              _updateConfig(_config.copyWith(blinkFrequency: v)),
        ),
        const Divider(height: 24, color: Colors.white10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('跑馬燈外框燈泡'),
          value: _config.showBorderFrame,
          onChanged: (v) =>
              _updateConfig(_config.copyWith(showBorderFrame: v)),
        ),
        if (_config.showBorderFrame)
          _ColorSwatchRow(
            title: '邊框燈色',
            selectedColor: _config.borderColor,
            palette: neonColorPalette,
            onSelect: (c) => _updateConfig(_config.copyWith(borderColor: c)),
            onCustomTap: () => _pickCustomColor(
              title: '選擇邊框燈色',
              current: _config.borderColor,
              onSelected: (c) =>
                  _updateConfig(_config.copyWith(borderColor: c)),
            ),
          ),
      ],
    );
  }

  Widget _buildMotionAndBgTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _SectionTitle('滾動方向'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ScrollDirection.values.map((dir) {
            return ChoiceChip(
              label: Text(dir.label),
              selected: _config.direction == dir,
              onSelected: (_) =>
                  _updateConfig(_config.copyWith(direction: dir)),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _SliderRow(
          label: '滾動速度',
          valueText: _config.scrollSpeed.toStringAsFixed(1),
          value: _config.scrollSpeed,
          min: 0.0,
          max: 10.0,
          onChanged: (v) => _updateConfig(_config.copyWith(scrollSpeed: v)),
        ),
        _SliderRow(
          label: '畫面亮度',
          valueText: '${(_config.brightness * 100).round()}%',
          value: _config.brightness,
          min: 0.2,
          max: 1.0,
          onChanged: (v) => _updateConfig(_config.copyWith(brightness: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('鏡像模式（水平翻轉）'),
          subtitle: const Text('適合隔著車窗或對鏡顯示'),
          value: _config.mirrorMode,
          onChanged: (v) => _updateConfig(_config.copyWith(mirrorMode: v)),
        ),
        const Divider(height: 24, color: Colors.white10),
        _SectionTitle('背景特效'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BackgroundEffect.values.map((fx) {
            return ChoiceChip(
              label: Text(fx.label),
              selected: _config.backgroundEffect == fx,
              onSelected: (_) =>
                  _updateConfig(_config.copyWith(backgroundEffect: fx)),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _ColorSwatchRow(
          title: '背景主色',
          selectedColor: _config.backgroundColor,
          palette: bgColorPalette,
          onSelect: (c) =>
              _updateConfig(_config.copyWith(backgroundColor: c)),
          onCustomTap: () => _pickCustomColor(
            title: '選擇背景主色',
            current: _config.backgroundColor,
            swatches: bgColorPalette,
            onSelected: (c) =>
                _updateConfig(_config.copyWith(backgroundColor: c)),
          ),
        ),
        if (_config.backgroundEffect != BackgroundEffect.solid) ...[
          const SizedBox(height: 14),
          _ColorSwatchRow(
            title: '特效點綴色',
            selectedColor: _config.backgroundAccentColor,
            palette: neonColorPalette,
            onSelect: (c) =>
                _updateConfig(_config.copyWith(backgroundAccentColor: c)),
            onCustomTap: () => _pickCustomColor(
              title: '選擇特效點綴色',
              current: _config.backgroundAccentColor,
              onSelected: (c) =>
                  _updateConfig(_config.copyWith(backgroundAccentColor: c)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPresetsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        FilledButton.tonalIcon(
          onPressed: _saveFavoriteDialog,
          icon: const Icon(Icons.bookmark_add_rounded),
          label: const Text('將目前設定存成我的模板'),
        ),
        const SizedBox(height: 16),
        _SectionTitle('精選場景模板'),
        const SizedBox(height: 6),
        ...builtInPresets.map((preset) => _PresetTile(
              preset: preset,
              onTap: () => _applyPreset(preset),
            )),
        if (_favorites.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('我的收藏'),
          const SizedBox(height: 6),
          ..._favorites.map((preset) => _PresetTile(
                preset: preset,
                onTap: () => _applyPreset(preset),
                onDelete: () => _deleteFavorite(preset.id),
              )),
        ],
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionTitle('最近播放紀錄'),
          const SizedBox(height: 6),
          ..._history.map((preset) => _PresetTile(
                preset: preset,
                onTap: () => _applyPreset(preset),
              )),
        ],
      ],
    );
  }
}

class _MiniPreviewButton extends StatelessWidget {
  const _MiniPreviewButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white70,
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Text(
              valueText,
              style: const TextStyle(
                color: Color(0xFF00F5D4),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ColorSwatchRow extends StatelessWidget {
  const _ColorSwatchRow({
    required this.title,
    required this.selectedColor,
    required this.palette,
    required this.onSelect,
    required this.onCustomTap,
  });

  final String title;
  final Color selectedColor;
  final List<Color> palette;
  final ValueChanged<Color> onSelect;
  final VoidCallback onCustomTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...palette.map((color) {
              final selected = color.toARGB32() == selectedColor.toARGB32();
              final isLight = color.computeLuminance() > 0.65;
              return GestureDetector(
                onTap: () => onSelect(color),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? (isLight ? const Color(0xFF00F5D4) : Colors.white)
                          : (isLight ? Colors.black26 : Colors.white24),
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: isLight ? Colors.black87 : Colors.white,
                        )
                      : null,
                ),
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.palette_outlined, size: 16),
              label: const Text('調色盤'),
              onPressed: onCustomTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.onTap,
    this.onDelete,
  });

  final BannerPreset preset;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final c = preset.config;
    return Card(
      color: const Color(0xFF1C2233),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.textColor, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            'LED',
            style: TextStyle(
              color: c.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(
          preset.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          c.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                preset.category,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: '刪除',
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
