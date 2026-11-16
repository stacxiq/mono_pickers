import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/controls.dart';
import '../core/effects.dart';
import '../core/feedback.dart';
import '../core/theme.dart';
import 'body.dart' show MonoBand, MonoDrumPicker;

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _wdShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

// ───────────────────────── Route ─────────────────────────

/// A place for [MonoRoutePicker].
@immutable
class MonoPlace {
  /// Creates a place.
  const MonoPlace(this.code, this.name);

  /// Short code ("BGW").
  final String code;

  /// Full name ("Baghdad").
  final String name;
}

/// From / To fields with an animated swap button.
class MonoRoutePicker extends StatefulWidget {
  /// Creates a route picker.
  const MonoRoutePicker({
    super.key,
    required this.from,
    required this.to,
    required this.onSwap,
    this.fromLabel = 'From',
    this.toLabel = 'To',
  });

  /// Origin.
  final MonoPlace from;

  /// Destination.
  final MonoPlace to;

  /// Called when the swap button is pressed; swap the places in your state.
  final VoidCallback onSwap;

  /// Label above the origin.
  final String fromLabel;

  /// Label above the destination.
  final String toLabel;

  @override
  State<MonoRoutePicker> createState() => _MonoRoutePickerState();
}

class _MonoRoutePickerState extends State<MonoRoutePicker> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    Widget field(String label, MonoPlace p, bool top) => Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: t.soft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: t.text(size: 11, color: t.muted, letterSpacing: 0.9),
          ),
          SizedBox(
            height: 34,
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: monoSpring,
                layoutBuilder: (c, prev) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...prev, ?c],
                ),
                transitionBuilder: (child, anim) {
                  final incoming = child.key == ValueKey(p.code);
                  final dir = top ? -1.1 : 1.1;
                  return SlideTransition(
                    position: Tween(
                      begin: Offset(0, incoming ? dir : -dir),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  );
                },
                child: Text(
                  p.code,
                  key: ValueKey(p.code),
                  style: t.text(
                    size: 28,
                    weight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
          MonoSwapText(p.name, style: t.text(size: 13, color: t.muted)),
        ],
      ),
    );
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            field(widget.fromLabel, widget.from, true),
            const SizedBox(height: 6),
            field(widget.toLabel, widget.to, false),
          ],
        ),
        PositionedDirectional(
          end: 18,
          top: 0,
          bottom: 0,
          child: Center(
            child: Semantics(
              button: true,
              label:
                  'Swap ${widget.fromLabel.toLowerCase()} and ${widget.toLabel.toLowerCase()}',
              child: MonoPressable(
                scale: 0.92,
                onTap: () {
                  setState(() => _turns += 0.5);
                  MonoTick.play(context, strong: true);
                  widget.onSwap();
                },
                child: AnimatedRotation(
                  turns: _turns,
                  duration: const Duration(milliseconds: 500),
                  curve: monoSpring,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: t.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.line),
                    ),
                    child: Icon(
                      Icons.swap_vert_rounded,
                      size: 20,
                      color: t.onInk,
                    ),
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

// ───────────────────────── Range calendar ─────────────────────────

/// A month calendar for picking a date range (stays, rentals, leave).
/// Tap a start date, then an end date; hovering previews the range.
class MonoRangeCalendar extends StatefulWidget {
  /// Creates a range calendar.
  MonoRangeCalendar({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
    DateTime? firstDate,
    DateTime? initialMonth,
    this.firstDayOfWeek = DateTime.monday,
  }) : firstDate = _day(firstDate ?? DateTime.now()),
       initialMonth = initialMonth ?? start ?? DateTime.now();

  /// Range start (check-in).
  final DateTime? start;

  /// Range end (check-out); null while picking.
  final DateTime? end;

  /// Called with the new start and end.
  final void Function(DateTime start, DateTime? end) onChanged;

  /// Earliest selectable date (defaults to today).
  final DateTime firstDate;

  /// Month shown first.
  final DateTime initialMonth;

  /// [DateTime.monday] … [DateTime.sunday].
  final int firstDayOfWeek;

  @override
  State<MonoRangeCalendar> createState() => _MonoRangeCalendarState();
}

class _MonoRangeCalendarState extends State<MonoRangeCalendar> {
  late DateTime _view = DateTime(
    widget.initialMonth.year,
    widget.initialMonth.month,
  );
  DateTime? _hover;
  int _dir = 0;
  int _pop = 0;
  DateTime? _popDay;

  void _go(int d) {
    setState(() {
      _dir = d;
      _view = DateTime(_view.year, _view.month + d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final first = DateTime(widget.firstDate.year, widget.firstDate.month);
    final canPrev = _view.isAfter(first);
    final start = widget.start == null ? null : _day(widget.start!);
    final end = widget.end == null ? null : _day(widget.end!);
    final previewEnd = end ?? _hover;
    final today = _day(DateTime.now());
    final lead =
        (DateTime(_view.year, _view.month).weekday -
            widget.firstDayOfWeek +
            7) %
        7;
    final dim = DateTime(_view.year, _view.month + 1, 0).day;
    final wd = [
      for (var i = 0; i < 7; i++)
        _wdShort[(widget.firstDayOfWeek - 1 + i) % 7].substring(0, 2),
    ];

    Widget cell(int day) {
      final d = DateTime(_view.year, _view.month, day);
      final disabled = d.isBefore(widget.firstDate);
      final isStart = start != null && d == start;
      final isEnd = end != null && d == end;
      final inRange =
          start != null && end != null && d.isAfter(start) && d.isBefore(end);
      final inPreview =
          start != null &&
          end == null &&
          previewEnd != null &&
          d.isAfter(start) &&
          !d.isAfter(previewEnd);
      final rangedStart =
          isStart && previewEnd != null && previewEnd.isAfter(start);
      final rtl = Directionality.of(context) == TextDirection.rtl;
      Widget band = const SizedBox();
      if (inRange || inPreview) {
        band = Positioned.fill(
          top: 2,
          bottom: 2,
          child: ColoredBox(color: t.line),
        );
      }
      final sel = isStart || isEnd;
      return Semantics(
        button: true,
        selected: sel,
        enabled: !disabled,
        label: '${_months[d.month - 1]} $day',
        excludeSemantics: true,
        child: MouseRegion(
          cursor: disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onEnter: (_) {
            if (end == null && !disabled) setState(() => _hover = d);
          },
          child: GestureDetector(
            onTap: disabled
                ? null
                : () {
                    setState(() {
                      _pop++;
                      _popDay = d;
                    });
                    if (end != null || start == null || !d.isAfter(start)) {
                      MonoTick.play(context);
                      widget.onChanged(d, null);
                    } else {
                      MonoTick.play(context, strong: true);
                      widget.onChanged(start, d);
                    }
                  },
            child: SizedBox(
              height: 40,
              child: LayoutBuilder(
                builder: (context, c) => Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    if (rangedStart || (isEnd && start != null))
                      Positioned(
                        top: 2,
                        bottom: 2,
                        left: (rangedStart != rtl) ? c.maxWidth / 2 : 0,
                        width: c.maxWidth / 2,
                        child: ColoredBox(color: t.line),
                      )
                    else
                      band,
                    Center(
                      child: MonoPop(
                        trigger: _popDay == d ? _pop : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel ? t.ink : null,
                            border: d == today && !sel
                                ? Border.all(color: t.line)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$day',
                            style: t.text(
                              size: 14,
                              weight: FontWeight.w500,
                              color: sel
                                  ? t.onInk
                                  : disabled
                                  ? t.muted.withValues(alpha: 0.4)
                                  : t.ink,
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

    final cells = <Widget>[
      for (var i = 0; i < lead; i++) const SizedBox(height: 40),
      for (var d = 1; d <= dim; d++) cell(d),
    ];
    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(
        Row(
          children: [
            for (var j = i; j < i + 7; j++)
              Expanded(
                child: j < cells.length ? cells[j] : const SizedBox(height: 40),
              ),
          ],
        ),
      );
    }

    Widget nav(IconData icon, String label, VoidCallback? onTap) =>
        MonoPressable(
          onTap: onTap,
          semanticLabel: label,
          child: AnimatedOpacity(
            opacity: onTap == null ? 0.35 : 1,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.soft,
                border: Border.all(color: t.line),
              ),
              child: Icon(icon, size: 18, color: t.ink),
            ),
          ),
        );

    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: MonoSwapText(
                '${_months[_view.month - 1]} ${_view.year}',
                style: t.text(size: 17, weight: FontWeight.w600),
              ),
            ),
            nav(
              rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
              'Previous month',
              canPrev ? () => _go(-1) : null,
            ),
            const SizedBox(width: 6),
            nav(
              rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              'Next month',
              () => _go(1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final w in wd)
              Expanded(
                child: Text(
                  w,
                  textAlign: TextAlign.center,
                  style: t.text(size: 11, color: t.muted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        MouseRegion(
          onExit: (_) => setState(() => _hover = null),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: monoEase,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: Offset(_dir * 0.05 * (rtl ? -1 : 1), 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            layoutBuilder: (c, prev) =>
                Stack(alignment: Alignment.topCenter, children: [?c]),
            child: Column(
              key: ValueKey('${_view.year}-${_view.month}'),
              children: [
                for (final r in rows)
                  Padding(padding: const EdgeInsets.only(bottom: 2), child: r),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Counter list ─────────────────────────

/// A row in [MonoCounterList].
@immutable
class MonoCounterItem {
  /// Creates a counter item.
  const MonoCounterItem({
    required this.title,
    this.subtitle = '',
    this.min = 0,
    this.max = 9,
  });

  /// Title ("Adults").
  final String title;

  /// Description ("Age 13+").
  final String subtitle;

  /// Minimum.
  final int min;

  /// Maximum (overridden by [MonoCounterList.maxOf]).
  final int max;
}

/// Rows of labelled steppers (guests, rooms, passengers, tickets).
class MonoCounterList extends StatelessWidget {
  /// Creates a counter list.
  const MonoCounterList({
    super.key,
    required this.items,
    required this.values,
    required this.onChanged,
    this.maxOf,
  });

  /// Rows.
  final List<MonoCounterItem> items;

  /// Current counts.
  final List<int> values;

  /// Called with all counts after any change.
  final ValueChanged<List<int>> onChanged;

  /// Dynamic maximum for row `i`, given all values (e.g. a shared cap).
  final int Function(int index, List<int> values)? maxOf;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: i == items.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: t.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].title,
                        style: t.text(size: 14, weight: FontWeight.w600),
                      ),
                      if (items[i].subtitle.isNotEmpty)
                        Text(
                          items[i].subtitle,
                          style: t.text(size: 12, color: t.muted),
                        ),
                    ],
                  ),
                ),
                MonoMiniStepper(
                  value: values[i],
                  min: items[i].min,
                  max: maxOf?.call(i, values) ?? items[i].max,
                  label: items[i].title.toLowerCase(),
                  onChanged: (v) => onChanged([...values]..[i] = v),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ───────────────────────── Seats ─────────────────────────

/// A row of seats for [MonoSeatPicker].
@immutable
class MonoSeatRow {
  /// Creates a seat row. Seat ids are `'$label$number'` (e.g. "F5").
  const MonoSeatRow({
    required this.label,
    required this.seats,
    this.gapsAfter = const [],
    this.wide = false,
    this.price = 0,
  });

  /// Row letter.
  final String label;

  /// Number of seats.
  final int seats;

  /// Seat numbers followed by an aisle.
  final List<int> gapsAfter;

  /// Wider seats (recliners).
  final bool wide;

  /// Price per seat in this row.
  final double price;
}

/// A cinema / venue seat map. Tap seats to toggle; taken seats are
/// disabled; the map shakes when the selection limit is reached.
class MonoSeatPicker extends StatefulWidget {
  /// Creates a seat picker.
  const MonoSeatPicker({
    super.key,
    required this.rows,
    required this.selected,
    required this.onChanged,
    this.taken = const {},
    this.maxSelection = 6,
    this.showScreen = true,
    this.screenLabel = 'Screen',
  });

  /// Rows, front to back.
  final List<MonoSeatRow> rows;

  /// Selected seat ids.
  final Set<String> selected;

  /// Called with the new selection.
  final ValueChanged<Set<String>> onChanged;

  /// Unavailable seat ids.
  final Set<String> taken;

  /// Maximum seats per order.
  final int maxSelection;

  /// Whether to draw the curved screen.
  final bool showScreen;

  /// Screen caption.
  final String screenLabel;

  @override
  State<MonoSeatPicker> createState() => _MonoSeatPickerState();
}

class _MonoSeatPickerState extends State<MonoSeatPicker> {
  int _shake = 0;
  String? _popped;
  int _pop = 0;

  void _toggle(String id) {
    final next = {...widget.selected};
    if (next.remove(id)) {
      MonoTick.play(context);
    } else {
      if (next.length >= widget.maxSelection) {
        setState(() => _shake++);
        return;
      }
      next.add(id);
      setState(() {
        _popped = id;
        _pop++;
      });
      MonoTick.play(context, strong: true);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    Widget seat(MonoSeatRow r, int n) {
      final id = '${r.label}$n';
      final taken = widget.taken.contains(id);
      final on = widget.selected.contains(id);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: Semantics(
          button: true,
          toggled: on,
          enabled: !taken,
          label: 'Row ${r.label} seat $n${taken ? ', taken' : ''}',
          excludeSemantics: true,
          child: MouseRegion(
            cursor: taken
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: taken ? null : () => _toggle(id),
              child: MonoPop(
                trigger: _popped == id ? _pop : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: r.wide ? 34 : 26,
                  height: 24,
                  decoration: BoxDecoration(
                    color: taken
                        ? t.line
                        : on
                        ? t.ink
                        : null,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(r.wide ? 10 : 8),
                      bottom: const Radius.circular(4),
                    ),
                    border: taken
                        ? null
                        : Border.all(
                            color: t.ink.withValues(alpha: on ? 1 : 0.45),
                            width: 1.5,
                          ),
                  ),
                  alignment: Alignment.center,
                  child: on
                      ? Text(
                          '$n',
                          style: t.text(
                            size: 9,
                            weight: FontWeight.w600,
                            color: t.onInk,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final label = t.text(size: 10, color: t.muted);
    return MonoShake(
      trigger: _shake,
      child: Column(
        children: [
          if (widget.showScreen) ...[
            CustomPaint(
              size: const Size(double.infinity, 26),
              painter: _ScreenPainter(t.ink.withValues(alpha: 0.8)),
            ),
            Text(
              widget.screenLabel.toUpperCase(),
              style: t.text(size: 10, color: t.muted, letterSpacing: 3),
            ),
            const SizedBox(height: 8),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Column(
                children: [
                  for (final r in widget.rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            child: Text(
                              r.label,
                              textAlign: TextAlign.center,
                              style: label,
                            ),
                          ),
                          for (var n = 1; n <= r.seats; n++) ...[
                            seat(r, n),
                            if (r.gapsAfter.contains(n))
                              const SizedBox(width: 14),
                          ],
                          SizedBox(
                            width: 16,
                            child: Text(
                              r.label,
                              textAlign: TextAlign.center,
                              style: label,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenPainter extends CustomPainter {
  _ScreenPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * 0.8, x0 = (size.width - w) / 2;
    canvas.drawPath(
      Path()
        ..moveTo(x0, size.height - 4)
        ..quadraticBezierTo(size.width / 2, -12, x0 + w, size.height - 4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ScreenPainter old) => old.color != color;
}

// ───────────────────────── Tiers ─────────────────────────

/// A ticket tier for [MonoTierPicker].
@immutable
class MonoTier {
  /// Creates a tier.
  const MonoTier({
    required this.title,
    required this.price,
    this.subtitle = '',
    this.soldOut = false,
    this.badge,
  });

  /// Name.
  final String title;

  /// Price text.
  final String price;

  /// Description.
  final String subtitle;

  /// Whether it is sold out.
  final bool soldOut;

  /// Small badge next to the title (e.g. a countdown).
  final String? badge;
}

/// Ticket tiers with per-tier steppers and a shared per-order limit.
class MonoTierPicker extends StatelessWidget {
  /// Creates a tier picker.
  const MonoTierPicker({
    super.key,
    required this.tiers,
    required this.quantities,
    required this.onChanged,
    this.maxPerOrder = 8,
    this.soldOutLabel = 'Sold out',
  });

  /// Tiers.
  final List<MonoTier> tiers;

  /// Quantity per tier.
  final List<int> quantities;

  /// Called with all quantities after a change.
  final ValueChanged<List<int>> onChanged;

  /// Maximum tickets across tiers.
  final int maxPerOrder;

  /// Label for sold-out tiers.
  final String soldOutLabel;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final total = quantities.fold<int>(0, (a, b) => a + b);
    return Column(
      children: [
        for (var i = 0; i < tiers.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Opacity(
            opacity: tiers[i].soldOut ? 0.5 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: t.soft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: t.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                tiers[i].title,
                                style: t.text(
                                  size: 14,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (tiers[i].badge != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: t.line),
                                ),
                                child: Text(
                                  tiers[i].badge!,
                                  style: t.text(size: 11),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (tiers[i].subtitle.isNotEmpty)
                          Text(
                            tiers[i].subtitle,
                            style: t.text(size: 12, color: t.muted),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          tiers[i].price,
                          style: t.text(size: 13, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (tiers[i].soldOut)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: t.soft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: t.line),
                      ),
                      child: Text(
                        soldOutLabel,
                        style: t.text(size: 13, weight: FontWeight.w600),
                      ),
                    )
                  else
                    MonoMiniStepper(
                      value: quantities[i],
                      max: maxPerOrder - total + quantities[i],
                      label: tiers[i].title,
                      onChanged: (v) => onChanged([...quantities]..[i] = v),
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

// ───────────────────────── Date strip ─────────────────────────

/// A horizontal strip of days with a sliding selection pill.
class MonoDateStrip extends StatefulWidget {
  /// Creates a date strip starting at [start] (default today).
  MonoDateStrip({
    super.key,
    required this.value,
    required this.onChanged,
    DateTime? start,
    this.days = 45,
    this.isEnabled,
    this.showHeader = true,
    this.todayLabel = 'Today',
  }) : start = _day(start ?? DateTime.now());

  /// Selected day.
  final DateTime value;

  /// Called with the new day.
  final ValueChanged<DateTime> onChanged;

  /// First day.
  final DateTime start;

  /// Number of days.
  final int days;

  /// Whether a day can be picked (closed days are dimmed).
  final bool Function(DateTime day)? isEnabled;

  /// Whether to show the month title and paging arrows.
  final bool showHeader;

  /// Label for the first day when it is today.
  final String todayLabel;

  @override
  State<MonoDateStrip> createState() => _MonoDateStripState();
}

class _MonoDateStripState extends State<MonoDateStrip> {
  final _scroll = ScrollController();
  static const _w = 52.0, _gap = 6.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _page(int d) {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    _scroll.animateTo(
      (p.pixels + d * p.viewportDimension * 0.8).clamp(0, p.maxScrollExtent),
      duration: const Duration(milliseconds: 380),
      curve: monoEase,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final days = [
      for (var i = 0; i < widget.days; i++)
        DateTime(widget.start.year, widget.start.month, widget.start.day + i),
    ];
    final sel = days.indexWhere((d) => d == _day(widget.value));
    final today = _day(DateTime.now());
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget nav(IconData icon, String label, int d) => MonoPressable(
      onTap: () => _page(d),
      semanticLabel: label,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.soft,
          border: Border.all(color: t.line),
        ),
        child: Icon(icon, size: 18, color: t.ink),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader) ...[
          Row(
            children: [
              Expanded(
                child: MonoSwapText(
                  '${_months[widget.value.month - 1]} ${widget.value.year}',
                  style: t.text(size: 17, weight: FontWeight.w600),
                ),
              ),
              nav(
                rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                'Earlier',
                -1,
              ),
              const SizedBox(width: 6),
              nav(
                rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                'Later',
                1,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 72,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: days.length * (_w + _gap) - _gap,
              child: Stack(
                children: [
                  if (sel >= 0)
                    AnimatedPositionedDirectional(
                      duration: const Duration(milliseconds: 450),
                      curve: monoSpring,
                      start: sel * (_w + _gap),
                      top: 0,
                      width: _w,
                      height: 72,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.ink,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      for (var i = 0; i < days.length; i++) ...[
                        if (i > 0) const SizedBox(width: _gap),
                        () {
                          final d = days[i];
                          final enabled = widget.isEnabled?.call(d) ?? true;
                          final on = i == sel;
                          return Opacity(
                            opacity: enabled ? 1 : 0.35,
                            child: MonoPressable(
                              selected: on,
                              semanticLabel:
                                  '${_wdShort[d.weekday - 1]} ${_months[d.month - 1]} ${d.day}${enabled ? '' : ', closed'}',
                              onTap: enabled && !on
                                  ? () {
                                      MonoTick.play(context);
                                      widget.onChanged(d);
                                    }
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: _w,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: on ? null : t.soft,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: on
                                        ? const Color(0x00000000)
                                        : t.line,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      d == today
                                          ? widget.todayLabel
                                          : _wdShort[d.weekday - 1],
                                      style: t.text(
                                        size: 11,
                                        color: on
                                            ? t.onInk.withValues(alpha: 0.7)
                                            : t.muted,
                                      ),
                                    ),
                                    Text(
                                      '${d.day}',
                                      style: t.text(
                                        size: 18,
                                        weight: FontWeight.w600,
                                        color: on ? t.onInk : t.ink,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: enabled
                                            ? (on ? t.onInk : t.ink).withValues(
                                                alpha: 0.45,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Slots ─────────────────────────

/// A grid of time slots; unavailable slots are struck through. Slots
/// cascade in when the list changes.
class MonoSlotPicker extends StatelessWidget {
  /// Creates a slot picker.
  const MonoSlotPicker({
    super.key,
    required this.slots,
    required this.value,
    required this.onChanged,
    this.isEnabled,
    this.minSlotWidth = 68,
  });

  /// Slot labels ("09:00").
  final List<String> slots;

  /// Selected index, or null.
  final int? value;

  /// Called with the chosen index.
  final ValueChanged<int> onChanged;

  /// Whether slot `i` is available.
  final bool Function(int index)? isEnabled;

  /// Minimum slot width.
  final double minSlotWidth;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final cols = math.max(
          1,
          ((c.maxWidth + 6) / (minSlotWidth + 6)).floor(),
        );
        final w = (c.maxWidth - 6 * (cols - 1)) / cols;
        return Wrap(
          key: ValueKey(
            Object.hashAll(slots) ^
                Object.hashAll([
                  for (var i = 0; i < slots.length; i++) isEnabled?.call(i),
                ]),
          ),
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < slots.length; i++)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 280 + i * 25),
                curve: Interval(i * 25 / (280 + i * 25), 1, curve: monoEase),
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 6 * (1 - v)),
                    child: child,
                  ),
                ),
                child: SizedBox(
                  width: w,
                  height: 38,
                  child: () {
                    final enabled = isEnabled?.call(i) ?? true;
                    final on = i == value;
                    return MonoPop(
                      trigger: on ? value : null,
                      child: MonoPressable(
                        selected: on,
                        semanticLabel:
                            '${slots[i]}${enabled ? '' : ', unavailable'}',
                        onTap: enabled && !on
                            ? () {
                                MonoTick.play(context, strong: true);
                                onChanged(i);
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          decoration: BoxDecoration(
                            color: on ? t.ink : t.soft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: on ? t.ink : t.line),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            slots[i],
                            style: t
                                .text(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: on
                                      ? t.onInk
                                      : enabled
                                      ? t.ink
                                      : t.muted.withValues(alpha: 0.6),
                                )
                                .copyWith(
                                  decoration: enabled
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                          ),
                        ),
                      ),
                    );
                  }(),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ───────────────────────── Time ─────────────────────────

/// Hour and minute drums with an AM/PM switch.
class MonoTimePicker extends StatelessWidget {
  /// Creates a time picker.
  const MonoTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.minuteInterval = 5,
    this.use24h = false,
  });

  /// Selected time.
  final TimeOfDay value;

  /// Called with the new time.
  final ValueChanged<TimeOfDay> onChanged;

  /// Minute step.
  final int minuteInterval;

  /// 24-hour clock.
  final bool use24h;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final hours = use24h
        ? [for (var h = 0; h < 24; h++) h.toString().padLeft(2, '0')]
        : [for (var h = 1; h <= 12; h++) '$h'];
    final mins = [
      for (var m = 0; m < 60; m += minuteInterval) m.toString().padLeft(2, '0'),
    ];
    final pm = value.hour >= 12;
    final hIndex = use24h
        ? value.hour
        : (value.hour % 12 == 0 ? 12 : value.hour % 12) - 1;
    final mIndex = (value.minute / minuteInterval).round().clamp(
      0,
      mins.length - 1,
    );
    int to24(int idx, bool isPm) =>
        use24h ? idx : ((idx + 1) % 12) + (isPm ? 12 : 0);
    return Column(
      children: [
        SizedBox(
          height: 232,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 116 - 23,
                height: 46,
                child: MonoBand(theme: t),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      child: MonoDrumPicker(
                        items: hours,
                        value: hIndex,
                        showBand: false,
                        semanticLabel: 'Hour',
                        onChanged: (i) => onChanged(
                          TimeOfDay(hour: to24(i, pm), minute: value.minute),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        ':',
                        style: t.text(size: 28, weight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: MonoDrumPicker(
                        items: mins,
                        value: mIndex,
                        showBand: false,
                        semanticLabel: 'Minute',
                        onChanged: (i) => onChanged(
                          TimeOfDay(
                            hour: value.hour,
                            minute: i * minuteInterval,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!use24h) ...[
          const SizedBox(height: 8),
          MonoSegmented<bool>(
            options: const [false, true],
            value: pm,
            labelBuilder: (p) => p ? 'PM' : 'AM',
            semanticLabel: 'AM or PM',
            onChanged: (p) => onChanged(
              TimeOfDay(hour: to24(hIndex, p), minute: value.minute),
            ),
          ),
        ],
      ],
    );
  }
}
