import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/controls.dart';
import '../core/effects.dart';
import '../core/feedback.dart';
import '../core/odometer.dart';
import '../core/physics.dart';
import '../core/theme.dart';

// ───────────────────────── Goal tiles ─────────────────────────

/// An option shown as a tile in [MonoGoalPicker].
@immutable
class MonoTileOption<T> {
  /// Creates a tile option.
  const MonoTileOption({
    required this.value,
    required this.title,
    required this.icon,
    this.subtitle = '',
  });

  /// The value this tile selects.
  final T value;

  /// Title.
  final String title;

  /// One-line description.
  final String subtitle;

  /// Icon.
  final IconData icon;
}

/// A grid of selectable tiles; the chosen tile inverts and its icon pops.
class MonoGoalPicker<T> extends StatelessWidget {
  /// Creates a tile picker.
  const MonoGoalPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.columns = 2,
  });

  /// Tiles.
  final List<MonoTileOption<T>> options;

  /// Selected value.
  final T value;

  /// Called when another tile is chosen.
  final ValueChanged<T> onChanged;

  /// Number of columns.
  final int columns;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final rows = <Widget>[];
    for (var r = 0; r < options.length; r += columns) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: 8),
                Expanded(
                  child: r + c < options.length
                      ? _GoalTile(
                          option: options[r + c],
                          selected: options[r + c].value == value,
                          theme: t,
                          onTap: () {
                            if (options[r + c].value == value) return;
                            MonoTick.play(context, strong: true);
                            onChanged(options[r + c].value);
                          },
                        )
                      : const SizedBox(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Semantics(
      container: true,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _GoalTile<T> extends StatelessWidget {
  const _GoalTile({
    required this.option,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final MonoTileOption<T> option;
  final bool selected;
  final MonoPickerThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final fg = selected ? t.onInk : t.ink;
    return MonoPressable(
      scale: 0.97,
      selected: selected,
      semanticLabel: '${option.title}. ${option.subtitle}',
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? t.ink : t.soft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? t.ink : t.line),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SpinPop(
                  trigger: selected,
                  play: selected,
                  child: Icon(option.icon, size: 30, color: fg),
                ),
                const SizedBox(height: 14),
                Text(
                  option.title,
                  style: t.text(size: 14, weight: FontWeight.w600, color: fg),
                ),
                const SizedBox(height: 2),
                Text(
                  option.subtitle,
                  style: t.text(
                    size: 11.5,
                    height: 1.35,
                    color: selected ? t.onInk.withValues(alpha: 0.62) : t.muted,
                  ),
                ),
              ],
            ),
            PositionedDirectional(
              top: -4,
              end: -4,
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 380),
                curve: monoBounce,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: t.onInk,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded, size: 14, color: t.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Scale + rotate pop played when [trigger] changes and [play] is true.
class _SpinPop extends StatefulWidget {
  const _SpinPop({
    required this.trigger,
    required this.play,
    required this.child,
  });

  final Object? trigger;
  final bool play;
  final Widget child;

  @override
  State<_SpinPop> createState() => _SpinPopState();
}

class _SpinPopState extends State<_SpinPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    value: 1,
  );

  @override
  void didUpdateWidget(_SpinPop old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.play) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      final v = _c.value;
      final (s, r) = v < 0.5
          ? (
              0.6 + (1.15 - 0.6) * Curves.easeOut.transform(v * 2),
              -14 + 19 * Curves.easeOut.transform(v * 2),
            )
          : (
              1.15 - 0.15 * Curves.easeOut.transform((v - 0.5) * 2),
              5 - 5 * Curves.easeOut.transform((v - 0.5) * 2),
            );
      return Transform.rotate(
        angle: r * math.pi / 180,
        child: Transform.scale(scale: s, child: child),
      );
    },
    child: widget.child,
  );
}

// ───────────────────────── Level bars ─────────────────────────

/// Rising bars for picking a level (activity, intensity, difficulty).
/// Drag across the bars or tap one.
class MonoLevelPicker extends StatelessWidget {
  /// Creates a level picker.
  const MonoLevelPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.count = 5,
    this.labels,
    this.height = 150,
  });

  /// Selected level, `0..count-1`.
  final int value;

  /// Called with the new level.
  final ValueChanged<int> onChanged;

  /// Number of levels.
  final int count;

  /// Optional names for accessibility.
  final List<String>? labels;

  /// Height of the tallest bar area.
  final double height;

  void _set(BuildContext context, int i) {
    i = i.clamp(0, count - 1);
    if (i == value) return;
    MonoTick.play(context, strong: true);
    onChanged(i);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return MonoAdjustable(
      label: 'Level',
      valueText: labels?[value] ?? '${value + 1} of $count',
      onStep: (d) => _set(context, value + d),
      onHome: () => _set(context, 0),
      onEnd: () => _set(context, count - 1),
      child: LayoutBuilder(
        builder: (context, c) {
          void pick(Offset p) {
            var f = p.dx / c.maxWidth;
            if (Directionality.of(context) == TextDirection.rtl) f = 1 - f;
            _set(context, (f * count).floor());
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => pick(d.localPosition),
            onHorizontalDragUpdate: (d) => pick(d.localPosition),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SizedBox(
                height: height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < count; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: AnimatedScale(
                          scale: i == value ? 1.05 : 1,
                          alignment: Alignment.bottomCenter,
                          duration: const Duration(milliseconds: 500),
                          curve: monoBounce,
                          child: AnimatedContainer(
                            duration: Duration(
                              milliseconds: 350 + (i - value).abs() * 25,
                            ),
                            height:
                                height *
                                (0.28 + i * (0.72 / math.max(1, count - 1))),
                            decoration: BoxDecoration(
                              color: t.ink.withValues(
                                alpha: i == value
                                    ? 1
                                    : i < value
                                    ? 0.4
                                    : 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
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
        },
      ),
    );
  }
}

// ───────────────────────── Week days ─────────────────────────

/// Seven day toggles. Drag across days to paint a selection on or off.
/// Indices are 0 = Monday … 6 = Sunday.
class MonoWeekPicker extends StatefulWidget {
  /// Creates a week picker.
  const MonoWeekPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.labels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    this.semanticLabels = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ],
  });

  /// Selected day indices.
  final Set<int> selected;

  /// Called with the new selection.
  final ValueChanged<Set<int>> onChanged;

  /// Short labels.
  final List<String> labels;

  /// Full names for accessibility.
  final List<String> semanticLabels;

  @override
  State<MonoWeekPicker> createState() => _MonoWeekPickerState();
}

class _MonoWeekPickerState extends State<MonoWeekPicker> {
  bool? _mode;
  final Map<int, int> _pops = {};
  // Latest selection we reported; pointer events can arrive before the
  // parent rebuilds with it.
  late Set<int> _current = widget.selected;

  @override
  void didUpdateWidget(MonoWeekPicker old) {
    super.didUpdateWidget(old);
    _current = widget.selected;
  }

  void _apply(int i, bool on) {
    if (_current.contains(i) == on) return;
    final next = {..._current};
    on ? next.add(i) : next.remove(i);
    _pops[i] = (_pops[i] ?? 0) + 1;
    MonoTick.play(context);
    _current = next;
    widget.onChanged(next);
  }

  int _indexAt(Offset p, double w) {
    var f = p.dx / w;
    if (Directionality.of(context) == TextDirection.rtl) f = 1 - f;
    return (f * 7).floor().clamp(0, 6);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return LayoutBuilder(
      builder: (context, c) => Listener(
        onPointerDown: (e) {
          final i = _indexAt(e.localPosition, c.maxWidth);
          _mode = !_current.contains(i);
          _apply(i, _mode!);
        },
        onPointerMove: (e) {
          if (_mode != null) {
            _apply(_indexAt(e.localPosition, c.maxWidth), _mode!);
          }
        },
        onPointerUp: (_) => _mode = null,
        onPointerCancel: (_) => _mode = null,
        child: Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Center(
                  child: Semantics(
                    toggled: widget.selected.contains(i),
                    label: widget.semanticLabels[i],
                    onTap: () => _apply(i, !widget.selected.contains(i)),
                    child: MonoPop(
                      trigger: _pops[i] ?? 0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 48),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.selected.contains(i)
                                  ? t.ink
                                  : t.soft,
                              border: Border.all(
                                color: widget.selected.contains(i)
                                    ? t.ink
                                    : t.line,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              widget.labels[i],
                              style: t.text(
                                size: 13,
                                weight: FontWeight.w600,
                                color: widget.selected.contains(i)
                                    ? t.onInk
                                    : t.muted,
                              ),
                            ),
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
      ),
    );
  }
}

// ───────────────────────── Dial ─────────────────────────

String _mmss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// A 270° dial for durations with a spring-loaded needle (rest timers,
/// cooking, focus sessions).
class MonoDialPicker extends StatefulWidget {
  /// Creates a dial picker.
  const MonoDialPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = const Duration(minutes: 5),
    this.step = const Duration(seconds: 15),
    this.majorStep = const Duration(minutes: 1),
    this.caption = 'rest',
    this.showStepButtons = true,
    this.size = 280,
  });

  /// Selected duration.
  final Duration value;

  /// Called with the new duration.
  final ValueChanged<Duration> onChanged;

  /// Maximum.
  final Duration max;

  /// Snap step.
  final Duration step;

  /// Long tick interval.
  final Duration majorStep;

  /// Small caption under the time.
  final String caption;

  /// Whether to show "− 15s / + 15s" buttons.
  final bool showStepButtons;

  /// Maximum diameter.
  final double size;

  @override
  State<MonoDialPicker> createState() => _MonoDialPickerState();
}

class _MonoDialPickerState extends State<MonoDialPicker>
    with SingleTickerProviderStateMixin {
  late final MonoSpring _spring = MonoSpring(
    vsync: this,
    value: widget.value.inSeconds.toDouble(),
    onChanged: (_) => setState(() {}),
  );

  int get _max => widget.max.inSeconds;
  int get _stepS => widget.step.inSeconds;

  @override
  void didUpdateWidget(MonoDialPicker old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      _spring.animateTo(widget.value.inSeconds.toDouble());
    }
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  void _set(double s) {
    final v = ((s / _stepS).round() * _stepS).clamp(0, _max);
    if (v == widget.value.inSeconds) return;
    MonoTick.play(context, strong: v % widget.majorStep.inSeconds == 0);
    widget.onChanged(Duration(seconds: v));
  }

  void _fromPointer(Offset p, double side, bool drag) {
    const c = 130.0, a0 = 135.0, sw = 270.0;
    final x = p.dx / side * 260, y = p.dy / side * 260;
    var rel = ((math.atan2(y - c, x - c) * 180 / math.pi) - a0 + 720) % 360;
    if (rel > sw) rel = rel > sw + (360 - sw) / 2 ? 0 : sw;
    final v = rel / sw * _max;
    if (drag && (v - widget.value.inSeconds).abs() > _max / 2) return;
    _set(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final dial = LayoutBuilder(
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
                    final dy = (ev as PointerScrollEvent).scrollDelta.dy;
                    _set(
                      widget.value.inSeconds +
                          (dy < 0 ? _stepS : -_stepS).toDouble(),
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
                      painter: _DialPainter(
                        shown: _spring.shown,
                        max: _max,
                        step: _stepS,
                        major: widget.majorStep.inSeconds,
                        ink: t.ink,
                        surface: t.surface,
                        label: t.text(
                          size: 11,
                          color: t.ink.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MonoOdometer(
                            _mmss(widget.value.inSeconds),
                            style: t.text(
                              size: 46 * side / 280,
                              weight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.caption.toUpperCase(),
                            style: t.text(
                              size: 12,
                              color: t.muted,
                              letterSpacing: 0.7,
                            ),
                          ),
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
    );
    return Column(
      children: [
        MonoAdjustable(
          label: widget.caption,
          radius: 999,
          valueText: _mmss(widget.value.inSeconds),
          onStep: (d) => _set(
            widget.value.inSeconds +
                d.sign *
                    (d.abs() >= 10 ? widget.majorStep.inSeconds : _stepS)
                        .toDouble(),
          ),
          child: dial,
        ),
        if (widget.showStepButtons) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pill(
                t,
                '− ${_stepS}s',
                () => _set((widget.value.inSeconds - _stepS).toDouble()),
              ),
              const SizedBox(width: 10),
              _pill(
                t,
                '+ ${_stepS}s',
                () => _set((widget.value.inSeconds + _stepS).toDouble()),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _pill(MonoPickerThemeData t, String text, VoidCallback onTap) =>
      MonoPressable(
        onTap: onTap,
        semanticLabel: text,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: t.soft,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.line),
          ),
          child: Text(text, style: t.text(size: 12, weight: FontWeight.w600)),
        ),
      );
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.shown,
    required this.max,
    required this.step,
    required this.major,
    required this.ink,
    required this.surface,
    required this.label,
  });

  final double shown;
  final int max, step, major;
  final Color ink, surface;
  final TextStyle label;

  static const c = 130.0, r = 96.0, a0 = 135.0, sw = 270.0;
  static Offset _pt(double deg, double rad) => Offset(
    c + rad * math.cos(deg * math.pi / 180),
    c + rad * math.sin(deg * math.pi / 180),
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 260);
    final line = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    for (var s = 0; s <= max; s += step) {
      final maj = s % major == 0;
      final a = a0 + sw * s / max;
      line.color = ink.withValues(alpha: maj ? 0.7 : 0.25);
      canvas.drawLine(_pt(a, r + 15), _pt(a, r + (maj ? 24 : 19)), line);
    }
    final rect = Rect.fromCircle(center: const Offset(c, c), radius: r);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    arc.color = ink.withValues(alpha: 0.08);
    canvas.drawArc(rect, a0 * math.pi / 180, sw * math.pi / 180, false, arc);
    final f = (shown / max).clamp(0.0, 1.0);
    if (f > 0.001) {
      arc.color = ink;
      canvas.drawArc(
        rect,
        a0 * math.pi / 180,
        sw * f * math.pi / 180,
        false,
        arc,
      );
    }
    final k = _pt(a0 + sw * f, r);
    canvas.drawCircle(k, 11, Paint()..color = surface);
    canvas.drawCircle(
      k,
      11,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ink,
    );
    for (final (text, frac) in [('0:00', 0.0), (_mmss(max), 1.0)]) {
      final p = _pt(a0 + sw * frac, r);
      final tp = TextPainter(
        text: TextSpan(text: text, style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy + 30 - tp.height + 2));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.shown != shown || old.ink != ink || old.max != max;
}

// ───────────────────────── Big stepper ─────────────────────────

/// A large stepper with rolling digits. Press and hold to accelerate;
/// shakes when a limit is reached.
class MonoStepper extends StatefulWidget {
  /// Creates a stepper.
  const MonoStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.fontSize = 68,
  });

  /// Small caption above the number.
  final String label;

  /// Current value.
  final int value;

  /// Called with the new value.
  final ValueChanged<int> onChanged;

  /// Minimum.
  final int min;

  /// Maximum.
  final int max;

  /// Number size.
  final double fontSize;

  @override
  State<MonoStepper> createState() => _MonoStepperState();
}

class _MonoStepperState extends State<MonoStepper> {
  Timer? _timer;
  int _shake = 0;
  late int _v = widget.value;
  int? _pressed;

  @override
  void didUpdateWidget(MonoStepper old) {
    super.didUpdateWidget(old);
    _v = widget.value;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _bump(int d) {
    final n = _v + d;
    if (n < widget.min || n > widget.max) {
      setState(() => _shake++);
      return false;
    }
    _v = n;
    MonoTick.play(context);
    widget.onChanged(n);
    return true;
  }

  void _start(int d) {
    setState(() => _pressed = d);
    if (!_bump(d)) return;
    var delay = 380.0;
    void rep() {
      if (!_bump(d)) return;
      delay = math.max(45, delay * 0.78);
      _timer = Timer(Duration(milliseconds: delay.round()), rep);
    }

    _timer = Timer(Duration(milliseconds: delay.round()), rep);
  }

  void _stop() {
    _timer?.cancel();
    if (_pressed != null) setState(() => _pressed = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    Widget btn(int d, IconData icon, String a11y) {
      final on = _pressed == d;
      return Semantics(
        button: true,
        label: a11y,
        onTap: () => _bump(d),
        child: GestureDetector(
          onTapDown: (_) => _start(d),
          onTapUp: (_) => _stop(),
          onTapCancel: _stop,
          child: AnimatedScale(
            scale: on ? 0.88 : 1,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? t.ink : t.soft,
                border: Border.all(color: t.line),
              ),
              child: Icon(icon, size: 18, color: on ? t.onInk : t.ink),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: widget.label,
      value: '${widget.value}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: t.text(size: 11, color: t.muted, letterSpacing: 0.9),
          ),
          const SizedBox(height: 12),
          MonoShake(
            trigger: _shake,
            child: MonoOdometer(
              '${widget.value}',
              style: t.text(size: widget.fontSize, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              btn(-1, Icons.remove_rounded, 'Decrease ${widget.label}'),
              const SizedBox(width: 8),
              btn(1, Icons.add_rounded, 'Increase ${widget.label}'),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Effort segments ─────────────────────────

/// Ten rising segments for effort / RPE / intensity. Drag across or tap.
class MonoEffortPicker extends StatelessWidget {
  /// Creates an effort picker.
  const MonoEffortPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.count = 10,
    this.height = 64,
    this.showScale = true,
  });

  /// Selected value, `1..count`.
  final int value;

  /// Called with the new value.
  final ValueChanged<int> onChanged;

  /// Number of segments.
  final int count;

  /// Segment height.
  final double height;

  /// Whether to show numbers under the segments.
  final bool showScale;

  void _set(BuildContext context, int v) {
    v = v.clamp(1, count);
    if (v == value) return;
    MonoTick.play(context, strong: v >= count - 1);
    onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return Column(
      children: [
        MonoAdjustable(
          label: 'Effort',
          valueText: '$value of $count',
          onStep: (d) => _set(context, value + d),
          onHome: () => _set(context, 1),
          onEnd: () => _set(context, count),
          child: LayoutBuilder(
            builder: (context, c) {
              void pick(Offset p) {
                var f = p.dx / c.maxWidth;
                if (Directionality.of(context) == TextDirection.rtl) f = 1 - f;
                _set(context, (f * count).floor() + 1);
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => pick(d.localPosition),
                onHorizontalDragUpdate: (d) => pick(d.localPosition),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: SizedBox(
                    height: height,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < count; i++) ...[
                          if (i > 0) const SizedBox(width: 5),
                          Expanded(
                            child: AnimatedScale(
                              scale: i == value - 1 ? 1.12 : 1,
                              alignment: Alignment.bottomCenter,
                              duration: const Duration(milliseconds: 450),
                              curve: monoBounce,
                              child: AnimatedContainer(
                                duration: Duration(
                                  milliseconds: 300 + (i - value).abs() * 18,
                                ),
                                decoration: BoxDecoration(
                                  color: t.ink.withValues(
                                    alpha: i < value
                                        ? 0.3 + 0.7 * i / math.max(1, count - 1)
                                        : 0.09,
                                  ),
                                  borderRadius: BorderRadius.circular(9),
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
            },
          ),
        ),
        if (showScale) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${i + 1}',
                    textAlign: TextAlign.center,
                    style: t.text(size: 10, color: t.muted),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
