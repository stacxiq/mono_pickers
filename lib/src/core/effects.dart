import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Plays a springy "pop" (scale 0.8 → 1.1 → 1) whenever [trigger] changes.
class MonoPop extends StatefulWidget {
  /// Creates a pop wrapper.
  const MonoPop({super.key, required this.trigger, required this.child});

  /// Any value; the pop plays when it changes.
  final Object? trigger;

  /// The widget to pop.
  final Widget child;

  @override
  State<MonoPop> createState() => _MonoPopState();
}

class _MonoPopState extends State<MonoPop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    value: 1,
  );
  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.8, end: 1.1).chain(CurveTween(curve: monoEase)),
      weight: 45,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.1,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 55,
    ),
  ]);

  @override
  void didUpdateWidget(MonoPop old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _c.drive(_scale), child: widget.child);
}

/// Shakes horizontally whenever [trigger] changes (used for "limit reached").
class MonoShake extends StatefulWidget {
  /// Creates a shake wrapper.
  const MonoShake({super.key, required this.trigger, required this.child});

  /// Any value; the shake plays when it changes.
  final Object? trigger;

  /// The widget to shake.
  final Widget child;

  @override
  State<MonoShake> createState() => _MonoShakeState();
}

class _MonoShakeState extends State<MonoShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );

  @override
  void didUpdateWidget(MonoShake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
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
      final t = _c.value;
      final dx = t >= 1
          ? 0.0
          : (1 - t) *
                5 *
                (t < 0.25
                    ? -1
                    : t < 0.5
                    ? 0.8
                    : t < 0.75
                    ? -0.4
                    : 0.1);
      return Transform.translate(offset: Offset(dx, 0), child: child);
    },
    child: widget.child,
  );
}

/// Cross-fades and slides text upward whenever it changes.
class MonoSwapText extends StatelessWidget {
  /// Creates swapping text.
  const MonoSwapText(this.text, {super.key, this.style, this.textAlign});

  /// The text.
  final String text;

  /// Style.
  final TextStyle? style;

  /// Alignment.
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 320),
    switchInCurve: monoEase,
    switchOutCurve: Curves.easeIn,
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.centerLeft,
      children: [...previous, ?current],
    ),
    transitionBuilder: (child, anim) => FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    ),
    child: Text(text, key: ValueKey(text), style: style, textAlign: textAlign),
  );
}

/// Scales its child down while pressed.
class MonoPressable extends StatefulWidget {
  /// Creates a pressable.
  const MonoPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.94,
    this.semanticLabel,
    this.selected,
  });

  /// Content.
  final Widget child;

  /// Tap handler; null disables.
  final VoidCallback? onTap;

  /// Scale while pressed.
  final double scale;

  /// Accessibility label.
  final String? semanticLabel;

  /// Selection state for accessibility.
  final bool? selected;

  @override
  State<MonoPressable> createState() => _MonoPressableState();
}

class _MonoPressableState extends State<MonoPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _down ? widget.scale : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
