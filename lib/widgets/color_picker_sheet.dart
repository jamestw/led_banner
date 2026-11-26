import 'package:flutter/material.dart';

import '../data/presets.dart';

Future<Color?> showColorPickerDialog(
  BuildContext context, {
  required Color initialColor,
  required String title,
  List<Color>? swatches,
}) {
  return showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF151925),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _ColorPickerSheet(
      initialColor: initialColor,
      title: title,
      swatches: swatches ?? neonColorPalette,
    ),
  );
}

class _ColorPickerSheet extends StatefulWidget {
  const _ColorPickerSheet({
    required this.initialColor,
    required this.title,
    required this.swatches,
  });

  final Color initialColor;
  final String title;
  final List<Color> swatches;

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late HSLColor _hsl;

  @override
  void initState() {
    super.initState();
    _hsl = HSLColor.fromColor(widget.initialColor);
  }

  Color get _currentColor => _hsl.toColor();

  String _toHex(Color color) {
    final argb = color.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _currentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _currentColor.withValues(alpha: 0.6),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _toHex(_currentColor),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.swatches.map((swatch) {
                  final selected =
                      swatch.toARGB32() == _currentColor.toARGB32();
                  final isLight = swatch.computeLuminance() > 0.65;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _hsl = HSLColor.fromColor(swatch);
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? (isLight
                                  ? const Color(0xFF00F5D4)
                                  : Colors.white)
                              : (isLight ? Colors.black26 : Colors.white24),
                          width: selected ? 3 : 1,
                        ),
                      ),
                      child: selected
                          ? Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: isLight ? Colors.black87 : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _buildSliderRow(
                label: '色相',
                value: _hsl.hue,
                min: 0,
                max: 360,
                activeColor: HSLColor.fromAHSL(1, _hsl.hue, 1, 0.5).toColor(),
                onChanged: (v) => setState(() => _hsl = _hsl.withHue(v)),
              ),
              _buildSliderRow(
                label: '飽和',
                value: _hsl.saturation,
                min: 0,
                max: 1,
                activeColor: _currentColor,
                onChanged: (v) =>
                    setState(() => _hsl = _hsl.withSaturation(v)),
              ),
              _buildSliderRow(
                label: '亮度',
                value: _hsl.lightness,
                min: 0.02,
                max: 0.98,
                activeColor: _currentColor,
                onChanged: (v) =>
                    setState(() => _hsl = _hsl.withLightness(v)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(context).pop(_currentColor),
                      child: const Text('套用顏色'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
