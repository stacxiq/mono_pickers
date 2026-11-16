import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';

/// Drag + momentum + snap in "index" units, shared by the ruler, height and
/// drum pickers.
///
/// Drags past the ends rubber-band. A fast release flings with exponential
/// decay and lands exactly on an index.
class MonoIndexScroller {
  /// Creates a scroller over indices `0..maxIndex`.
  MonoIndexScroller({
    required TickerProvider vsync,
    required this.maxIndex,
    required double position,
    required this.onPosition,
    required this.onIndex,
  }) : _pos = position,
       _last = position.round() {
    _ticker = vsync.createTicker(_tick);
  }

  /// Largest index.
  int maxIndex;

  /// Called on every position change (for repainting).
  final void Function(double position) onPosition;

  /// Called when the nearest index changes.
  final void Function(int index) onIndex;

  late final Ticker _ticker;
  double _pos;
  int _last;
  double _from = 0, _target = 0, _tau = 120;
  bool _animating = false;
  bool _dragging = false;
  final List<(int, double)> _samples = [];
  Timer? _wheelTimer;

  /// Current (fractional) position.
  double get position => _pos;

  /// The index the scroller is at or heading to.
  int get index => (_animating ? _target : _pos).round().clamp(0, maxIndex);

  /// Whether the user is dragging.
  bool get isDragging => _dragging;

  void _emit() {
    final i = _pos.round().clamp(0, maxIndex);
    if (i != _last) {
      _last = i;
      onIndex(i);
    }
    onPosition(_pos);
  }

  void _tick(Duration elapsed) {
    final e = math.exp(-elapsed.inMicroseconds / 1000 / _tau);
    _pos = _target + (_from - _target) * e;
    if ((_pos - _target).abs() < 0.002) {
      _pos = _target;
      _animating = false;
      _ticker.stop();
    }
    _emit();
  }

  /// Jumps to [index] without animation or callbacks to [onIndex].
  void jump(double index) {
    _stop();
    _pos = index;
    _last = index.round();
    onPosition(_pos);
  }

  /// Animates to [index] with time constant [tau] (ms).
  void animateTo(double index, {double tau = 120}) {
    _stop();
    _from = _pos;
    _target = index.clamp(0, maxIndex.toDouble()).roundToDouble();
    _tau = tau;
    _animating = true;
    _ticker.start();
  }

  void _stop() {
    if (_ticker.isActive) _ticker.stop();
    _animating = false;
  }

  /// Starts a drag.
  void dragStart() {
    _stop();
    _dragging = true;
    _samples
      ..clear()
      ..add((_now, _pos));
  }

  static int get _now => DateTime.now().microsecondsSinceEpoch;

  /// Moves by [deltaIndex] (positive = higher index).
  void dragBy(double deltaIndex) {
    if (_pos < 0 || _pos > maxIndex) deltaIndex *= 0.35;
    _pos += deltaIndex;
    final now = _now;
    _samples.add((now, _pos));
    while (_samples.length > 2 && now - _samples.first.$1 > 100000) {
      _samples.removeAt(0);
    }
    _emit();
  }

  /// Ends a drag, flinging when released fast.
  void dragEnd() {
    if (!_dragging) return;
    _dragging = false;
    final now = _now;
    final (t0, p0) = _samples.isEmpty ? (now, _pos) : _samples.first;
    final dtMs = (now - t0) / 1000;
    final v = dtMs > 8 ? (_pos - p0) / dtMs : 0.0;
    final fast = v.abs() > 0.003;
    animateTo(_pos + (fast ? v * 325 : 0), tau: fast ? 325 : 110);
  }

  /// Scrolls by [deltaIndex] from a mouse wheel and snaps shortly after.
  void wheel(double deltaIndex) {
    _stop();
    _pos = (_pos + deltaIndex).clamp(-0.4, maxIndex + 0.4);
    _emit();
    _wheelTimer?.cancel();
    _wheelTimer = Timer(
      const Duration(milliseconds: 110),
      () => animateTo(_pos, tau: 110),
    );
  }

  /// Releases resources.
  void dispose() {
    _wheelTimer?.cancel();
    _ticker.dispose();
  }
}

/// A critically-damped-ish spring used by dials and needles.
class MonoSpring {
  /// Creates a spring.
  MonoSpring({
    required TickerProvider vsync,
    required double value,
    required this.onChanged,
    this.stiffness = 0.0009,
    this.damping = 0.05,
    this.epsilon = 0.05,
  }) : _shown = value,
       _target = value {
    _ticker = vsync.createTicker(_tick);
  }

  /// Called with the displayed value on every frame.
  final void Function(double shown) onChanged;

  /// Spring constant (per ms²).
  final double stiffness;

  /// Damping (per ms).
  final double damping;

  /// Settling threshold.
  final double epsilon;

  late final Ticker _ticker;
  double _shown, _target, _vel = 0;
  Duration _lastT = Duration.zero;

  /// Value currently drawn.
  double get shown => _shown;

  /// Target value.
  double get target => _target;

  /// Springs to [value].
  void animateTo(double value) {
    _target = value;
    if (!_ticker.isActive) {
      _lastT = Duration.zero;
      _ticker.start();
    }
  }

  /// Jumps to [value].
  void jump(double value) {
    if (_ticker.isActive) _ticker.stop();
    _shown = _target = value;
    _vel = 0;
    onChanged(_shown);
  }

  void _tick(Duration t) {
    final dt = math.min(32.0, (t - _lastT).inMicroseconds / 1000);
    _lastT = t;
    for (var k = 0.0; k < dt; k += 4) {
      final h = math.min(4.0, dt - k);
      _vel += (stiffness * (_target - _shown) - damping * _vel) * h;
      _shown += _vel * h;
    }
    if ((_target - _shown).abs() < epsilon && _vel.abs() < epsilon / 50) {
      _shown = _target;
      _vel = 0;
      _ticker.stop();
    }
    onChanged(_shown);
  }

  /// Releases resources.
  void dispose() => _ticker.dispose();
}

/// Exponential smoothing toward a target (used for morphing shapes).
class MonoSmoother {
  /// Creates a smoother with time constant [tau] (ms).
  MonoSmoother({
    required TickerProvider vsync,
    required double value,
    required this.onChanged,
    this.tau = 110,
    this.epsilon = 0.002,
  }) : _shown = value,
       _target = value {
    _ticker = vsync.createTicker(_tick);
  }

  /// Called each frame.
  final void Function(double shown) onChanged;

  /// Time constant (ms).
  final double tau;

  /// Settling threshold.
  final double epsilon;

  late final Ticker _ticker;
  double _shown, _target;
  Duration _lastT = Duration.zero;

  /// Current value.
  double get shown => _shown;

  /// Smooths to [value].
  void animateTo(double value) {
    _target = value;
    if (!_ticker.isActive) {
      _lastT = Duration.zero;
      _ticker.start();
    }
  }

  /// Jumps to [value].
  void jump(double value) {
    if (_ticker.isActive) _ticker.stop();
    _shown = _target = value;
    onChanged(_shown);
  }

  void _tick(Duration t) {
    final dt = math.min(32.0, (t - _lastT).inMicroseconds / 1000);
    _lastT = t;
    _shown += (_target - _shown) * (1 - math.exp(-dt / tau));
    if ((_target - _shown).abs() < epsilon) {
      _shown = _target;
      _ticker.stop();
    }
    onChanged(_shown);
  }

  /// Releases resources.
  void dispose() => _ticker.dispose();
}
