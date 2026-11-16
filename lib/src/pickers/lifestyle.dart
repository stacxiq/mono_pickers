import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/controls.dart';
import '../core/effects.dart';
import '../core/feedback.dart';
import '../core/odometer.dart';
import '../core/physics.dart';
import '../core/theme.dart';
import 'body.dart' show MonoThumb;

// ───────────────────────── Ring dial (thermostat) ─────────────────────────

/// A 300° ring of ticks that light up to the target (thermostats, volume,
/// speed). Ticks swell around the knob; an optional dot marks the current
/// (ambient) value.
class MonoRingDial extends StatefulWidget {
  /// Creates a ring dial.
  const MonoRingDial({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 10,
    this.max = 30,
    this.step = 0.5,
    this.ambient,
    this.caption = '',
    this.unit = '°',
    this.decimals = 1,
    this.size = 280,
  });

  /// Target value.
  final double value;

  /// Called with the new target.
  final ValueChanged<double> onChanged;

  /// Minimum.
  final double min;

  /// Maximum.
  final double max;

  /// Snap step.
  final double step;

  /// Current reading, drawn as a small dot.
  final double? ambient;

  /// Caption under the value ("Heating").
  final String caption;

  /// Unit appended to the value.
  final String unit;

  /// Decimal places shown.
  final int decimals;

  /// Maximum diameter.
  final double size;

  @override
  State<MonoRingDial> createState() => _MonoRingDialState();
}

class _MonoRingDialState extends State<MonoRingDial>
    with SingleTickerProviderStateMixin {
  late final MonoSpring _spring = MonoSpring(
    vsync: this,
    value: widget.value,
    epsilon: 0.005,
    onChanged: (_) => setState(() {}),
  );

  @override
  void didUpdateWidget(MonoRingDial old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _spring.animateTo(widget.value);
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _set(double v) {
    v = ((v / widget.step).round() * widget.step).clamp(widget.min, widget.max);
    if ((v - widget.value).abs() < 1e-9) return;
    MonoTick.play(context, strong: (v - v.roundToDouble()).abs() < 1e-9);
    widget.onChanged(double.parse(v.toStringAsFixed(4)));
  }

  void _fromPointer(Offset p, double side, bool drag) {
    const c = 130.0, a0 = 120.0, sw = 300.0;
    final x = p.dx / side * 260, y = p.dy / side * 260;
    var rel = ((math.atan2(y - c, x - c) * 180 / math.pi) - a0 + 720) % 360;
    if (rel > sw) rel = rel > sw + (360 - sw) / 2 ? 0 : sw;
    final v = widget.min + rel / sw * (widget.max - widget.min);
    if (drag && (v - widget.value).abs() > (widget.max - widget.min) / 2) {
      return;
    }
    _set(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final text =
        '${widget.value.toStringAsFixed(widget.decimals)}${widget.unit}';
    return MonoAdjustable(
      label: widget.caption.isEmpty ? 'Value' : widget.caption,
      radius: 999,
      valueText: text,
      onStep: (d) =>
          _set(widget.value + d.sign * widget.step * (d.abs() >= 10 ? 4 : 1)),
      child: LayoutBuilder(
        builder: (context, c) {
          final side = math.min(widget.size, c.maxWidth);
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: Listener(
                onPointerSignal: (e) {
                  if (e is PointerScrollEvent) {
                    GestureBinding.instance.pointerSignalResolver.register(e, (
                      ev,
                    ) {
                      _set(
                        widget.value +
                            ((ev as PointerScrollEvent).scrollDelta.dy < 0
                                ? widget.step
                                : -widget.step),
                      );
                    });
                  }
                },
                child: GestureDetector(
                  onPanDown: (d) => _fromPointer(d.localPosition, side, false),
                  onPanUpdate: (d) => _fromPointer(d.localPosition, side, true),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CustomPaint(
                        painter: _RingPainter(
                          f:
                              ((_spring.shown - widget.min) /
                                      (widget.max - widget.min))
                                  .clamp(0.0, 1.0),
                          ambient: widget.ambient == null
                              ? null
                              : (widget.ambient! - widget.min) /
                                    (widget.max - widget.min),
                          ink: t.ink,
                          surface: t.surface,
                          label: t.text(
                            size: 11,
                            color: t.ink.withValues(alpha: 0.55),
                          ),
                          minLabel: '${widget.min.round()}${widget.unit}',
                          maxLabel: '${widget.max.round()}${widget.unit}',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MonoOdometer(
                              text,
                              style: t.text(
                                size: 46 * side / 280,
                                weight: FontWeight.w600,
                              ),
                            ),
                            if (widget.caption.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              MonoSwapText(
                                widget.caption.toUpperCase(),
                                style: t.text(
                                  size: 12,
                                  color: t.muted,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.f,
    required this.ambient,
    required this.ink,
    required this.surface,
    required this.label,
    required this.minLabel,
    required this.maxLabel,
  });

  final double f;
  final double? ambient;
  final Color ink, surface;
  final TextStyle label;
  final String minLabel, maxLabel;

  static const c = 130.0, r = 100.0, a0 = 120.0, sw = 300.0, n = 48;
  static Offset _pt(double deg, double rad) => Offset(
    c + rad * math.cos(deg * math.pi / 180),
    c + rad * math.sin(deg * math.pi / 180),
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 260);
    final p = Paint()..strokeCap = StrokeCap.round;
    for (var k = 0; k <= n; k++) {
      final kf = k / n;
      final on = kf <= f + 1e-6;
      final g = math.exp(-math.pow((kf - f) * n / 2.5, 2));
      final a = a0 + sw * kf;
      p
        ..strokeWidth = on ? 2.25 : 1.5
        ..color = ink.withValues(
          alpha: on ? (0.6 + 0.4 * (f > 0 ? kf / f : 1)).clamp(0, 1) : 0.14,
        );
      canvas.drawLine(_pt(a, r - 7 - g * 5), _pt(a, r + 7 + g * 6), p);
    }
    if (ambient != null) {
      canvas.drawCircle(
        _pt(a0 + sw * ambient!.clamp(0, 1), r - 26),
        3,
        Paint()..color = ink.withValues(alpha: 0.5),
      );
    }
    final k = _pt(a0 + sw * f, r + 24);
    canvas.drawCircle(k, 7, Paint()..color = surface);
    canvas.drawCircle(
      k,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ink,
    );
    for (final (text, frac) in [(minLabel, 0.0), (maxLabel, 1.0)]) {
      final pt = _pt(a0 + sw * frac, r);
      final tp = TextPainter(
        text: TextSpan(text: text, style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(pt.dx - tp.width / 2, pt.dy + 30 - tp.height + 2),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.f != f || old.ink != ink || old.ambient != ambient;
}

// ───────────────────────── Fill slider ─────────────────────────

/// A tall control-center style slider: drag anywhere to fill it.
/// Over-dragging stretches it slightly, like iOS.
class MonoFillSlider extends StatefulWidget {
  /// Creates a fill slider. [value] is 0..1.
  const MonoFillSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.icon,
    this.width = 92,
    this.height = 220,
    this.semanticLabel = 'Level',
  });

  /// Fill fraction, 0..1.
  final double value;

  /// Called with the new fraction.
  final ValueChanged<double> onChanged;

  /// Builds the icon for a value and a color (see [MonoSunIcon],
  /// [MonoVolumeIcon]).
  final Widget Function(double value, Color color)? icon;

  /// Width.
  final double width;

  /// Height.
  final double height;

  /// Accessibility label.
  final String semanticLabel;

  @override
  State<MonoFillSlider> createState() => _MonoFillSliderState();
}

class _MonoFillSliderState extends State<MonoFillSlider> {
  double _start = 0, _sy = 0, _over = 0;
  bool _drag = false;
  late int _lastPct = (widget.value * 100).round();

  void _emit(double v) {
    v = v.clamp(0.0, 1.0);
    final pct = (v * 100).round();
    if (pct != _lastPct) {
      if (pct % 10 == 0) MonoTick.play(context, strong: pct % 50 == 0);
      _lastPct = pct;
    }
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final v = widget.value.clamp(0.0, 1.0);
    final iconColor = v >= 0.23 ? t.onInk : t.ink;
    return MonoAdjustable(
      label: widget.semanticLabel,
      radius: 30,
      valueText: '${(v * 100).round()}%',
      onStep: (d) => _emit(((v * 100).round() + d * 5) / 100),
      child: GestureDetector(
        onVerticalDragStart: (d) {
          setState(() => _drag = true);
          _start = v;
          _sy = d.globalPosition.dy;
        },
        onVerticalDragUpdate: (d) {
          final nv = _start + (_sy - d.globalPosition.dy) / widget.height;
          setState(
            () => _over = nv > 1
                ? nv - 1
                : nv < 0
                ? nv
                : 0,
          );
          _emit(nv);
        },
        onVerticalDragEnd: (_) => setState(() {
          _drag = false;
          _over = 0;
        }),
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeUpDown,
          child: AnimatedScale(
            scale: 1,
            duration: Duration.zero,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _over),
              duration: Duration(milliseconds: _drag ? 0 : 450),
              curve: monoBounce,
              builder: (context, over, child) => Transform(
                alignment: over > 0
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                transform: Matrix4.diagonal3Values(
                  1,
                  1 + math.min(0.07, over.abs() * 0.18),
                  1,
                ),
                child: child,
              ),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: t.soft,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: t.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: _drag ? 0 : 450),
                        curve: monoSpring,
                        height: widget.height * v,
                        color: t.ink,
                      ),
                    ),
                    if (widget.icon != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 18,
                        child: Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: widget.icon!(v, iconColor),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sun whose core and rays grow with [value] (0..1).
class MonoSunIcon extends StatelessWidget {
  /// Creates a sun icon.
  const MonoSunIcon({super.key, required this.value, required this.color});

  /// 0..1.
  final double value;

  /// Stroke color.
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SunPainter(value, color),
    size: const Size.square(30),
  );
}

class _SunPainter extends CustomPainter {
  _SunPainter(this.v, this.color);
  final double v;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(const Offset(12, 12), 3.2 + 1.3 * v, p);
    final l = 1 + 2.4 * v;
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4;
      final c = math.cos(a), s = math.sin(a);
      canvas.drawLine(
        Offset(12 + c * 7, 12 + s * 7),
        Offset(12 + c * (7 + l), 12 + s * (7 + l)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.v != v || old.color != color;
}

/// A speaker with 0–2 waves (or muted) depending on [value] (0..1).
class MonoVolumeIcon extends StatelessWidget {
  /// Creates a volume icon.
  const MonoVolumeIcon({super.key, required this.value, required this.color});

  /// 0..1.
  final double value;

  /// Stroke color.
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _VolumePainter(value, color),
    size: const Size.square(30),
  );
}

class _VolumePainter extends CustomPainter {
  _VolumePainter(this.v, this.color);
  final double v;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(4, 9.5)
        ..lineTo(7, 9.5)
        ..lineTo(11.5, 5.5)
        ..lineTo(11.5, 18.5)
        ..lineTo(7, 14.5)
        ..lineTo(4, 14.5)
        ..close(),
      p,
    );
    if (v < 0.01) {
      canvas.drawLine(const Offset(16, 9.5), const Offset(21, 14.5), p);
      canvas.drawLine(const Offset(21, 9.5), const Offset(16, 14.5), p);
      return;
    }
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(12, 12), radius: 5),
      -0.9,
      1.8,
      false,
      p,
    );
    if (v > 0.45) {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(11, 12), radius: 8),
        -0.95,
        1.9,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_VolumePainter old) => old.v != v || old.color != color;
}

// ───────────────────────── Rating ─────────────────────────

Path _star(double s) {
  const pts = [
    (12.0, 3.3),
    (14.53, 9.32),
    (21.04, 9.86),
    (16.09, 14.13),
    (17.58, 20.49),
    (12.0, 17.1),
    (6.42, 20.49),
    (7.91, 14.13),
    (2.96, 9.86),
    (9.47, 9.32),
  ];
  final p = Path()..moveTo(pts[0].$1 * s, pts[0].$2 * s);
  for (final (x, y) in pts.skip(1)) {
    p.lineTo(x * s, y * s);
  }
  return p..close();
}

/// Star rating. Drag across or tap; filled stars pop in sequence.
class MonoRatingPicker extends StatefulWidget {
  /// Creates a rating picker.
  const MonoRatingPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 5,
    this.size = 46,
    this.labels,
  });

  /// Rating, 0..max.
  final int value;

  /// Called with the new rating.
  final ValueChanged<int> onChanged;

  /// Number of stars.
  final int max;

  /// Star size.
  final double size;

  /// Names for accessibility ("Terrible" … "Amazing").
  final List<String>? labels;

  @override
  State<MonoRatingPicker> createState() => _MonoRatingPickerState();
}

class _MonoRatingPickerState extends State<MonoRatingPicker> {
  late int _prev = widget.value;

  @override
  void didUpdateWidget(MonoRatingPicker old) {
    super.didUpdateWidget(old);
    _prev = old.value;
  }

  void _set(int v) {
    v = v.clamp(1, widget.max);
    if (v == widget.value) return;
    MonoTick.play(context, strong: v == widget.max);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final s = widget.size;
    final w = widget.max * s + (widget.max - 1) * 6;
    return MonoAdjustable(
      label: 'Rating',
      valueText:
          '${widget.value} of ${widget.max}${widget.labels != null && widget.value > 0 ? ', ${widget.labels![widget.value - 1]}' : ''}',
      onStep: (d) => _set(widget.value + d.sign),
      onHome: () => _set(1),
      onEnd: () => _set(widget.max),
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _pick(d.localPosition.dx, w),
          onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, w),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.max; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    _Star(
                      on: i < widget.value,
                      size: s,
                      color: t.ink,
                      replay:
                          i < widget.value &&
                              (i >= _prev || i == widget.value - 1)
                          ? widget.value
                          : null,
                      delay: Duration(
                        milliseconds: math.max(0, i - _prev) * 45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pick(double dx, double w) {
    var f = dx / w;
    if (Directionality.of(context) == TextDirection.rtl) f = 1 - f;
    _set((f * widget.max).floor() + 1);
  }
}

class _Star extends StatefulWidget {
  const _Star({
    required this.on,
    required this.size,
    required this.color,
    required this.replay,
    required this.delay,
  });
  final bool on;
  final double size;
  final Color color;
  final Object? replay;
  final Duration delay;

  @override
  State<_Star> createState() => _StarState();
}

class _StarState extends State<_Star> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );

  @override
  void didUpdateWidget(_Star old) {
    super.didUpdateWidget(old);
    if (widget.replay != null && widget.replay != old.replay) {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      final v = _c.value;
      final (sc, rot) = v < 0.5
          ? (
              0.6 + 0.6 * Curves.easeOut.transform(v * 2),
              -20 + 26 * Curves.easeOut.transform(v * 2),
            )
          : (
              1.2 - 0.2 * Curves.easeOut.transform((v - 0.5) * 2),
              6 - 6 * Curves.easeOut.transform((v - 0.5) * 2),
            );
      return Transform.rotate(
        angle: rot * math.pi / 180,
        child: Transform.scale(
          scale: sc,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _StarPainter(widget.on, widget.color),
          ),
        ),
      );
    },
  );
}

class _StarPainter extends CustomPainter {
  _StarPainter(this.on, this.color);
  final bool on;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _star(size.width / 24);
    if (on) canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 * size.width / 24
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.on != on || old.color != color;
}

// ───────────────────────── Tags ─────────────────────────

/// Toggleable chips (feedback reasons, filters, interests). Chips cascade
/// in when the tag list changes.
class MonoTagPicker extends StatelessWidget {
  /// Creates a tag picker.
  const MonoTagPicker({
    super.key,
    required this.tags,
    required this.selected,
    required this.onChanged,
    this.alignment = WrapAlignment.center,
  });

  /// Tags.
  final List<String> tags;

  /// Selected tags.
  final Set<String> selected;

  /// Called with the new selection.
  final ValueChanged<Set<String>> onChanged;

  /// Wrap alignment.
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return Wrap(
      key: ValueKey(Object.hashAll(tags)),
      alignment: alignment,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < tags.length; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + i * 35),
            curve: Interval(i * 35 / (300 + i * 35), 1, curve: monoBounce),
            builder: (context, v, child) => Opacity(
              opacity: v.clamp(0, 1),
              child: Transform.scale(scale: 0.85 + 0.15 * v, child: child),
            ),
            child: MonoPop(
              trigger: selected.contains(tags[i]),
              child: MonoPressable(
                selected: selected.contains(tags[i]),
                semanticLabel: tags[i],
                onTap: () {
                  MonoTick.play(context);
                  final next = {...selected};
                  next.contains(tags[i])
                      ? next.remove(tags[i])
                      : next.add(tags[i]);
                  onChanged(next);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected.contains(tags[i]) ? t.ink : t.soft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected.contains(tags[i]) ? t.ink : t.line,
                    ),
                  ),
                  child: Text(
                    tags[i],
                    style: t.text(
                      size: 12.5,
                      color: selected.contains(tags[i]) ? t.onInk : t.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── Mood ─────────────────────────

/// A face that morphs from awful to great as you slide. Snaps to the
/// nearest of five moods on release.
class MonoMoodPicker extends StatefulWidget {
  /// Creates a mood picker. [value] is 0 (worst) … 4 (best).
  const MonoMoodPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.labels = const ['Awful', 'Bad', 'Okay', 'Good', 'Great'],
    this.faceSize = 150,
  });

  /// Mood index, 0..4.
  final int value;

  /// Called with the new mood.
  final ValueChanged<int> onChanged;

  /// Five labels.
  final List<String> labels;

  /// Face diameter.
  final double faceSize;

  @override
  State<MonoMoodPicker> createState() => _MonoMoodPickerState();
}

class _MonoMoodPickerState extends State<MonoMoodPicker>
    with SingleTickerProviderStateMixin {
  late final MonoSmoother _s = MonoSmoother(
    vsync: this,
    value: widget.value.toDouble(),
    tau: 90,
    onChanged: (_) => setState(() {}),
  );
  bool _drag = false;
  int _bump = 0;

  @override
  void didUpdateWidget(MonoMoodPicker old) {
    super.didUpdateWidget(old);
    if (!_drag && old.value != widget.value) {
      _s.animateTo(widget.value.toDouble());
    }
  }

  @override
  void dispose() {
    _s.dispose();
    super.dispose();
  }

  void _fromX(double x, double w) {
    var f = (x / w).clamp(0.0, 1.0);
    if (Directionality.of(context) == TextDirection.rtl) f = 1 - f;
    final shown = f * 4;
    _s.jump(shown);
    final idx = shown.round();
    if (idx != widget.value) {
      MonoTick.play(context, strong: idx == 4);
      widget.onChanged(idx);
    }
  }

  void _release() {
    setState(() {
      _drag = false;
      _bump++;
    });
    _s.animateTo(widget.value.toDouble());
  }

  void _step(int d) {
    final v = (widget.value + d.sign).clamp(0, 4);
    if (v == widget.value) return;
    MonoTick.play(context, strong: v == 4);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final shown = _s.shown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MonoPop(
          trigger: _bump,
          child: Center(
            child: CustomPaint(
              size: Size.square(widget.faceSize),
              painter: _FacePainter(shown / 4, t.ink),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: MonoSwapText(
            widget.labels[widget.value],
            style: t.text(size: 22, weight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),
        MonoAdjustable(
          label: 'Mood',
          radius: 999,
          valueText: widget.labels[widget.value],
          onStep: _step,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final rtl = Directionality.of(context) == TextDirection.rtl;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _fromX(d.localPosition.dx, w),
                onTapUp: (_) => _release(),
                onHorizontalDragStart: (d) {
                  setState(() => _drag = true);
                  _fromX(d.localPosition.dx, w);
                },
                onHorizontalDragUpdate: (d) => _fromX(d.localPosition.dx, w),
                onHorizontalDragEnd: (_) => _release(),
                child: SizedBox(
                  height: 28,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 11,
                        height: 6,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < 4; i++) ...[
                              if (i > 0) const SizedBox(width: 3),
                              Expanded(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: t.ink.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Positioned(
                        left: (rtl ? 1 - shown / 4 : shown / 4) * w - 12,
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
        SizedBox(
          height: 16,
          child: LayoutBuilder(
            builder: (context, c) {
              final rtl = Directionality.of(context) == TextDirection.rtl;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < 5; i++)
                    Positioned(
                      left: (rtl ? 1 - i / 4 : i / 4) * c.maxWidth,
                      top: 0,
                      child: FractionalTranslation(
                        translation: Offset(
                          i == 0
                              ? (rtl ? -1 : 0)
                              : i == 4
                              ? (rtl ? 0 : -1)
                              : -0.5,
                          0,
                        ),
                        child: Text(
                          widget.labels[i],
                          style: t.text(
                            size: 11,
                            weight: i == widget.value
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: i == widget.value ? t.ink : t.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FacePainter extends CustomPainter {
  _FacePainter(this.t, this.ink);
  final double t;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(size.width / 140);
    canvas.drawCircle(
      Offset.zero,
      62,
      Paint()..color = ink.withValues(alpha: 0.06),
    );
    canvas.drawCircle(
      Offset.zero,
      62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ink,
    );
    final sad = math.max(0.0, 0.5 - t) * 2;
    final ry = 6.5 - 3 * t * t;
    for (final x in [-21.0, 21.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, -12), width: 11, height: ry * 2),
        Paint()..color = ink,
      );
    }
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = ink.withValues(alpha: 0.35 + 0.65 * sad);
    final by = -30 - 3 * t;
    canvas.drawLine(
      Offset(-31, by + sad * 2),
      Offset(-13, by - sad * 7),
      stroke,
    );
    canvas.drawLine(Offset(31, by + sad * 2), Offset(13, by - sad * 7), stroke);
    final w = 18 + 8 * t, cy = 24 - 12 * (t - 0.5), qy = 24 + 44 * (t - 0.5);
    canvas.drawPath(
      Path()
        ..moveTo(-w, cy)
        ..quadraticBezierTo(0, qy, w, cy),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5
        ..color = ink,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.t != t || old.ink != ink;
}

// ───────────────────────── Habits ─────────────────────────

/// A habit row for [MonoHabitCheck].
@immutable
class MonoHabit {
  /// Creates a habit. [days] holds the last 7 days, oldest first (index 6
  /// is today).
  const MonoHabit({
    required this.title,
    required this.icon,
    required this.days,
    this.streakBonus = 0,
  });

  /// Name.
  final String title;

  /// Icon.
  final IconData icon;

  /// Completion for the last seven days.
  final List<bool> days;

  /// Days added to the visible streak once it spans the whole week (for
  /// streaks that started earlier).
  final int streakBonus;

  /// Current streak, counting back from today (or yesterday if today is
  /// not done yet).
  int get streak {
    var i = days[6] ? 6 : 5;
    var n = 0;
    while (i >= 0 && days[i]) {
      n++;
      i--;
    }
    return n + (n >= 6 ? streakBonus : 0);
  }
}

/// Habit rows with a seven-day check grid and a live streak counter.
class MonoHabitCheck extends StatefulWidget {
  /// Creates a habit check list.
  MonoHabitCheck({
    super.key,
    required this.habits,
    required this.onChanged,
    DateTime? today,
  }) : today = today ?? DateTime.now();

  /// Habits.
  final List<MonoHabit> habits;

  /// Called when a day is toggled.
  final void Function(int habit, int day, bool done) onChanged;

  /// The last day shown.
  final DateTime today;

  @override
  State<MonoHabitCheck> createState() => _MonoHabitCheckState();
}

class _MonoHabitCheckState extends State<MonoHabitCheck> {
  final Map<String, int> _pops = {};

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    const narrow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(
          widget.today.year,
          widget.today.month,
          widget.today.day - 6 + i,
        ),
    ];
    return Column(
      children: [
        for (var h = 0; h < widget.habits.length; h++) ...[
          if (h > 0) const SizedBox(height: 10),
          () {
            final habit = widget.habits[h];
            final done = habit.days[6];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: t.soft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: t.line),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoPop(
                    trigger: _pops['$h:icon'],
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: done ? t.ink : t.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: done ? t.ink : t.line),
                      ),
                      child: Icon(
                        habit.icon,
                        size: 21,
                        color: done ? t.onInk : t.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                habit.title,
                                style: t.text(
                                  size: 14,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.local_fire_department_outlined,
                              size: 14,
                              color: t.muted,
                            ),
                            const SizedBox(width: 3),
                            MonoOdometer(
                              '${habit.streak}',
                              style: t.text(
                                size: 12,
                                weight: FontWeight.w600,
                                color: t.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            for (var d = 0; d < 7; d++) ...[
                              if (d > 0) const SizedBox(width: 4),
                              Expanded(
                                child: MonoPop(
                                  trigger: _pops['$h:$d'],
                                  child: Semantics(
                                    toggled: habit.days[d],
                                    label:
                                        '${habit.title}, ${d == 6 ? 'today' : '${6 - d} days ago'}',
                                    excludeSemantics: true,
                                    child: MonoPressable(
                                      onTap: () {
                                        setState(() {
                                          _pops['$h:$d'] =
                                              (_pops['$h:$d'] ?? 0) + 1;
                                          if (d == 6 && !habit.days[6]) {
                                            _pops['$h:icon'] =
                                                (_pops['$h:icon'] ?? 0) + 1;
                                          }
                                        });
                                        MonoTick.play(context, strong: d == 6);
                                        widget.onChanged(h, d, !habit.days[d]);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: habit.days[d] ? t.ink : null,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: habit.days[d]
                                                ? t.ink
                                                : t.line,
                                          ),
                                          boxShadow: d == 6
                                              ? [
                                                  BoxShadow(
                                                    color: t.ink,
                                                    spreadRadius: 1.5,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          narrow[days[d].weekday - 1],
                                          style: t.text(
                                            size: 10,
                                            weight: FontWeight.w600,
                                            color: habit.days[d]
                                                ? t.onInk
                                                : t.muted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }(),
        ],
      ],
    );
  }
}

// ───────────────────────── Count (water glasses) ─────────────────────────

/// A row of glasses that fill with a wave (water, servings, reps). Tap a
/// glass to fill up to it; tap the last filled one to empty it.
class MonoCountPicker extends StatefulWidget {
  /// Creates a count picker.
  const MonoCountPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.goal = 8,
    this.showProgress = true,
  });

  /// Filled count.
  final int value;

  /// Called with the new count.
  final ValueChanged<int> onChanged;

  /// Number of glasses.
  final int goal;

  /// Whether to show a progress bar.
  final bool showProgress;

  @override
  State<MonoCountPicker> createState() => _MonoCountPickerState();
}

class _MonoCountPickerState extends State<MonoCountPicker> {
  late int _prev = widget.value;
  int? _popped;
  int _pop = 0;

  @override
  void didUpdateWidget(MonoCountPicker old) {
    super.didUpdateWidget(old);
    _prev = old.value;
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final v = widget.value;
    final origin = v > _prev ? _prev : v;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < widget.goal; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  toggled: i < v,
                  label: 'Glass ${i + 1}',
                  excludeSemantics: true,
                  child: MonoPressable(
                    onTap: () {
                      final nv = v == i + 1 ? i : i + 1;
                      setState(() {
                        _popped = i;
                        _pop++;
                      });
                      MonoTick.play(context, strong: nv == widget.goal);
                      widget.onChanged(nv);
                    },
                    child: MonoPop(
                      trigger: _popped == i ? _pop : null,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: i < v ? 1 : 0),
                          duration: Duration(
                            milliseconds: 700 + (i - origin).abs() * 45,
                          ),
                          curve: Interval(
                            ((i - origin).abs() * 45) /
                                (700 + (i - origin).abs() * 45),
                            1,
                            curve: monoSpring,
                          ),
                          builder: (context, level, _) =>
                              CustomPaint(painter: _GlassPainter(level, t.ink)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (widget.showProgress) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Positioned.fill(child: ColoredBox(color: t.line)),
                  LayoutBuilder(
                    builder: (context, c) => AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: monoSpring,
                      width: c.maxWidth * (v / widget.goal).clamp(0, 1),
                      decoration: BoxDecoration(
                        color: t.ink,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter(this.level, this.ink);
  final double level;
  final Color ink;

  static Path _glass() => Path()
    ..moveTo(6, 4)
    ..lineTo(18, 4)
    ..lineTo(16.6, 18.6)
    ..quadraticBezierTo(16.5, 20.5, 14.6, 20.5)
    ..lineTo(9.4, 20.5)
    ..quadraticBezierTo(7.5, 20.5, 7.4, 18.6)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final g = _glass();
    canvas.save();
    canvas.clipPath(g);
    canvas.translate(0, 15 * (1 - level));
    final wave = Path()..moveTo(3, 9.5);
    for (var x = 3.0; x < 21; x += 4.5) {
      wave.quadraticBezierTo(x + 1.125, 8.6, x + 2.25, 9.5);
      wave.quadraticBezierTo(x + 3.375, 10.4, x + 4.5, 9.5);
    }
    wave
      ..lineTo(21, 24)
      ..lineTo(3, 24)
      ..close();
    canvas.drawPath(wave, Paint()..color = ink.withValues(alpha: 0.85));
    canvas.restore();
    canvas.drawPath(
      g,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = ink,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.level != level || old.ink != ink;
}

// ───────────────────────── Time of day ─────────────────────────

/// A part of the day for [MonoTimeOfDayPicker].
@immutable
class MonoDayPart {
  /// Creates a day part. [angle] is the sun's position on the arc in
  /// degrees (180 = horizon left, 90 = top, 0 = horizon right).
  const MonoDayPart(this.label, this.angle, {this.night = false});

  /// Label.
  final String label;

  /// Arc angle in degrees.
  final double angle;

  /// Shows the moon and stars.
  final bool night;

  /// Morning, Midday, Evening, Night.
  static const defaults = [
    MonoDayPart('Morning', 155),
    MonoDayPart('Midday', 90),
    MonoDayPart('Evening', 25),
    MonoDayPart('Night', 90, night: true),
  ];
}

/// A sun that springs along an arc (or turns into the moon at night).
class MonoTimeOfDayPicker extends StatefulWidget {
  /// Creates a time-of-day picker.
  const MonoTimeOfDayPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.parts = MonoDayPart.defaults,
  });

  /// Selected part index.
  final int value;

  /// Called with the new index.
  final ValueChanged<int> onChanged;

  /// Parts of the day.
  final List<MonoDayPart> parts;

  @override
  State<MonoTimeOfDayPicker> createState() => _MonoTimeOfDayPickerState();
}

class _MonoTimeOfDayPickerState extends State<MonoTimeOfDayPicker>
    with TickerProviderStateMixin {
  late final MonoSpring _a = MonoSpring(
    vsync: this,
    value: widget.parts[widget.value].angle,
    stiffness: 0.0006,
    damping: 0.045,
    onChanged: (_) => setState(() {}),
  );
  late final MonoSmoother _night = MonoSmoother(
    vsync: this,
    value: widget.parts[widget.value].night ? 1 : 0,
    tau: 140,
    epsilon: 0.003,
    onChanged: (_) => setState(() {}),
  );

  @override
  void didUpdateWidget(MonoTimeOfDayPicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _a.animateTo(widget.parts[widget.value].angle);
      _night.animateTo(widget.parts[widget.value].night ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _a.dispose();
    _night.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 2,
          child: CustomPaint(
            painter: _SkyPainter(_a.shown, _night.shown, t.ink),
          ),
        ),
        const SizedBox(height: 12),
        MonoSegmented<int>(
          options: [for (var i = 0; i < widget.parts.length; i++) i],
          value: widget.value,
          expand: true,
          labelBuilder: (i) => widget.parts[i].label,
          semanticLabel: 'Time of day',
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.angle, this.night, this.ink);
  final double angle, night;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300);
    const cx = 150.0, cy = 124.0, r = 104.0;
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = ink.withValues(alpha: 0.35);
    for (var a = 180.0; a >= 0; a -= 4.4) {
      final rad = a * math.pi / 180;
      final p = Offset(cx + r * math.cos(rad), cy - r * math.sin(rad));
      canvas.drawCircle(p, 0.75, Paint()..color = dash.color);
    }
    canvas.drawLine(
      const Offset(20, cy),
      const Offset(280, cy),
      dash..color = ink.withValues(alpha: 0.3),
    );
    if (night > 0.01) {
      final star = Paint()..color = ink.withValues(alpha: 0.7 * night);
      for (final (i, (x, y)) in const [
        (70.0, 40.0),
        (230.0, 52.0),
        (110.0, 22.0),
        (200.0, 28.0),
        (52.0, 78.0),
        (250.0, 92.0),
      ].indexed) {
        canvas.drawCircle(Offset(x, y), i.isOdd ? 1.6 : 1.2, star);
      }
    }
    final rad = angle * math.pi / 180;
    final c = Offset(cx + r * math.cos(rad), cy - r * math.sin(rad));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    if (night < 0.99) {
      canvas.save();
      canvas.rotate(angle * 2 * math.pi / 180);
      canvas.scale(1 - 0.3 * night);
      final sun = Paint()..color = ink.withValues(alpha: 1 - night);
      canvas.drawCircle(Offset.zero, 13, sun);
      final ray = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = sun.color;
      for (var k = 0; k < 8; k++) {
        final a = k * math.pi / 4;
        canvas.drawLine(
          Offset(math.cos(a) * 18, math.sin(a) * 18),
          Offset(math.cos(a) * 23, math.sin(a) * 23),
          ray,
        );
      }
      canvas.restore();
    }
    if (night > 0.01) {
      final moon = Path()
        ..addOval(Rect.fromCircle(center: Offset.zero, radius: 13));
      final bite = Path()
        ..addOval(Rect.fromCircle(center: const Offset(7, -6), radius: 10.5));
      canvas.drawPath(
        Path.combine(PathOperation.difference, moon, bite),
        Paint()..color = ink.withValues(alpha: night),
      );
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.angle != angle || old.night != night || old.ink != ink;
}
