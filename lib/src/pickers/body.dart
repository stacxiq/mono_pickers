import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
// Material moved to package:material_ui in Flutter 3.47; keep this import so
// the package still supports older Flutter versions.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../core/controls.dart';
import '../core/effects.dart';
import '../core/feedback.dart';
import '../core/physics.dart';
import '../core/theme.dart';

bool _isMult(double v, double m) =>
    ((v / m) - (v / m).roundToDouble()).abs() < 1e-6;

TextPainter _label(String text, TextStyle style) => TextPainter(
  text: TextSpan(text: text, style: style),
  textDirection: TextDirection.ltr,
)..layout();

// ───────────────────────── Body silhouette ─────────────────────────

/// Right half of the body outline, in units of body height
/// (x from the center line, y: 0 = top of head, 1 = floor).
const List<(double, double)> _rh = [
  (.026, .135),
  (.031, .152),
  (.07, .166),
  (.112, .186),
  (.128, .232),
  (.134, .33),
  (.131, .44),
  (.123, .503),
  (.107, .506),
  (.1, .44),
  (.098, .33),
  (.092, .258),
  (.08, .33),
  (.073, .4),
  (.084, .482),
  (.08, .6),
  (.066, .76),
  (.059, .94),
  (.07, .988),
  (.021, .996),
  (.022, .94),
  (.025, .76),
  (.015, .565),
];

final List<(double, double)> _outline = [
  ..._rh,
  (0, .54),
  ..._rh.reversed.map((p) => (-p.$1, p.$2)),
];

Path _smoothClosed(List<Offset> pts) {
  final n = pts.length;
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = pts[(i - 1 + n) % n], p1 = pts[i];
    final p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n];
    path.cubicTo(
      p1.dx + (p2.dx - p0.dx) / 6,
      p1.dy + (p2.dy - p0.dy) / 6,
      p2.dx - (p3.dx - p1.dx) / 6,
      p2.dy - (p3.dy - p1.dy) / 6,
      p2.dx,
      p2.dy,
    );
  }
  return path..close();
}

Shader _figureShader(Color ink, double top, double floor) => ui.Gradient.linear(
  Offset(0, top),
  Offset(0, floor),
  [
    ink.withValues(alpha: 0.92),
    ink.withValues(alpha: 0.38),
    ink.withValues(alpha: 0.06),
  ],
  const [0, 0.55, 1],
);

// ───────────────────────── Ruler ─────────────────────────

/// A horizontal ruler you drag or flick; ticks magnify around the center
/// needle. Ideal for weight, distance, money or any long numeric range.
class MonoRulerPicker extends StatefulWidget {
  /// Creates a ruler picker.
  const MonoRulerPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.majorInterval = 10,
    this.midInterval,
    this.pixelsPerStep = 10,
    this.labelBuilder,
    this.semanticLabel = 'Value',
    this.height = 128,
  });

  /// Current value.
  final double value;

  /// Called when the value under the needle changes.
  final ValueChanged<double> onChanged;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Value between neighbouring ticks.
  final double step;

  /// Values that are multiples of this get a long, labelled tick.
  final double majorInterval;

  /// Values that are multiples of this get a medium tick.
  final double? midInterval;

  /// Distance between ticks in logical pixels.
  final double pixelsPerStep;

  /// Formats labels under major ticks.
  final String Function(double value)? labelBuilder;

  /// Accessibility label.
  final String semanticLabel;

  /// Height of the ruler.
  final double height;

  @override
  State<MonoRulerPicker> createState() => _MonoRulerPickerState();
}

class _MonoRulerPickerState extends State<MonoRulerPicker>
    with SingleTickerProviderStateMixin {
  late final MonoIndexScroller _s;
  late double _pos;

  int get _n => ((widget.max - widget.min) / widget.step).round();
  double _valueAt(int i) =>
      double.parse((widget.min + i * widget.step).toStringAsFixed(6));
  double _indexOf(double v) =>
      ((v.clamp(widget.min, widget.max) - widget.min) / widget.step)
          .roundToDouble();

  @override
  void initState() {
    super.initState();
    _pos = _indexOf(widget.value);
    _s = MonoIndexScroller(
      vsync: this,
      maxIndex: _n,
      position: _pos,
      onPosition: (p) => setState(() => _pos = p),
      onIndex: (i) {
        final v = _valueAt(i);
        MonoTick.play(context, strong: _isMult(v, widget.majorInterval));
        widget.onChanged(v);
      },
    );
  }

  @override
  void didUpdateWidget(MonoRulerPicker old) {
    super.didUpdateWidget(old);
    _s.maxIndex = _n;
    final target = _indexOf(widget.value);
    if (old.min != widget.min || old.step != widget.step) {
      _s.jump(target);
    } else if (!_s.isDragging && target != _s.index) {
      _s.animateTo(target, tau: 160);
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _step(int d) {
    final i = (_s.index + d).clamp(0, _n);
    _s.animateTo(i.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final dir = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    final v = _valueAt(_s.index);
    return MonoAdjustable(
      label: widget.semanticLabel,
      valueText: widget.labelBuilder?.call(v) ?? '$v',
      onStep: _step,
      onHome: () => _s.animateTo(0),
      onEnd: () => _s.animateTo(_n.toDouble()),
      child: Listener(
        onPointerSignal: (e) {
          if (e is PointerScrollEvent) {
            GestureBinding.instance.pointerSignalResolver.register(e, (ev) {
              final d = (ev as PointerScrollEvent).scrollDelta;
              final delta = d.dx.abs() > d.dy.abs() ? d.dx * dir : d.dy;
              _s.wheel(delta / widget.pixelsPerStep * 0.6);
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _s.dragStart(),
          onHorizontalDragUpdate: (d) =>
              _s.dragBy(-d.delta.dx * dir / widget.pixelsPerStep),
          onHorizontalDragEnd: (_) => _s.dragEnd(),
          onHorizontalDragCancel: _s.dragEnd,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                colors: [
                  Color(0x00000000),
                  Color(0xFF000000),
                  Color(0xFF000000),
                  Color(0x00000000),
                ],
                stops: [0, 0.18, 0.82, 1],
              ).createShader(r),
              child: CustomPaint(
                size: Size(double.infinity, widget.height),
                painter: _RulerPainter(
                  pos: _pos,
                  n: _n,
                  w: widget,
                  ink: t.ink,
                  dir: dir,
                  labelStyle: t.text(size: 11, color: t.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.pos,
    required this.n,
    required this.w,
    required this.ink,
    required this.dir,
    required this.labelStyle,
  });

  final double pos;
  final int n;
  final MonoRulerPicker w;
  final Color ink;
  final double dir;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height * 88 / 128;
    final cx = size.width / 2;
    final half = size.width / 2 - 10;
    final pps = w.pixelsPerStep;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    final span = (half / pps).ceil() + 1;
    for (
      var i = math.max(0, (pos - span).floor());
      i <= math.min(n, (pos + span).ceil());
      i++
    ) {
      final v = w.min + i * w.step;
      final d = (i - pos) * pps * dir;
      if (d.abs() > half) continue;
      final maj = _isMult(v, w.majorInterval);
      final mid = w.midInterval != null && _isMult(v, w.midInterval!);
      final f = 1 + 0.45 * math.exp(-math.pow(d / 34, 2));
      final fade = 1 - math.pow(d.abs() / half, 2).toDouble();
      final h =
          (maj
              ? 32
              : mid
              ? 20
              : 11) *
          f;
      final x = cx + d;
      paint.color = ink.withValues(
        alpha:
            (fade *
                    (maj
                        ? 1
                        : mid
                        ? 0.55
                        : 0.28))
                .clamp(0, 1),
      );
      canvas.drawLine(Offset(x, base), Offset(x, base - h), paint);
      if (maj) {
        final text =
            w.labelBuilder?.call(double.parse(v.toStringAsFixed(6))) ??
            (v == v.roundToDouble() ? v.toInt().toString() : v.toString());
        final tp = _label(
          text,
          labelStyle.copyWith(
            color: ink.withValues(alpha: (fade * 0.75).clamp(0, 1)),
          ),
        );
        tp.paint(canvas, Offset(x - tp.width / 2, base + 24 - tp.height + 2));
      }
    }
    final needle = Paint()
      ..color = ink
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, base - 62), Offset(cx, base + 6), needle);
    canvas.drawCircle(Offset(cx, base - 70), 3.5, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.pos != pos || old.ink != ink || old.dir != dir || old.n != n;
}

// ───────────────────────── Height ─────────────────────────

/// Length units for [MonoHeightPicker].
enum MonoLengthUnit {
  /// Centimetres, 1 cm steps.
  cm,

  /// Feet and inches, 1 inch steps.
  ftIn,
}

/// A stadiometer: a silhouette grows as you drag the headboard, and the
/// ruler magnifies around it like a dock.
class MonoHeightPicker extends StatefulWidget {
  /// Creates a height picker. [cm] is always in centimetres.
  const MonoHeightPicker({
    super.key,
    required this.cm,
    required this.onChanged,
    this.unit = MonoLengthUnit.cm,
    this.minCm = 120,
    this.maxCm = 220,
    this.semanticLabel = 'Height',
  });

  /// Height in centimetres.
  final double cm;

  /// Called with the new height in centimetres.
  final ValueChanged<double> onChanged;

  /// Display and step unit.
  final MonoLengthUnit unit;

  /// Minimum height.
  final double minCm;

  /// Maximum height.
  final double maxCm;

  /// Accessibility label.
  final String semanticLabel;

  /// Formats [cm] in [unit], e.g. `178 cm` or `5′10″`.
  static String format(double cm, MonoLengthUnit unit) {
    if (unit == MonoLengthUnit.cm) return '${cm.round()} cm';
    final inches = (cm / 2.54).round();
    return '${inches ~/ 12}′${inches % 12}″';
  }

  @override
  State<MonoHeightPicker> createState() => _MonoHeightPickerState();
}

class _HeightCfg {
  const _HeightCfg(
    this.min,
    this.max,
    this.cmPer,
    this.t0,
    this.t1,
    this.ts,
    this.major,
    this.mid,
  );
  final int min, max;
  final double cmPer;
  final int t0, t1, ts, major;
  final int? mid;
  double cm(num v) => v * cmPer;
}

class _MonoHeightPickerState extends State<MonoHeightPicker>
    with SingleTickerProviderStateMixin {
  late final MonoIndexScroller _s;
  late double _pos;

  _HeightCfg get _cfg => widget.unit == MonoLengthUnit.cm
      ? _HeightCfg(
          widget.minCm.round(),
          widget.maxCm.round(),
          1,
          widget.minCm.round() - 5,
          widget.maxCm.round() + 5,
          5,
          10,
          null,
        )
      : _HeightCfg(
          (widget.minCm / 2.54).round(),
          (widget.maxCm / 2.54).round(),
          2.54,
          ((widget.minCm / 2.54) / 3).floor() * 3 - 6,
          ((widget.maxCm / 2.54) / 3).ceil() * 3 + 3,
          3,
          12,
          6,
        );

  int get _n => _cfg.max - _cfg.min;
  double _indexOf(double cm) =>
      ((cm / _cfg.cmPer).round().clamp(_cfg.min, _cfg.max) - _cfg.min)
          .toDouble();

  @override
  void initState() {
    super.initState();
    _pos = _indexOf(widget.cm);
    _s = MonoIndexScroller(
      vsync: this,
      maxIndex: _n,
      position: _pos,
      onPosition: (p) => setState(() => _pos = p),
      onIndex: (i) {
        final v = _cfg.min + i;
        MonoTick.play(context, strong: v % _cfg.major == 0);
        widget.onChanged(_cfg.cm(v));
      },
    );
  }

  @override
  void didUpdateWidget(MonoHeightPicker old) {
    super.didUpdateWidget(old);
    _s.maxIndex = _n;
    final target = _indexOf(widget.cm);
    if (old.unit != widget.unit) {
      _s.jump(target);
    } else if (!_s.isDragging && target != _s.index) {
      _s.animateTo(target, tau: 160);
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth.isFinite ? c.maxWidth : 320.0;
        final scale = w / 320;
        final px = _cfg.cmPer * 1.27 / 0.6 * scale;
        return MonoAdjustable(
          label: widget.semanticLabel,
          valueText: MonoHeightPicker.format(
            _cfg.cm(_cfg.min + _s.index),
            widget.unit,
          ),
          onStep: (d) => _s.animateTo((_s.index + d).clamp(0, _n).toDouble()),
          child: Listener(
            onPointerSignal: (e) {
              if (e is PointerScrollEvent) {
                GestureBinding.instance.pointerSignalResolver.register(e, (ev) {
                  _s.wheel(
                    -(ev as PointerScrollEvent).scrollDelta.dy / px * 0.6,
                  );
                });
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) => _s.dragStart(),
              onVerticalDragUpdate: (d) => _s.dragBy(-d.delta.dy / px),
              onVerticalDragEnd: (_) => _s.dragEnd(),
              onVerticalDragCancel: _s.dragEnd,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: CustomPaint(
                  size: Size(w, w * 316 / 320),
                  painter: _HeightPainter(
                    pos: _pos,
                    cfg: _cfg,
                    n: _n,
                    ink: t.ink,
                    surface: t.surface,
                    label: t.text(size: 11),
                    ft: widget.unit == MonoLengthUnit.ftIn,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeightPainter extends CustomPainter {
  _HeightPainter({
    required this.pos,
    required this.cfg,
    required this.n,
    required this.ink,
    required this.surface,
    required this.label,
    required this.ft,
  });

  final double pos;
  final _HeightCfg cfg;
  final int n;
  final Color ink, surface;
  final TextStyle label;
  final bool ft;

  static const k = 1.27, floor = 304.0, fx = 118.0, rx = 296.0;
  double _y(double cm) => floor - cm * k;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320);
    final v = cfg.min + pos.clamp(-1.5, n + 1.5);
    final h = cfg.cm(v) * k;
    final top = floor - h;
    final line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(fx, floor), width: 104, height: 9),
      Paint()..color = ink.withValues(alpha: 0.07),
    );
    line.color = ink.withValues(alpha: 0.14);
    canvas.drawLine(const Offset(20, floor), const Offset(rx + 4, floor), line);
    canvas.drawLine(Offset(rx, _y(228)), const Offset(rx, floor), line);

    for (var tv = cfg.t0; tv <= cfg.t1; tv += cfg.ts) {
      final y = _y(cfg.cm(tv));
      final d = y - top;
      final g = math.exp(-math.pow(d / 24, 2));
      final maj = tv % cfg.major == 0;
      final mid = cfg.mid != null && tv % cfg.mid! == 0;
      final len =
          (maj
              ? 14
              : mid
              ? 10
              : 6) *
          (1 + 1.1 * g);
      line.color = ink.withValues(
        alpha: ((maj ? 0.55 : 0.22) + 0.45 * g).clamp(0, 1),
      );
      canvas.drawLine(Offset(rx - 6, y), Offset(rx - 6 - len, y), line);
      if (maj && d.abs() > 9 && d.abs() < 46) {
        final text = ft ? '${tv ~/ 12}′' : '$tv';
        final o = math.pow((1 - d.abs() / 46).clamp(0, 1), 0.7).toDouble();
        final tp = _label(
          text,
          label.copyWith(color: ink.withValues(alpha: o)),
        );
        tp.paint(canvas, Offset(rx - 38 - tp.width, y + 4 - tp.height + 2));
      }
    }

    final fill = Paint()..shader = _figureShader(ink, top, floor);
    canvas.drawCircle(Offset(fx, top + 0.064 * h), 0.061 * h, fill);
    canvas.drawPath(
      _smoothClosed([
        for (final (x, y) in _outline) Offset(fx + x * h, top + y * h),
      ]),
      fill,
    );

    // dashed rail
    final rail = Paint()
      ..color = ink.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var x = fx + 40; x < rx - 18; x += 6) {
      canvas.drawLine(Offset(x, top - 3.5), Offset(x + 1, top - 3.5), rail);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(fx - 34, top - 6, 68, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = ink,
    );
    final kc = Offset(rx, top - 3.5);
    canvas.drawCircle(kc, 12, Paint()..color = surface);
    canvas.drawCircle(
      kc,
      12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ink,
    );
    final chev = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;
    canvas.drawPath(
      Path()
        ..moveTo(kc.dx - 3.5, kc.dy - 2)
        ..lineTo(kc.dx, kc.dy - 5.5)
        ..lineTo(kc.dx + 3.5, kc.dy - 2)
        ..moveTo(kc.dx - 3.5, kc.dy + 2)
        ..lineTo(kc.dx, kc.dy + 5.5)
        ..lineTo(kc.dx + 3.5, kc.dy + 2),
      chev,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HeightPainter old) =>
      old.pos != pos || old.ink != ink || old.ft != ft || old.n != n;
}

// ───────────────────────── Drum ─────────────────────────

/// An iOS-style 3D wheel. Drag, flick, scroll or tap an item.
class MonoDrumPicker extends StatefulWidget {
  /// Creates a drum picker over [items].
  const MonoDrumPicker({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.height = 232,
    this.itemExtent = 40,
    this.showBand = true,
    this.semanticLabel = 'Value',
    this.fontSize = 28,
    this.majorEvery,
  });

  /// Labels, one per position.
  final List<String> items;

  /// Selected index.
  final int value;

  /// Called with the new index.
  final ValueChanged<int> onChanged;

  /// Optional unit drawn to the right of the band (e.g. "years").
  final String? suffix;

  /// Height of the wheel.
  final double height;

  /// Height of each row.
  final double itemExtent;

  /// Whether to draw the selection band (turn off when combining drums).
  final bool showBand;

  /// Accessibility label.
  final String semanticLabel;

  /// Label size.
  final double fontSize;

  /// Indices that are multiples of this play a strong tick.
  final int? majorEvery;

  @override
  State<MonoDrumPicker> createState() => _MonoDrumPickerState();
}

class _MonoDrumPickerState extends State<MonoDrumPicker>
    with SingleTickerProviderStateMixin {
  late final MonoIndexScroller _s;
  late double _pos;
  static const _stepDeg = 18.0;

  double get _r =>
      widget.itemExtent / (2 * math.tan(_stepDeg / 2 * math.pi / 180));

  @override
  void initState() {
    super.initState();
    _pos = widget.value.toDouble();
    _s = MonoIndexScroller(
      vsync: this,
      maxIndex: widget.items.length - 1,
      position: _pos,
      onPosition: (p) => setState(() => _pos = p),
      onIndex: (i) {
        MonoTick.play(
          context,
          strong: widget.majorEvery != null && i % widget.majorEvery! == 0,
        );
        widget.onChanged(i);
      },
    );
  }

  @override
  void didUpdateWidget(MonoDrumPicker old) {
    super.didUpdateWidget(old);
    _s.maxIndex = widget.items.length - 1;
    if (!_s.isDragging && widget.value != _s.index) {
      _s.animateTo(widget.value.toDouble(), tau: 160);
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final h = widget.height;
    final r = _r;
    final children = <Widget>[];
    final n = widget.items.length - 1;
    for (
      var i = math.max(0, (_pos - 5).floor());
      i <= math.min(n, (_pos + 5).ceil());
      i++
    ) {
      final a = (i - _pos) * _stepDeg;
      if (a.abs() >= 90) continue;
      final rad = a * math.pi / 180;
      final c = math.cos(rad);
      final y = h / 2 + r * math.sin(rad) - widget.itemExtent / 2;
      children.add(
        Positioned(
          left: 0,
          right: 0,
          top: y,
          height: widget.itemExtent,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(1, c, 1),
            child: Opacity(
              opacity: (0.18 + 0.82 * math.pow(c, 3)).clamp(0, 1).toDouble(),
              child: Center(
                child: Text(
                  widget.items[i],
                  style: t.text(
                    size: widget.fontSize,
                    weight: FontWeight.w600,
                    color: (i - _pos).abs() < 0.5 ? t.ink : t.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return MonoAdjustable(
      label: widget.semanticLabel,
      valueText:
          widget.items[_s.index] +
          (widget.suffix == null ? '' : ' ${widget.suffix}'),
      onStep: (d) => _s.animateTo((_s.index + d).clamp(0, n).toDouble()),
      onHome: () => _s.animateTo(0),
      onEnd: () => _s.animateTo(n.toDouble()),
      child: Listener(
        onPointerSignal: (e) {
          if (e is PointerScrollEvent) {
            GestureBinding.instance.pointerSignalResolver.register(e, (ev) {
              _s.wheel(
                (ev as PointerScrollEvent).scrollDelta.dy /
                    widget.itemExtent *
                    0.6,
              );
            });
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) => _s.dragStart(),
          onVerticalDragUpdate: (d) =>
              _s.dragBy(-d.delta.dy / widget.itemExtent),
          onVerticalDragEnd: (_) => _s.dragEnd(),
          onVerticalDragCancel: _s.dragEnd,
          onTapUp: (d) {
            final dy = d.localPosition.dy - h / 2;
            final a = math.asin((dy / r).clamp(-1.0, 1.0)) * 180 / math.pi;
            _s.animateTo(
              (_pos + a / _stepDeg).roundToDouble().clamp(0, n.toDouble()),
              tau: 160,
            );
          },
          child: SizedBox(
            height: h,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0xFF000000),
                  Color(0xFF000000),
                  Color(0x00000000),
                ],
                stops: [0, 0.22, 0.78, 1],
              ).createShader(rect),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (widget.showBand)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: h / 2 - 23,
                      height: 46,
                      child: MonoBand(theme: t),
                    ),
                  ...children,
                  if (widget.suffix != null)
                    PositionedDirectional(
                      end: 0,
                      top: 0,
                      bottom: 0,
                      child: FractionallySizedBox(
                        widthFactor: null,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(end: 18),
                          child: Center(
                            child: Text(
                              widget.suffix!,
                              style: t.text(size: 13, color: t.muted),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The soft rounded band that marks the selected row of a drum.
class MonoBand extends StatelessWidget {
  /// Creates a band.
  const MonoBand({super.key, required this.theme});

  /// Theme.
  final MonoPickerThemeData theme;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: theme.soft,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: theme.line),
    ),
  );
}

// ───────────────────────── Body fat ─────────────────────────

/// Biological sex, which changes body-fat categories and the silhouette.
enum MonoSex {
  /// Male ranges and shape.
  male,

  /// Female ranges and shape.
  female,
}

/// A labelled range of body-fat percentages.
@immutable
class MonoRangeCategory {
  /// Creates a category from [from] to [to] (inclusive).
  const MonoRangeCategory(this.label, this.from, this.to);

  /// Name.
  final String label;

  /// Lowest value.
  final int from;

  /// Highest value.
  final int to;
}

/// A body-fat slider whose silhouette morphs as you drag. The track is
/// segmented by category (Athletic, Fitness, Average, Above).
class MonoBodyFatPicker extends StatefulWidget {
  /// Creates a body-fat picker.
  const MonoBodyFatPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.sex = MonoSex.male,
    this.min = 5,
    this.max = 45,
    this.categories,
  });

  /// Percentage.
  final int value;

  /// Called with the new percentage.
  final ValueChanged<int> onChanged;

  /// Sex (silhouette and default categories).
  final MonoSex sex;

  /// Minimum.
  final int min;

  /// Maximum.
  final int max;

  /// Categories; defaults depend on [sex].
  final List<MonoRangeCategory>? categories;

  /// Default categories for [sex].
  static List<MonoRangeCategory> defaultCategories(MonoSex sex) =>
      sex == MonoSex.male
      ? const [
          MonoRangeCategory('Athletic', 5, 13),
          MonoRangeCategory('Fitness', 14, 17),
          MonoRangeCategory('Average', 18, 24),
          MonoRangeCategory('Above', 25, 45),
        ]
      : const [
          MonoRangeCategory('Athletic', 5, 20),
          MonoRangeCategory('Fitness', 21, 24),
          MonoRangeCategory('Average', 25, 31),
          MonoRangeCategory('Above', 32, 45),
        ];

  @override
  State<MonoBodyFatPicker> createState() => _MonoBodyFatPickerState();
}

class _MonoBodyFatPickerState extends State<MonoBodyFatPicker>
    with TickerProviderStateMixin {
  late final MonoSmoother _val = MonoSmoother(
    vsync: this,
    value: widget.value.toDouble(),
    onChanged: (_) => setState(() {}),
  );
  late final MonoSmoother _sex = MonoSmoother(
    vsync: this,
    value: widget.sex == MonoSex.female ? 1 : 0,
    onChanged: (_) => setState(() {}),
  );
  bool _drag = false;

  List<MonoRangeCategory> get _cats =>
      widget.categories ?? MonoBodyFatPicker.defaultCategories(widget.sex);
  int _catOf(int v) {
    final i = _cats.indexWhere((c) => v >= c.from && v <= c.to);
    return i < 0 ? 0 : i;
  }

  @override
  void didUpdateWidget(MonoBodyFatPicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _val.animateTo(widget.value.toDouble());
    if (old.sex != widget.sex) {
      _sex.animateTo(widget.sex == MonoSex.female ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _val.dispose();
    _sex.dispose();
    super.dispose();
  }

  void _set(int v) {
    v = v.clamp(widget.min, widget.max);
    if (v == widget.value) return;
    MonoTick.play(context, strong: _catOf(v) != _catOf(widget.value));
    widget.onChanged(v);
  }

  void _fromX(double x, double w) {
    var f = x / w;
    if (Directionality.of(context) == TextDirection.rtl) f = 1 - f;
    final span = widget.max - widget.min + 1;
    _set((widget.min + f * span - 0.5).round());
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final cats = _cats;
    final cur = _catOf(widget.value);
    final span = widget.max - widget.min + 1;
    final frac = (widget.value - widget.min + 0.5) / span;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: AspectRatio(
                  aspectRatio: 240 / 232,
                  child: CustomPaint(
                    painter: _BodyFatPainter(
                      t: ((_val.shown - widget.min) / (widget.max - widget.min))
                          .clamp(0, 1.2),
                      s: _sex.shown,
                      ink: t.ink,
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              start: 0,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: t.soft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.line),
                ),
                child: MonoSwapText(
                  cats[cur].label,
                  style: t.text(size: 12, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MonoAdjustable(
          label: 'Body fat',
          radius: 999,
          valueText: '${widget.value}% · ${cats[cur].label}',
          onStep: (d) => _set(widget.value + d),
          onHome: () => _set(widget.min),
          onEnd: () => _set(widget.max),
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _fromX(d.localPosition.dx, w),
                onHorizontalDragStart: (d) {
                  setState(() => _drag = true);
                  _fromX(d.localPosition.dx, w);
                },
                onHorizontalDragUpdate: (d) => _fromX(d.localPosition.dx, w),
                onHorizontalDragEnd: (_) => setState(() => _drag = false),
                child: SizedBox(
                  height: 28,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Positioned.fill(
                        child: Center(
                          child: SizedBox(
                            height: 6,
                            child: Row(
                              children: [
                                for (var i = 0; i < cats.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 3),
                                  Expanded(
                                    flex: cats[i].to - cats[i].from + 1,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      decoration: BoxDecoration(
                                        color: t.ink.withValues(
                                          alpha: i == cur ? 0.6 : 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositionedDirectional(
                        duration: Duration(milliseconds: _drag ? 80 : 400),
                        curve: _drag ? Curves.linear : monoSpring,
                        start: frac * w - 12,
                        top: 2,
                        child: MonoThumb(theme: t, active: _drag),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var i = 0; i < cats.length; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                flex: cats[i].to - cats[i].from + 1,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: t.text(
                    size: 10.5,
                    weight: i == cur ? FontWeight.w600 : FontWeight.w400,
                    color: i == cur ? t.ink : t.muted,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      cats[i].label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The round slider thumb used across mono pickers.
class MonoThumb extends StatelessWidget {
  /// Creates a thumb.
  const MonoThumb({
    super.key,
    required this.theme,
    this.active = false,
    this.size = 24,
  });

  /// Theme.
  final MonoPickerThemeData theme;

  /// Whether it is being dragged (slightly enlarged).
  final bool active;

  /// Diameter.
  final double size;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: active ? 1.12 : 1,
    duration: const Duration(milliseconds: 150),
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: theme.ink, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
    ),
  );
}

class _BodyFatPainter extends CustomPainter {
  _BodyFatPainter({required this.t, required this.s, required this.ink});

  final double t, s;
  final Color ink;

  static const fx = 120.0, floor = 224.0, h = 210.0, top = floor - h;

  static double _k(double y, double t, double s) =>
      (0.9 + t * (0.32 + 0.62 * math.exp(-math.pow((y - 0.45) / 0.14, 2)))) *
      (1 +
          s *
              (-0.1 * math.exp(-math.pow((y - 0.2) / 0.07, 2)) +
                  0.13 * math.exp(-math.pow((y - 0.52) / 0.08, 2))));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 240);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(fx, floor), width: 120, height: 9),
      Paint()..color = ink.withValues(alpha: 0.07),
    );
    final n = _rh.length;
    final pts = <Offset>[];
    for (var i = 0; i < _outline.length; i++) {
      final (x, y) = _outline[i];
      final r = i < n ? i : 2 * n - i;
      final arm = i != n && r >= 4 && r <= 10;
      final k = _k(y, t, s);
      if (arm) {
        final ax = x.abs(), sg = x.sign;
        pts.add(
          Offset(
            fx +
                sg *
                    (ax * 0.9 + 0.088 * (k - 0.9) + (ax - 0.116) * 0.4 * t) *
                    h,
            top + y * h,
          ),
        );
      } else {
        pts.add(Offset(fx + x * k * h, top + y * h));
      }
    }
    final fill = Paint()..shader = _figureShader(ink, top, floor);
    canvas.drawCircle(
      Offset(fx, top + 0.064 * h),
      0.061 * h * (1 + 0.06 * t),
      fill,
    );
    canvas.drawPath(_smoothClosed(pts), fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodyFatPainter old) =>
      old.t != t || old.s != s || old.ink != ink;
}
