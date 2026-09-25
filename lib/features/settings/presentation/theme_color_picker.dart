/// Theme colour picker dialog.
///
/// Four ways in, from quickest to most precise: a preset swatch, a colour
/// taken from the background picture, hue / saturation / brightness sliders
/// drawn with their own gradients, and a hex field. A preview shows the
/// scheme Material builds from the seed — the seed itself is not what the app
/// paints with, so showing only the swatch would misrepresent the result.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Show the picker starting at [initial]; resolves to the chosen colour, or
/// null if cancelled.
Future<Color?> showThemeColorPicker(
  BuildContext context, {
  required Color initial,
  List<Color> backgroundColors = const [],
}) {
  return showDialog<Color>(
    context: context,
    builder: (context) => _ThemeColorPickerDialog(
      initial: initial,
      backgroundColors: backgroundColors,
    ),
  );
}

/// Preset seeds, one per hue family.
const themeColorPresets = <Color>[
  Color(0xFF1976D2), // 蓝（简约主题）
  Color(0xFF3F51B5), // 靛
  Color(0xFF6750A4), // 紫
  Color(0xFFE91E63), // 粉（二次元主题）
  Color(0xFFD32F2F), // 红
  Color(0xFFEF6C00), // 橙
  Color(0xFFF9A825), // 琥珀
  Color(0xFF2E7D32), // 绿
  Color(0xFF00897B), // 青绿
  Color(0xFF0097A7), // 青
  Color(0xFF6D4C41), // 棕
  Color(0xFF546E7A), // 蓝灰
];

/// `#RRGGBB` for [color], upper-case.
String colorToHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Parse `RRGGBB` or `#RRGGBB` into an opaque colour, or null.
Color? colorFromHex(String text) {
  final hex = text.trim().replaceFirst('#', '');
  if (hex.length != 6) return null;
  final rgb = int.tryParse(hex, radix: 16);
  return rgb == null ? null : Color(0xFF000000 | rgb);
}

class _ThemeColorPickerDialog extends StatefulWidget {
  const _ThemeColorPickerDialog({
    required this.initial,
    required this.backgroundColors,
  });

  final Color initial;
  final List<Color> backgroundColors;

  @override
  State<_ThemeColorPickerDialog> createState() =>
      _ThemeColorPickerDialogState();
}

class _ThemeColorPickerDialogState extends State<_ThemeColorPickerDialog> {
  /// Held as HSV, not as a Color. Converting back and forth loses the hue
  /// whenever saturation or brightness reaches 0 (every grey has hue 0), so
  /// dragging brightness to the bottom and back used to snap the hue slider
  /// to red.
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);
  late final _hexController = TextEditingController(
    text: colorToHex(widget.initial).substring(1),
  );

  Color get _color => _hsv.toColor();

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _setHsv(HSVColor hsv, {bool updateHex = true}) {
    setState(() => _hsv = hsv);
    if (updateHex) {
      final text = colorToHex(hsv.toColor()).substring(1);
      _hexController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _setColor(Color color, {bool updateHex = true}) {
    var hsv = HSVColor.fromColor(color);
    // A grey carries no hue of its own; keep the one the slider is on.
    if (hsv.saturation == 0 || hsv.value == 0) hsv = hsv.withHue(_hsv.hue);
    _setHsv(hsv, updateHex: updateHex);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _color;

    return AlertDialog(
      title: const Text('主题色'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SchemePreview(seed: color),
              const SizedBox(height: 16),
              Text('推荐颜色', style: textTheme.labelLarge),
              const SizedBox(height: 8),
              _SwatchRow(
                colors: themeColorPresets,
                selected: color,
                onTap: _setColor,
              ),
              if (widget.backgroundColors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('从背景图提取', style: textTheme.labelLarge),
                const SizedBox(height: 8),
                _SwatchRow(
                  colors: widget.backgroundColors,
                  selected: color,
                  onTap: _setColor,
                ),
              ],
              const SizedBox(height: 16),
              Text('自定义', style: textTheme.labelLarge),
              _GradientSlider(
                label: '色相',
                value: _hsv.hue,
                max: 360,
                thumbColor: color,
                colors: [
                  for (var h = 0; h <= 360; h += 60)
                    HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
                ],
                format: (v) => '${v.round()}°',
                onChanged: (v) => _setHsv(_hsv.withHue(v)),
              ),
              _GradientSlider(
                label: '饱和度',
                value: _hsv.saturation * 100,
                max: 100,
                thumbColor: color,
                colors: [
                  _hsv.withSaturation(0).toColor(),
                  _hsv.withSaturation(1).toColor(),
                ],
                format: (v) => '${v.round()}%',
                onChanged: (v) => _setHsv(_hsv.withSaturation(v / 100)),
              ),
              _GradientSlider(
                label: '明度',
                value: _hsv.value * 100,
                max: 100,
                thumbColor: color,
                colors: [
                  _hsv.withValue(0).toColor(),
                  _hsv.withValue(1).toColor(),
                ],
                format: (v) => '${v.round()}%',
                onChanged: (v) => _setHsv(_hsv.withValue(v / 100)),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('theme-color-hex'),
                controller: _hexController,
                decoration: const InputDecoration(
                  labelText: '色值',
                  prefixText: '#',
                  isDense: true,
                ),
                style: const TextStyle(fontFamily: 'monospace'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (text) {
                  final parsed = colorFromHex(text);
                  // Leave the field alone while the user types into it.
                  if (parsed != null) _setColor(parsed, updateHex: false);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(color),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// A miniature of the scheme [seed] produces.
class _SchemePreview extends StatelessWidget {
  const _SchemePreview({required this.seed});

  final Color seed;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: seed);
    final textTheme = Theme.of(context).textTheme;

    Widget tone(Color color, String label) => Expanded(
      child: Tooltip(
        message: label,
        child: Container(height: 28, color: color),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: seed, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      colorToHex(seed),
                      style: textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      '生成的配色预览',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {},
                  child: const Text('按钮'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                tone(scheme.primary, '主色'),
                tone(scheme.primaryContainer, '主色容器'),
                tone(scheme.secondary, '辅助色'),
                tone(scheme.secondaryContainer, '辅助色容器'),
                tone(scheme.tertiary, '第三色'),
                tone(scheme.surfaceContainerHighest, '表面'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwatchRow extends StatelessWidget {
  const _SwatchRow({
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onTap;

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final color in colors)
          Tooltip(
            message: colorToHex(color),
            child: InkResponse(
              onTap: () => onTap(color),
              radius: 22,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: outline.withValues(alpha: 0.4)),
                ),
                child: color.toARGB32() == selected.toARGB32()
                    ? Icon(
                        Icons.check,
                        size: 20,
                        color:
                            ThemeData.estimateBrightnessForColor(color) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      )
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// A slider whose track shows the colours it will produce.
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.colors,
    required this.thumbColor,
    required this.format,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final List<Color> colors;
  final Color thumbColor;
  final String Function(double value) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label, style: textTheme.bodyMedium)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              trackShape: _GradientTrackShape(colors),
              thumbShape: _RingThumbShape(thumbColor),
              overlayColor: thumbColor.withValues(alpha: 0.16),
            ),
            child: Slider(
              value: value.clamp(0, max),
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            format(value),
            textAlign: TextAlign.end,
            style: textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _GradientTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _GradientTrackShape(this.colors);

  final List<Color> colors;

  @override
  bool get isRounded => true;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    required TextDirection textDirection,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }
}

/// A thumb filled with the current colour inside a white ring.
///
/// The default thumb is the theme's primary colour, which is meaningless on a
/// colour track; and a thumb filled with the current colour alone vanishes
/// into the gradient at exactly its own position.
class _RingThumbShape extends SliderComponentShape {
  const _RingThumbShape(this.color);

  final Color color;

  static const _radius = 11.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(_radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    canvas
      ..drawCircle(
        center.translate(0, 1),
        _radius,
        Paint()
          ..color = Colors.black26
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      )
      ..drawCircle(center, _radius, Paint()..color = Colors.white)
      ..drawCircle(center, _radius - 3, Paint()..color = color);
  }
}
