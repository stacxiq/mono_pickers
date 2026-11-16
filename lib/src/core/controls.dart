import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'effects.dart';
import 'feedback.dart';
import 'odometer.dart';
import 'theme.dart';

/// A pill-shaped segmented control with a sliding thumb.
class MonoSegmented<T> extends StatelessWidget {
  /// Creates a segmented control.
  const MonoSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.labelBuilder,
    this.expand = false,
    this.semanticLabel,
  });

  /// The options in order.
  final List<T> options;

  /// The selected option.
  final T value;

  /// Called when another option is chosen.
  final ValueChanged<T> onChanged;

  /// Builds a label; defaults to `toString()`.
  final String Function(T option)? labelBuilder;

  /// Whether to fill the available width.
  final bool expand;

  /// Accessibility label for the group.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final labels = [for (final o in options) labelBuilder?.call(o) ?? '$o'];
    final style = t.text(size: 12, weight: FontWeight.w600);
    final index = options.indexOf(value).clamp(0, options.length - 1);

    Widget build(double segW) {
      final n = options.length;
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: t.soft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: t.line),
        ),
        child: SizedBox(
          width: segW * n,
          height: 30,
          child: Stack(
            children: [
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 350),
                curve: monoSpring,
                start: segW * index,
                top: 0,
                bottom: 0,
                width: segW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < n; i++)
                    SizedBox(
                      width: segW,
                      child: Semantics(
                        inMutuallyExclusiveGroup: true,
                        checked: i == index,
                        button: true,
                        label: labels[i],
                        excludeSemantics: true,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (i == index) return;
                              MonoTick.play(context, strong: true);
                              onChanged(options[i]);
                            },
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 250),
                                style: style.copyWith(
                                  color: i == index ? t.onInk : t.muted,
                                ),
                                child: Text(
                                  labels[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final group = expand
        ? LayoutBuilder(
            builder: (context, c) => build((c.maxWidth - 8) / options.length),
          )
        : build(() {
            var w = 46.0;
            for (final l in labels) {
              final tp = TextPainter(
                text: TextSpan(text: l, style: style),
                textDirection: TextDirection.ltr,
                textScaler: MediaQuery.textScalerOf(context),
              )..layout();
              if (tp.width + 28 > w) w = tp.width + 28;
            }
            return w;
          }());
    return Semantics(container: true, label: semanticLabel, child: group);
  }
}

/// A compact − value + stepper with rolling digits.
class MonoMiniStepper extends StatelessWidget {
  /// Creates a mini stepper.
  const MonoMiniStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.label = '',
  });

  /// Current value.
  final int value;

  /// Called with the new value.
  final ValueChanged<int> onChanged;

  /// Minimum.
  final int min;

  /// Maximum.
  final int max;

  /// Accessibility label (for example "adults").
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    Widget btn(IconData icon, bool enabled, int d, String a11y) =>
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1 : 0.3,
          child: MonoPressable(
            scale: 0.88,
            semanticLabel: a11y,
            onTap: enabled
                ? () {
                    MonoTick.play(context);
                    onChanged(value + d);
                  }
                : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.soft,
                border: Border.all(color: t.line),
              ),
              child: Icon(icon, size: 15, color: t.ink),
            ),
          ),
        );
    return Semantics(
      value: '$value',
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded, value > min, -1, 'Fewer $label'),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                widthFactor: 1,
                child: MonoOdometer(
                  '$value',
                  style: t.text(size: 17, weight: FontWeight.w600),
                ),
              ),
            ),
          ),
          btn(Icons.add_rounded, value < max, 1, 'More $label'),
        ],
      ),
    );
  }
}

/// Makes a picker focusable and adjustable with the keyboard, and exposes
/// it to screen readers as a slider.
class MonoAdjustable extends StatefulWidget {
  /// Creates an adjustable wrapper.
  const MonoAdjustable({
    super.key,
    required this.child,
    required this.onStep,
    required this.label,
    required this.valueText,
    this.onHome,
    this.onEnd,
    this.radius = 16,
    this.increasedValueText,
    this.decreasedValueText,
  });

  /// The picker.
  final Widget child;

  /// Called with +1 / −1 (arrows) or ±10 (page keys).
  final ValueChanged<int> onStep;

  /// Accessibility label.
  final String label;

  /// Accessibility value text.
  final String valueText;

  /// Home key.
  final VoidCallback? onHome;

  /// End key.
  final VoidCallback? onEnd;

  /// Corner radius of the focus ring.
  final double radius;

  /// What the value becomes after an increase (for screen readers).
  /// Defaults to [valueText].
  final String? increasedValueText;

  /// What the value becomes after a decrease (for screen readers).
  /// Defaults to [valueText].
  final String? decreasedValueText;

  @override
  State<MonoAdjustable> createState() => _MonoAdjustableState();
}

class _MonoAdjustableState extends State<MonoAdjustable> {
  bool _focused = false;
  final FocusNode _node = FocusNode(debugLabel: 'MonoAdjustable');

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final k = e.logicalKey;
    int? d;
    if (k == LogicalKeyboardKey.arrowUp) d = 1;
    if (k == LogicalKeyboardKey.arrowDown) d = -1;
    if (k == LogicalKeyboardKey.arrowRight) d = rtl ? -1 : 1;
    if (k == LogicalKeyboardKey.arrowLeft) d = rtl ? 1 : -1;
    if (k == LogicalKeyboardKey.pageUp) d = 10;
    if (k == LogicalKeyboardKey.pageDown) d = -10;
    if (d != null) {
      widget.onStep(d);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.home && widget.onHome != null) {
      widget.onHome!();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.end && widget.onEnd != null) {
      widget.onEnd!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return Semantics(
      slider: true,
      label: widget.label,
      value: widget.valueText,
      increasedValue: widget.increasedValueText ?? widget.valueText,
      decreasedValue: widget.decreasedValueText ?? widget.valueText,
      onIncrease: () => widget.onStep(1),
      onDecrease: () => widget.onStep(-1),
      child: Focus(
        focusNode: _node,
        onKeyEvent: _key,
        onFocusChange: (f) => setState(() => _focused = f),
        child: Listener(
          onPointerDown: (_) {
            if (!_node.hasFocus) {
              _node.requestFocus();
            }
          },
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(
                color: _focused ? t.ink : const Color(0x00000000),
                width: 2,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
