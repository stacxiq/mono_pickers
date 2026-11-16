import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/controls.dart';
import '../core/effects.dart';
import '../core/feedback.dart';
import '../core/odometer.dart';
import '../core/theme.dart';
import 'body.dart' show MonoThumb;

// ───────────────────────── Add → stepper ─────────────────────────

/// An "Add" button that morphs into a − n + stepper once the quantity is
/// above zero. At one item the minus becomes a trash can.
class MonoAddStepper extends StatelessWidget {
  /// Creates an add stepper.
  const MonoAddStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.max = 99,
    this.label = 'Add',
    this.itemName = 'item',
  });

  /// Quantity in the cart.
  final int quantity;

  /// Called with the new quantity.
  final ValueChanged<int> onChanged;

  /// Maximum quantity.
  final int max;

  /// Label of the closed button.
  final String label;

  /// Name used for accessibility ("Add croissant").
  final String itemName;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final open = quantity > 0;
    final fg = t.onInk;
    Widget iconBtn(IconData icon, String a11y, VoidCallback? onTap) =>
        Semantics(
          button: true,
          label: a11y,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 16, color: fg),
            ),
          ),
        );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: monoSpring,
      width: open ? 122 : 82,
      height: 40,
      decoration: BoxDecoration(
        color: t.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            ignoring: open,
            child: AnimatedOpacity(
              opacity: open ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: AnimatedScale(
                scale: open ? 0.7 : 1,
                duration: const Duration(milliseconds: 350),
                curve: monoSpring,
                child: Semantics(
                  button: true,
                  label: '$label $itemName',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      MonoTick.play(context, strong: true);
                      onChanged(1);
                    },
                    child: SizedBox(
                      width: 82,
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, size: 16, color: fg),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: t.text(
                              size: 13,
                              weight: FontWeight.w600,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: !open,
            child: AnimatedOpacity(
              opacity: open ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: AnimatedScale(
                scale: open ? 1 : 0.7,
                duration: const Duration(milliseconds: 350),
                curve: monoSpring,
                child: OverflowBox(
                  maxWidth: 122,
                  minWidth: 122,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      iconBtn(
                        quantity == 1
                            ? Icons.delete_outline_rounded
                            : Icons.remove_rounded,
                        quantity == 1 ? 'Remove $itemName' : 'Decrease',
                        () {
                          MonoTick.play(context, strong: quantity == 1);
                          onChanged(quantity - 1);
                        },
                      ),
                      MonoOdometer(
                        '${math.max(1, quantity)}',
                        style: t.text(
                          size: 15,
                          weight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                      iconBtn(
                        Icons.add_rounded,
                        'Increase',
                        quantity >= max
                            ? null
                            : () {
                                MonoTick.play(context);
                                onChanged(quantity + 1);
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Range with histogram ─────────────────────────

/// A two-thumb range slider with an optional histogram that lights up
/// inside the selected range (price filters, budgets, durations).
class MonoRangePicker extends StatefulWidget {
  /// Creates a range picker.
  const MonoRangePicker({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1000,
    this.step = 10,
    this.minGap = 50,
    this.histogram,
    this.majorInterval = 100,
  });

  /// Selected range.
  final RangeValues values;

  /// Called with the new range.
  final ValueChanged<RangeValues> onChanged;

  /// Minimum.
  final double min;

  /// Maximum.
  final double max;

  /// Snap step.
  final double step;

  /// Smallest allowed distance between the thumbs.
  final double minGap;

  /// Bar heights (0..1), evenly spread from [min] to [max].
  final List<double>? histogram;

  /// Values that are multiples of this play a strong tick.
  final double majorInterval;

  @override
  State<MonoRangePicker> createState() => _MonoRangePickerState();
}

class _MonoRangePickerState extends State<MonoRangePicker> {
  int _active = -1;

  void _setK(int k, double x) {
    x = (x / widget.step).round() * widget.step;
    final v = widget.values;
    x = k == 1
        ? x.clamp(v.start + widget.minGap, widget.max)
        : x.clamp(widget.min, v.end - widget.minGap);
    if (x == (k == 0 ? v.start : v.end)) return;
    MonoTick.play(context, strong: x % widget.majorInterval == 0);
    widget.onChanged(k == 0 ? RangeValues(x, v.end) : RangeValues(v.start, x));
  }

  double _valAt(double dx, double w) {
    var f = (dx / w).clamp(0.0, 1.0);
    if (Directionality.of(context) == TextDirection.rtl) f = 1 - f;
    return widget.min + f * (widget.max - widget.min);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final v = widget.values;
    final span = widget.max - widget.min;
    final f0 = (v.start - widget.min) / span, f1 = (v.end - widget.min) / span;
    final h = widget.histogram;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (h != null && h.isNotEmpty)
          SizedBox(
            height: 84,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              textDirection: Directionality.of(context),
              children: [
                for (var i = 0; i < h.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    child: () {
                      final c = widget.min + (i + 0.5) / h.length * span;
                      final on = c >= v.start && c <= v.end;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 84 * h[i].clamp(0.02, 1.0),
                        decoration: BoxDecoration(
                          color: t.ink.withValues(alpha: on ? 0.7 : 0.12),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                            bottom: Radius.circular(1),
                          ),
                        ),
                      );
                    }(),
                  ),
                ],
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanDown: (d) {
                final x = _valAt(d.localPosition.dx, w);
                var k = (x - v.start).abs() <= (x - v.end).abs() ? 0 : 1;
                if (x > v.end) k = 1;
                if (x < v.start) k = 0;
                setState(() => _active = k);
                _setK(k, x);
              },
              onPanUpdate: (d) {
                if (_active >= 0) _setK(_active, _valAt(d.localPosition.dx, w));
              },
              onPanEnd: (_) => setState(() => _active = -1),
              onPanCancel: () => setState(() => _active = -1),
              child: SizedBox(
                height: 28,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 12,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    AnimatedPositionedDirectional(
                      duration: Duration(milliseconds: _active >= 0 ? 0 : 400),
                      curve: monoSpring,
                      start: f0 * w,
                      width: (f1 - f0) * w,
                      top: 12,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.ink,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    for (final (k, f) in [(0, f0), (1, f1)])
                      AnimatedPositionedDirectional(
                        duration: Duration(
                          milliseconds: _active >= 0 ? 0 : 400,
                        ),
                        curve: monoSpring,
                        start: f * w - 12,
                        top: 2,
                        child: MonoAdjustable(
                          label: k == 0 ? 'Minimum' : 'Maximum',
                          radius: 999,
                          valueText: '${(k == 0 ? v.start : v.end).round()}',
                          onStep: (d) => _setK(
                            k,
                            (k == 0 ? v.start : v.end) + d * widget.step,
                          ),
                          child: MonoThumb(theme: t, active: _active == k),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ───────────────────────── Swatches & sizes ─────────────────────────

/// Round color swatches with a ring around the selected one.
class MonoSwatchPicker extends StatefulWidget {
  /// Creates a swatch picker.
  const MonoSwatchPicker({
    super.key,
    required this.colors,
    required this.value,
    required this.onChanged,
    this.labels,
    this.size = 36,
  });

  /// Colors.
  final List<Color> colors;

  /// Selected index.
  final int value;

  /// Called with the new index.
  final ValueChanged<int> onChanged;

  /// Color names for accessibility.
  final List<String>? labels;

  /// Swatch diameter.
  final double size;

  @override
  State<MonoSwatchPicker> createState() => _MonoSwatchPickerState();
}

class _MonoSwatchPickerState extends State<MonoSwatchPicker> {
  int _pop = 0;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < widget.colors.length; i++)
          MonoPop(
            trigger: i == widget.value ? _pop : null,
            child: MonoPressable(
              scale: 0.9,
              selected: i == widget.value,
              semanticLabel: widget.labels?[i] ?? 'Color ${i + 1}',
              onTap: () {
                if (i == widget.value) return;
                setState(() => _pop++);
                MonoTick.play(context);
                widget.onChanged(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.colors[i],
                  shape: BoxShape.circle,
                  boxShadow: i == widget.value
                      ? [
                          BoxShadow(color: t.ink, spreadRadius: 5),
                          BoxShadow(color: t.surface, spreadRadius: 3),
                        ]
                      : [BoxShadow(color: t.line, spreadRadius: 1)],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A grid of size chips; unavailable sizes are struck through.
class MonoSizePicker extends StatelessWidget {
  /// Creates a size picker.
  const MonoSizePicker({
    super.key,
    required this.sizes,
    required this.value,
    required this.onChanged,
    this.unavailable = const {},
    this.columns = 6,
  });

  /// Size labels.
  final List<String> sizes;

  /// Selected index.
  final int value;

  /// Called with the new index.
  final ValueChanged<int> onChanged;

  /// Indices that are sold out.
  final Set<int> unavailable;

  /// Columns.
  final int columns;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 6 * (columns - 1)) / columns;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < sizes.length; i++)
              SizedBox(
                width: w,
                height: 40,
                child: MonoPressable(
                  selected: i == value,
                  semanticLabel:
                      '${sizes[i]}${unavailable.contains(i) ? ', sold out' : ''}',
                  onTap: unavailable.contains(i)
                      ? null
                      : () {
                          if (i == value) return;
                          MonoTick.play(context);
                          onChanged(i);
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: i == value ? t.ink : t.soft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: i == value ? t.ink : t.line),
                    ),
                    child: CustomPaint(
                      painter: unavailable.contains(i)
                          ? _StrikePainter(t.line)
                          : null,
                      child: Center(
                        child: Text(
                          sizes[i],
                          style: t.text(
                            size: 13,
                            weight: FontWeight.w600,
                            color: unavailable.contains(i)
                                ? t.muted
                                : i == value
                                ? t.onInk
                                : t.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StrikePainter extends CustomPainter {
  _StrikePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
    Offset(0, size.height),
    Offset(size.width, 0),
    Paint()
      ..color = color
      ..strokeWidth = 1.5,
  );

  @override
  bool shouldRepaint(_StrikePainter old) => old.color != color;
}

// ───────────────────────── Options (radio rows) ─────────────────────────

/// A row in [MonoOptionPicker].
@immutable
class MonoOption<T> {
  /// Creates an option.
  const MonoOption({
    required this.value,
    required this.title,
    this.subtitle = '',
    this.trailing = '',
    this.icon,
  });

  /// Value.
  final T value;

  /// Title.
  final String title;

  /// Description.
  final String subtitle;

  /// Right-aligned text (price, "Free").
  final String trailing;

  /// Optional icon.
  final IconData? icon;
}

/// Radio rows with a border that slides to the selected row (delivery,
/// shipping speed, plans).
class MonoOptionPicker<T> extends StatefulWidget {
  /// Creates an option picker.
  const MonoOptionPicker({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.rowHeight = 64,
  });

  /// Options.
  final List<MonoOption<T>> options;

  /// Selected value.
  final T value;

  /// Called with the new value.
  final ValueChanged<T> onChanged;

  /// Height of each row.
  final double rowHeight;

  @override
  State<MonoOptionPicker<T>> createState() => _MonoOptionPickerState<T>();
}

class _MonoOptionPickerState<T> extends State<MonoOptionPicker<T>> {
  int _pop = 0;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final idx = widget.options.indexWhere((o) => o.value == widget.value);
    final rh = widget.rowHeight;
    return SizedBox(
      height: widget.options.length * (rh + 8) - 8,
      child: Stack(
        children: [
          Column(
            children: [
              for (var i = 0; i < widget.options.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                SizedBox(
                  height: rh,
                  child: _OptionRow(
                    option: widget.options[i],
                    selected: i == idx,
                    theme: t,
                    pop: i == idx ? _pop : 0,
                    onTap: () {
                      if (i == idx) return;
                      setState(() => _pop++);
                      MonoTick.play(context, strong: true);
                      widget.onChanged(widget.options[i].value);
                    },
                  ),
                ),
              ],
            ],
          ),
          if (idx >= 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 450),
              curve: monoSpring,
              left: 0,
              right: 0,
              top: idx * (rh + 8),
              height: rh,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: t.ink, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.theme,
    required this.pop,
    required this.onTap,
  });

  final MonoOption<T> option;
  final bool selected;
  final MonoPickerThemeData theme;
  final int pop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '${option.title}, ${option.subtitle}, ${option.trailing}',
      excludeSemantics: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: t.soft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: t.line),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? t.ink : t.line,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    curve: monoBounce,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: t.ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (option.icon != null) ...[
                  MonoPop(
                    trigger: pop,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.line),
                      ),
                      child: Icon(option.icon, size: 21, color: t.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: t.text(size: 14, weight: FontWeight.w600),
                      ),
                      if (option.subtitle.isNotEmpty)
                        Text(
                          option.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.text(size: 12, color: t.muted),
                        ),
                    ],
                  ),
                ),
                if (option.trailing.isNotEmpty)
                  Text(
                    option.trailing,
                    style: t.text(size: 13, weight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Card carousel ─────────────────────────

/// A snapping carousel where off-center cards shrink and fade, with page
/// dots underneath (payment methods, plans, addresses).
class MonoCardCarousel extends StatefulWidget {
  /// Creates a carousel.
  const MonoCardCarousel({
    super.key,
    required this.children,
    required this.value,
    required this.onChanged,
    this.cardWidth = 240,
    this.cardHeight = 150,
    this.spacing = 14,
    this.showDots = true,
  });

  /// Cards.
  final List<Widget> children;

  /// Centered index.
  final int value;

  /// Called when another card settles in the center.
  final ValueChanged<int> onChanged;

  /// Card width.
  final double cardWidth;

  /// Card height.
  final double cardHeight;

  /// Gap between cards.
  final double spacing;

  /// Whether to show page dots.
  final bool showDots;

  @override
  State<MonoCardCarousel> createState() => _MonoCardCarouselState();
}

class _MonoCardCarouselState extends State<MonoCardCarousel> {
  PageController? _pc;
  double _fraction = 0;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _shown = widget.value;
  }

  @override
  void didUpdateWidget(MonoCardCarousel old) {
    super.didUpdateWidget(old);
    if (widget.value != _shown && _pc != null && _pc!.hasClients) {
      _shown = widget.value;
      _pc!.animateToPage(
        widget.value,
        duration: const Duration(milliseconds: 380),
        curve: monoEase,
      );
    }
  }

  @override
  void dispose() {
    _pc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final frac = ((widget.cardWidth + widget.spacing) / c.maxWidth).clamp(
          0.2,
          1.0,
        );
        if (_pc == null || _fraction != frac) {
          final page = _pc != null && _pc!.hasClients
              ? (_pc!.page ?? _shown.toDouble()).round()
              : _shown;
          _pc?.dispose();
          _pc = PageController(viewportFraction: frac, initialPage: page);
          _fraction = frac;
        }
        final pc = _pc!;
        return Column(
          children: [
            SizedBox(
              height: widget.cardHeight + 16,
              child: PageView.builder(
                controller: pc,
                itemCount: widget.children.length,
                onPageChanged: (i) {
                  _shown = i;
                  MonoTick.play(context);
                  widget.onChanged(i);
                },
                itemBuilder: (context, i) => AnimatedBuilder(
                  animation: pc,
                  builder: (context, child) {
                    final p = pc.hasClients && pc.position.haveDimensions
                        ? pc.page ?? _shown.toDouble()
                        : _shown.toDouble();
                    final k = math.min(
                      1.0,
                      (p - i).abs() * (widget.cardWidth + widget.spacing) / 260,
                    );
                    return Opacity(
                      opacity: 1 - 0.5 * k,
                      child: Transform.scale(scale: 1 - 0.1 * k, child: child),
                    );
                  },
                  child: Center(
                    child: GestureDetector(
                      onTap: () => pc.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 380),
                        curve: monoEase,
                      ),
                      child: SizedBox(
                        width: widget.cardWidth,
                        height: widget.cardHeight,
                        child: widget.children[i],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showDots) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.children.length; i++)
                    GestureDetector(
                      onTap: () => pc.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 380),
                        curve: monoEase,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: monoSpring,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == widget.value ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: t.ink.withValues(
                            alpha: i == widget.value ? 1 : 0.2,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Visual styles for [MonoPaymentCard].
enum MonoCardStyle {
  /// Solid ink.
  ink,

  /// Outlined.
  outline,

  /// Soft fill.
  soft,
}

/// A monochrome payment card for [MonoCardCarousel].
class MonoPaymentCard extends StatelessWidget {
  /// Creates a payment card. Provide [number] (last 4) or [balance].
  const MonoPaymentCard({
    super.key,
    required this.title,
    this.style = MonoCardStyle.ink,
    this.number,
    this.expiry,
    this.balance,
    this.footnote,
  });

  /// Card name ("Credit").
  final String title;

  /// Style.
  final MonoCardStyle style;

  /// Last four digits.
  final String? number;

  /// Expiry text.
  final String? expiry;

  /// Balance text, for wallets.
  final String? balance;

  /// Text shown instead of the number (e.g. "Instant · no fees").
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final (bg, fg, border) = switch (style) {
      MonoCardStyle.ink => (t.ink, t.onInk, t.ink),
      MonoCardStyle.outline => (t.surface, t.ink, t.ink),
      MonoCardStyle.soft => (t.soft, t.ink, t.line),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -58,
            bottom: -66,
            child: Opacity(
              opacity: 0.12,
              child: CustomPaint(
                size: const Size(170, 170),
                painter: _RingsPainter(fg),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: t.text(size: 13, weight: FontWeight.w600, color: fg),
                  ),
                  Icon(Icons.contactless_outlined, size: 22, color: fg),
                ],
              ),
              if (balance != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance',
                      style: t.text(size: 11, color: fg.withValues(alpha: 0.6)),
                    ),
                    Text(
                      balance!,
                      style: t.text(
                        size: 28,
                        weight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: 34,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: fg.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      number != null ? '•••• $number' : footnote ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.text(
                        size: 15,
                        weight: FontWeight.w600,
                        color: fg,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Text(
                    expiry ?? '',
                    style: t.text(
                      size: 13,
                      weight: FontWeight.w500,
                      color: fg.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..color = color;
    final c = size.center(Offset.zero);
    for (final r in [0.18, 0.32, 0.46]) {
      canvas.drawCircle(c, size.width * r, p);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color;
}

// ───────────────────────── Tip ─────────────────────────

/// Tip presets with a custom percentage stepper.
class MonoTipPicker extends StatefulWidget {
  /// Creates a tip picker. [value] is a percentage.
  const MonoTipPicker({
    super.key,
    required this.amount,
    required this.value,
    required this.onChanged,
    this.presets = const [0, 10, 15, 20],
    this.customMax = 40,
    this.formatMoney,
  });

  /// Order total the percentage applies to.
  final double amount;

  /// Selected percentage.
  final int value;

  /// Called with the new percentage.
  final ValueChanged<int> onChanged;

  /// Preset percentages (0 shows as "None").
  final List<int> presets;

  /// Maximum custom percentage.
  final int customMax;

  /// Formats money; defaults to `$12.34`.
  final String Function(double amount)? formatMoney;

  @override
  State<MonoTipPicker> createState() => _MonoTipPickerState();
}

class _MonoTipPickerState extends State<MonoTipPicker> {
  late bool _custom;
  late int _customValue;

  @override
  void initState() {
    super.initState();
    _custom = !widget.presets.contains(widget.value);
    _customValue = _custom ? widget.value : 18;
  }

  int _pop = 0;

  String _money(double v) =>
      widget.formatMoney?.call(v) ?? '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    Widget tile(
      String top,
      String bottom,
      bool on,
      VoidCallback onTap,
      int i,
    ) => Expanded(
      child: MonoPop(
        trigger: on ? _pop : null,
        child: MonoPressable(
          selected: on,
          semanticLabel: '$top $bottom',
          onTap: on
              ? null
              : () {
                  setState(() => _pop++);
                  MonoTick.play(context, strong: true);
                  onTap();
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: on ? t.ink : t.soft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: on ? t.ink : t.line),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  children: [
                    Text(
                      top,
                      style: t.text(
                        size: 15,
                        weight: FontWeight.w600,
                        color: on ? t.onInk : t.ink,
                      ),
                    ),
                    Text(
                      bottom,
                      style: t.text(
                        size: 11,
                        color: on ? t.onInk.withValues(alpha: 0.65) : t.muted,
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
    final tiles = <Widget>[];
    for (var i = 0; i < widget.presets.length; i++) {
      final p = widget.presets[i];
      if (i > 0) tiles.add(const SizedBox(width: 6));
      tiles.add(
        tile(
          p == 0 ? 'None' : '$p%',
          _money(widget.amount * p / 100),
          !_custom && widget.value == p,
          () {
            setState(() => _custom = false);
            widget.onChanged(p);
          },
          i,
        ),
      );
    }
    tiles.add(const SizedBox(width: 6));
    tiles.add(
      tile('Other', _custom ? '$_customValue%' : '…', _custom, () {
        setState(() => _custom = true);
        widget.onChanged(_customValue);
      }, widget.presets.length),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: tiles),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: monoEase,
          child: _custom
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.line),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Custom',
                            style: t.text(size: 13, color: t.muted),
                          ),
                        ),
                        MonoMiniStepper(
                          value: _customValue,
                          min: 1,
                          max: widget.customMax,
                          label: 'percent',
                          onChanged: (v) {
                            setState(() => _customValue = v);
                            widget.onChanged(v);
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
