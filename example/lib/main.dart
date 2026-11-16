import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mono_pickers/mono_pickers.dart';

void main() => runApp(const GalleryApp());

/// The mono_pickers gallery: every picker in a realistic card.
class GalleryApp extends StatefulWidget {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  ThemeMode _mode = switch (Uri.base.queryParameters['theme']) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
  MonoFeedback _feedback = MonoFeedback.none;
  bool _rtl = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mono Pickers',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF3F3F1),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0B),
      ),
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final base = dark
            ? const MonoPickerThemeData.dark()
            : const MonoPickerThemeData.light();
        return MonoPickerTheme(
          data: base.copyWith(feedback: _feedback),
          child: Directionality(
            textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        );
      },
      home: Builder(
        builder: (context) => GalleryPage(
          feedback: _feedback,
          rtl: _rtl,
          onFeedback: (f) => setState(() => _feedback = f),
          onRtl: (r) => setState(() => _rtl = r),
          onToggleTheme: () => setState(() {
            final dark = Theme.of(context).brightness == Brightness.dark;
            _mode = dark ? ThemeMode.light : ThemeMode.dark;
          }),
        ),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({
    super.key,
    required this.feedback,
    required this.rtl,
    required this.onFeedback,
    required this.onRtl,
    required this.onToggleTheme,
  });

  final MonoFeedback feedback;
  final bool rtl;
  final ValueChanged<MonoFeedback> onFeedback;
  final ValueChanged<bool> onRtl;
  final VoidCallback onToggleTheme;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

String _money(double v) => '\$${v.toStringAsFixed(2)}';
String _mmss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

const _monthsShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
String _dateLabel(DateTime d) =>
    '${_wd[d.weekday - 1]}, ${_monthsShort[d.month - 1]} ${d.day}';

class _GalleryPageState extends State<GalleryPage> {
  String _filter = Uri.base.queryParameters['filter'] ?? 'all';

  // Fitness · body
  double _kg = 72.5;
  bool _lb = false;
  double _cm = 178;
  MonoLengthUnit _hUnit = MonoLengthUnit.cm;
  int _age = 27 - 13;
  int _fat = 18;
  MonoSex _sex = MonoSex.male;
  // Goal & plan
  String _goal = 'muscle';
  int _activity = 2;
  Set<int> _days = {0, 2, 4, 5};
  String _session = '60';
  // Workout
  Duration _rest = const Duration(seconds: 90);
  int _sets = 4, _reps = 12, _rpe = 8;
  // Shopping
  final List<int> _cart = [0, 2];
  RangeValues _price = const RangeValues(120, 480);
  late final List<double> _hist = List.generate(30, (i) {
    final x = i / 29;
    return (0.12 +
            0.88 * math.exp(-math.pow((x - 0.32) / 0.18, 2)) +
            0.35 *
                math.exp(-math.pow((x - 0.72) / 0.1, 2)) *
                (0.6 + 0.4 * math.sin(i * 2.1))) *
        0.9;
  });
  int _color = 1, _size = 2;
  // Checkout
  int _delivery = 0, _card = 0, _tip = 15;
  // Travel
  MonoPlace _from = const MonoPlace('BGW', 'Baghdad'),
      _to = const MonoPlace('IST', 'Istanbul');
  int _trip = 1, _cabin = 0;
  DateTime? _stayStart = _today().add(const Duration(days: 3));
  DateTime? _stayEnd = _today().add(const Duration(days: 7));
  List<int> _guests = [2, 1, 0, 1];
  // Tickets
  Set<String> _seats = {'F5', 'F6'};
  List<int> _tiers = [0, 0, 0, 0];
  late final DateTime _earlyEnds = DateTime.now().add(
    const Duration(hours: 2, minutes: 14, seconds: 55),
  );
  Timer? _clock;
  // Booking
  DateTime _day = _today().add(const Duration(days: 1));
  int? _slot;
  TimeOfDay _alarm = const TimeOfDay(hour: 7, minute: 30);
  // Home
  double _temp = 21.5;
  int _thermoMode = 0;
  double _bright = 0.64, _vol = 0.38;
  // Feedback
  int _rating = 4, _mood = 3;
  Set<String> _rateTags = {};
  // Habits
  final List<List<bool>> _habitDays = [
    [true, true, false, true, true, true, false],
    [true, true, true, true, true, true, false],
    [false, true, true, false, true, false, false],
  ];
  int _water = 5, _tod = 0;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    final sections = <(String, String, List<Widget>)>[
      (
        'fitness',
        'Fitness · Body',
        [_weight(t), _height(t), _ageCard(t), _bodyFat(t)],
      ),
      (
        'fitness',
        'Fitness · Goal & plan',
        [_goalCard(t), _activityCard(t), _weekCard(t)],
      ),
      (
        'fitness',
        'Fitness · Workout',
        [_dialCard(t), _stepperCard(t), _effortCard(t)],
      ),
      ('commerce', 'Shopping', [_cartCard(t), _priceCard(t), _variantCard(t)]),
      (
        'commerce',
        'Checkout',
        [_deliveryCard(t), _paymentCard(t), _tipCard(t)],
      ),
      ('travel', 'Travel', [_routeCard(t), _calendarCard(t), _guestsCard(t)]),
      ('tickets', 'Tickets', [_seatsCard(t), _tiersCard(t)]),
      ('booking', 'Booking & time', [_appointmentCard(t), _alarmCard(t)]),
      ('home', 'Home & media', [_thermoCard(t), _fillCard(t)]),
      ('feedback', 'Feedback', [_ratingCard(t), _moodCard(t)]),
      ('habits', 'Habits', [_habitsCard(t), _waterCard(t), _todCard(t)]),
    ];
    const filters = [
      ('all', 'All'),
      ('fitness', 'Fitness'),
      ('commerce', 'Shopping'),
      ('travel', 'Travel'),
      ('tickets', 'Tickets'),
      ('booking', 'Booking & time'),
      ('home', 'Home & media'),
      ('feedback', 'Feedback'),
      ('habits', 'Habits'),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1232),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 80),
              children: [
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FLUTTER PACKAGE · MONO_PICKERS',
                            style: t.text(
                              size: 11,
                              color: t.muted,
                              letterSpacing: 0.9,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mono Pickers',
                            style: t.text(size: 30, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '31 monochrome, animated pickers for fitness, shopping and checkout, travel, tickets, booking, smart home, feedback and habit tracking. Drag, flick, scroll or use the arrow keys.',
                            style: t.text(
                              size: 14,
                              color: t.muted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        MonoSegmented<MonoFeedback>(
                          options: MonoFeedback.values,
                          value: widget.feedback,
                          labelBuilder: (f) => switch (f) {
                            MonoFeedback.none => 'Silent',
                            MonoFeedback.sound => 'Tick sound',
                            MonoFeedback.haptic => 'Haptic',
                          },
                          onChanged: widget.onFeedback,
                        ),
                        MonoSegmented<bool>(
                          options: const [false, true],
                          value: widget.rtl,
                          labelBuilder: (r) => r ? 'RTL' : 'LTR',
                          onChanged: widget.onRtl,
                        ),
                        _chipButton(t, 'Theme', widget.onToggleTheme),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (id, label) in filters)
                      _filterChip(
                        t,
                        label,
                        _filter == id,
                        () => setState(() => _filter = id),
                      ),
                  ],
                ),
                for (final (group, title, cards) in sections)
                  if (_filter == 'all' || _filter == group)
                    _section(t, title, cards),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── layout helpers ─────────────

  Widget _section(
    MonoPickerThemeData t,
    String title,
    List<Widget> cards,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 12),
        child: Row(
          children: [
            Text(
              title,
              style: t.text(size: 13, weight: FontWeight.w600, color: t.muted),
            ),
            const SizedBox(width: 10),
            Expanded(child: Container(height: 1, color: t.line)),
          ],
        ),
      ),
      LayoutBuilder(
        builder: (context, c) {
          final cols = math.max(1, ((c.maxWidth + 16) / (320 + 16)).floor());
          final w = (c.maxWidth - 16 * (cols - 1)) / cols;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final card in cards)
                SizedBox(
                  width: card is _Card && card.wide && cols >= 2
                      ? w * 2 + 16
                      : w,
                  child: card,
                ),
            ],
          );
        },
      ),
    ],
  );

  Widget _chipButton(MonoPickerThemeData t, String label, VoidCallback onTap) =>
      MonoPressable(
        onTap: onTap,
        semanticLabel: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: t.line),
          ),
          child: Text(label, style: t.text(size: 12, color: t.muted)),
        ),
      );

  Widget _filterChip(
    MonoPickerThemeData t,
    String label,
    bool on,
    VoidCallback onTap,
  ) => MonoPressable(
    onTap: onTap,
    selected: on,
    semanticLabel: label,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: on ? t.ink : t.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: on ? t.ink : t.line),
      ),
      child: Text(
        label,
        style: t.text(size: 12, color: on ? t.onInk : t.muted),
      ),
    ),
  );

  Widget _readout(
    MonoPickerThemeData t,
    String value,
    String unit, {
    Widget? trailing,
    double size = 48,
  }) => SizedBox(
    height: 56,
    child: Row(
      children: [
        MonoOdometer(
          value,
          style: t.text(size: size, weight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: EdgeInsets.only(top: size * 0.35),
          child: Text(
            unit,
            style: t.text(size: 16, weight: FontWeight.w500, color: t.muted),
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    ),
  );

  Widget _caption(
    MonoPickerThemeData t,
    List<(String, bool)> parts, {
    TextAlign align = TextAlign.start,
  }) => Text.rich(
    TextSpan(
      children: [
        for (final (s, b) in parts)
          TextSpan(
            text: s,
            style: t.text(
              size: 13,
              weight: b ? FontWeight.w600 : FontWeight.w400,
              color: b ? t.ink : t.muted,
            ),
          ),
      ],
    ),
    textAlign: align,
  );

  Widget _pill(MonoPickerThemeData t, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
    decoration: BoxDecoration(
      color: t.soft,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: t.line),
    ),
    child: MonoSwapText(text, style: t.text(size: 13, weight: FontWeight.w600)),
  );

  Widget _subtotal(MonoPickerThemeData t, Widget left, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: DefaultTextStyle(
            style: t.text(size: 13, color: t.muted),
            child: left,
          ),
        ),
        MonoOdometer(value, style: t.text(size: 26, weight: FontWeight.w600)),
      ],
    ),
  );

  // ───────────── Fitness · Body ─────────────

  Widget _weight(MonoPickerThemeData t) {
    final shown = _lb ? (_kg * 2.20462).roundToDouble() : (_kg * 2).round() / 2;
    final bmi = _kg / math.pow(_cm / 100, 2);
    final cat = bmi < 18.5
        ? 'Underweight'
        : bmi < 25
        ? 'Healthy'
        : bmi < 30
        ? 'Overweight'
        : 'Obese';
    return _Card(
      title: 'Weight',
      badge: 'RulerPicker',
      snippet:
          'MonoRulerPicker(min: 30, max: 200, step: 0.5, majorInterval: 5)',
      children: [
        _readout(
          t,
          _lb ? '${shown.toInt()}' : shown.toStringAsFixed(1),
          _lb ? 'lb' : 'kg',
          trailing: MonoSegmented<bool>(
            options: const [false, true],
            value: _lb,
            labelBuilder: (l) => l ? 'lb' : 'kg',
            onChanged: (l) => setState(() => _lb = l),
          ),
        ),
        MonoRulerPicker(
          value: shown,
          min: _lb ? 66 : 30,
          max: _lb ? 440 : 200,
          step: _lb ? 1 : 0.5,
          majorInterval: _lb ? 10 : 5,
          midInterval: _lb ? 5 : 1,
          pixelsPerStep: _lb ? 8 : 10,
          semanticLabel: 'Weight',
          labelBuilder: (v) => v.toInt().toString(),
          onChanged: (v) => setState(() => _kg = _lb ? v / 2.20462 : v),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.soft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: t.line),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text('BMI ', style: t.text(size: 13, color: t.muted)),
                  Text(
                    bmi.toStringAsFixed(1),
                    style: t.text(size: 13, weight: FontWeight.w600),
                  ),
                  const Spacer(),
                  MonoSwapText(
                    cat,
                    style: t.text(size: 13, weight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, c) => SizedBox(
                        height: 14,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 4,
                              height: 6,
                              child: Row(
                                children: [
                                  for (final (f, o) in [
                                    (14, 0.14),
                                    (26, 0.55),
                                    (20, 0.14),
                                    (40, 0.14),
                                  ]) ...[
                                    Expanded(
                                      flex: f,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: t.ink.withValues(alpha: o),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                  ],
                                ],
                              ),
                            ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 500),
                              curve: monoSpring,
                              left:
                                  ((bmi - 15) / 25).clamp(0.0, 1.0) *
                                      c.maxWidth -
                                  7,
                              top: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: t.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: t.ink, width: 3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (final (f, s) in [
                          (14, '15'),
                          (26, '18.5'),
                          (20, '25'),
                          (40, '30'),
                        ])
                          Expanded(
                            flex: f,
                            child: Text(
                              s,
                              style: t.text(size: 10, color: t.muted),
                            ),
                          ),
                        Text('40', style: t.text(size: 10, color: t.muted)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _height(MonoPickerThemeData t) {
    final inches = (_cm / 2.54).round();
    return _Card(
      title: 'Height',
      badge: 'HeightPicker',
      snippet: 'MonoHeightPicker(cm: 178, unit: MonoLengthUnit.cm)',
      children: [
        _readout(
          t,
          _hUnit == MonoLengthUnit.cm
              ? '${_cm.round()}'
              : '${inches ~/ 12}′${inches % 12}″',
          _hUnit == MonoLengthUnit.cm ? 'cm' : '',
          trailing: MonoSegmented<MonoLengthUnit>(
            options: MonoLengthUnit.values,
            value: _hUnit,
            labelBuilder: (u) => u == MonoLengthUnit.cm ? 'cm' : 'ft',
            onChanged: (u) => setState(() => _hUnit = u),
          ),
        ),
        MonoHeightPicker(
          cm: _cm,
          unit: _hUnit,
          onChanged: (v) => setState(() => _cm = v),
        ),
      ],
    );
  }

  Widget _ageCard(MonoPickerThemeData t) => _Card(
    title: 'Age',
    badge: 'DrumPicker',
    snippet: "MonoDrumPicker(items: ages, suffix: 'years')",
    children: [
      _caption(t, [
        ('Born around ', false),
        ('${DateTime.now().year - (13 + _age)}', true),
      ]),
      MonoDrumPicker(
        items: [for (var a = 13; a <= 90; a++) '$a'],
        value: _age,
        suffix: 'years',
        semanticLabel: 'Age',
        majorEvery: 10,
        onChanged: (i) => setState(() => _age = i),
      ),
    ],
  );

  Widget _bodyFat(MonoPickerThemeData t) => _Card(
    title: 'Body fat',
    badge: 'BodyFatPicker',
    snippet: 'MonoBodyFatPicker(sex: MonoSex.male, value: 18)',
    children: [
      _readout(
        t,
        '$_fat',
        '%',
        trailing: MonoSegmented<MonoSex>(
          options: MonoSex.values,
          value: _sex,
          labelBuilder: (s) => s == MonoSex.male ? 'Male' : 'Female',
          onChanged: (s) => setState(() => _sex = s),
        ),
      ),
      MonoBodyFatPicker(
        value: _fat,
        sex: _sex,
        onChanged: (v) => setState(() => _fat = v),
      ),
    ],
  );

  // ───────────── Goal & plan ─────────────

  Widget _goalCard(MonoPickerThemeData t) => _Card(
    title: 'Main goal',
    badge: 'GoalPicker',
    snippet: 'MonoGoalPicker(options: goals, value: goal)',
    children: [
      MonoGoalPicker<String>(
        value: _goal,
        onChanged: (g) => setState(() => _goal = g),
        options: const [
          MonoTileOption(
            value: 'fat',
            title: 'Lose fat',
            subtitle: 'Burn fat, keep muscle',
            icon: Icons.local_fire_department_outlined,
          ),
          MonoTileOption(
            value: 'muscle',
            title: 'Build muscle',
            subtitle: 'Get stronger and bigger',
            icon: Icons.fitness_center_rounded,
          ),
          MonoTileOption(
            value: 'endurance',
            title: 'Endurance',
            subtitle: 'Run longer, breathe easier',
            icon: Icons.monitor_heart_outlined,
          ),
          MonoTileOption(
            value: 'health',
            title: 'Stay healthy',
            subtitle: 'Move more, feel better',
            icon: Icons.favorite_border_rounded,
          ),
        ],
      ),
    ],
  );

  static const _levels = [
    ('Sedentary', 'Desk job, little or no exercise', '1.20'),
    ('Lightly active', 'Walks or training 1–2× a week', '1.375'),
    ('Moderate', 'Training 3–4× a week', '1.55'),
    ('Very active', 'Hard training 5–6× a week', '1.725'),
    ('Athlete', 'Daily training or a physical job', '1.90'),
  ];

  Widget _activityCard(MonoPickerThemeData t) => _Card(
    title: 'Activity level',
    badge: 'LevelPicker',
    snippet: 'MonoLevelPicker(count: 5, value: 2)',
    children: [
      SizedBox(
        height: 60,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonoSwapText(
                    _levels[_activity].$1,
                    style: t.text(
                      size: 28,
                      weight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    _levels[_activity].$2,
                    style: t.text(size: 13, color: t.muted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: t.line),
              ),
              child: Text(
                'TDEE × ${_levels[_activity].$3}',
                style: t.text(size: 11, color: t.muted),
              ),
            ),
          ],
        ),
      ),
      MonoLevelPicker(
        value: _activity,
        labels: [for (final l in _levels) l.$1],
        onChanged: (v) => setState(() => _activity = v),
      ),
    ],
  );

  Widget _weekCard(MonoPickerThemeData t) {
    final n = _days.length;
    final msg = n == 0
        ? 'Pick at least one day'
        : n <= 2
        ? 'A gentle start that is easy to keep'
        : n <= 4
        ? 'Great balance of training and recovery'
        : n <= 6
        ? 'Ambitious: plan your recovery days'
        : 'No rest days: consider taking one off';
    return _Card(
      title: 'Training days',
      badge: 'WeekPicker',
      snippet: 'MonoWeekPicker(selected: {0, 2, 4})',
      children: [
        _readout(t, '$n', 'days / week'),
        MonoWeekPicker(
          selected: _days,
          onChanged: (d) => setState(() => _days = d),
        ),
        MonoSwapText(msg, style: t.text(size: 13, color: t.muted)),
        Text('Session length', style: t.text(size: 12, color: t.muted)),
        MonoSegmented<String>(
          options: const ['30', '45', '60', '90'],
          value: _session,
          expand: true,
          labelBuilder: (s) => s == '90' ? '90 min' : s,
          onChanged: (s) => setState(() => _session = s),
        ),
      ],
    );
  }

  // ───────────── Workout ─────────────

  Widget _dialCard(MonoPickerThemeData t) => _Card(
    title: 'Rest timer',
    badge: 'DialPicker',
    snippet:
        'MonoDialPicker(max: Duration(minutes: 5), step: Duration(seconds: 15))',
    children: [
      MonoDialPicker(value: _rest, onChanged: (d) => setState(() => _rest = d)),
    ],
  );

  Widget _stepperCard(MonoPickerThemeData t) {
    final secs = _sets * _reps * 3 + (_sets - 1) * _rest.inSeconds;
    return _Card(
      title: 'Sets × reps',
      badge: 'Stepper',
      snippet: "MonoStepper(label: 'Sets', min: 1, max: 10, value: 4)",
      children: [
        Row(
          children: [
            Expanded(
              child: MonoStepper(
                label: 'Sets',
                value: _sets,
                min: 1,
                max: 10,
                onChanged: (v) => setState(() => _sets = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Text(
                '×',
                style: t.text(
                  size: 30,
                  weight: FontWeight.w300,
                  color: t.muted,
                ),
              ),
            ),
            Expanded(
              child: MonoStepper(
                label: 'Reps',
                value: _reps,
                min: 1,
                max: 30,
                onChanged: (v) => setState(() => _reps = v),
              ),
            ),
          ],
        ),
        _caption(t, [
          ('${_sets * _reps}', true),
          (' total reps · about ', false),
          ('${math.max(1, (secs / 60).round())} min', true),
          (' with ${_mmss(_rest.inSeconds)} rest', false),
        ]),
        Row(
          children: [
            for (final (i, (s, r, l)) in const [
              (5, 5, 'Strength'),
              (3, 10, 'Muscle'),
              (3, 15, 'Endurance'),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: MonoPressable(
                  semanticLabel: '$s by $r, $l',
                  onTap: () => setState(() {
                    _sets = s;
                    _reps = r;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _sets == s && _reps == r ? t.ink : t.soft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.line),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$s × $r',
                          style: t.text(
                            size: 15,
                            weight: FontWeight.w600,
                            color: _sets == s && _reps == r ? t.onInk : t.ink,
                          ),
                        ),
                        Text(
                          l,
                          style: t.text(
                            size: 11,
                            color: _sets == s && _reps == r
                                ? t.onInk.withValues(alpha: 0.65)
                                : t.muted,
                          ),
                        ),
                      ],
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

  Widget _effortCard(MonoPickerThemeData t) {
    final v = _rpe;
    final label = v <= 2
        ? 'Very light'
        : v <= 4
        ? 'Light'
        : v <= 6
        ? 'Moderate'
        : v <= 8
        ? 'Hard'
        : v == 9
        ? 'Very hard'
        : 'Max effort';
    final desc = v <= 4
        ? 'Warm-up pace: you could chat the whole set'
        : v >= 10
        ? 'Nothing left: true failure'
        : 'About ${10 - v} rep${10 - v > 1 ? 's' : ''} left in the tank';
    return _Card(
      title: 'Effort',
      badge: 'EffortPicker · RPE',
      snippet: 'MonoEffortPicker(value: 8)',
      children: [
        _readout(t, '$v', '/ 10', trailing: _pill(t, label)),
        MonoEffortPicker(value: v, onChanged: (x) => setState(() => _rpe = x)),
        Text(desc, style: t.text(size: 13, color: t.muted)),
      ],
    );
  }

  // ───────────── Shopping ─────────────

  static const _products = [
    ('Oat latte', 'Large · extra shot', 4.5, Icons.coffee_outlined),
    ('Butter croissant', 'Warm', 3.2, Icons.bakery_dining_outlined),
  ];

  Widget _cartCard(MonoPickerThemeData t) {
    final total = [
      for (var i = 0; i < _products.length; i++) _products[i].$3 * _cart[i],
    ].fold<double>(0, (a, b) => a + b);
    final count = _cart.fold<int>(0, (a, b) => a + b);
    return _Card(
      title: 'Cart',
      badge: 'AddStepper',
      snippet: 'MonoAddStepper(quantity: 0, onChanged: (q) => …)',
      children: [
        for (var i = 0; i < _products.length; i++)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.soft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: t.line),
            ),
            child: Row(
              children: [
                MonoPop(
                  trigger: _cart[i] > 0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: t.line),
                    ),
                    child: Icon(_products[i].$4, size: 26, color: t.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _products[i].$1,
                        style: t.text(size: 14, weight: FontWeight.w600),
                      ),
                      Text(
                        '${_products[i].$2} · ${_money(_products[i].$3)}',
                        style: t.text(size: 12, color: t.muted),
                      ),
                    ],
                  ),
                ),
                MonoAddStepper(
                  quantity: _cart[i],
                  itemName: _products[i].$1,
                  onChanged: (q) => setState(() => _cart[i] = q),
                ),
              ],
            ),
          ),
        _subtotal(
          t,
          Text('Subtotal · $count item${count == 1 ? '' : 's'}'),
          _money(total),
        ),
      ],
    );
  }

  Widget _priceCard(MonoPickerThemeData t) {
    var homes = 0;
    for (var i = 0; i < _hist.length; i++) {
      final c = (i + 0.5) / _hist.length * 1000;
      if (c >= _price.start && c <= _price.end) {
        homes += (_hist[i] / 0.9 * 14).round();
      }
    }
    return _Card(
      title: 'Price range',
      badge: 'RangePicker',
      snippet: 'MonoRangePicker(min: 0, max: 1000, histogram: prices)',
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              MonoOdometer(
                '\$${_price.start.round()}',
                style: t.text(size: 34, weight: FontWeight.w600),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Text('to', style: t.text(size: 16, color: t.muted)),
              ),
              MonoOdometer(
                '\$${_price.end.round()}${_price.end >= 1000 ? '+' : ''}',
                style: t.text(size: 34, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
        MonoRangePicker(
          values: _price,
          histogram: _hist,
          onChanged: (v) => setState(() => _price = v),
        ),
        _caption(t, [('$homes', true), (' homes in this range', false)]),
      ],
    );
  }

  static const _colors = [
    ('Black', Color(0xFF1D1D1F)),
    ('Sand', Color(0xFFCBB994)),
    ('Olive', Color(0xFF6B7150)),
    ('Navy', Color(0xFF2B3550)),
    ('Cloud', Color(0xFFE9E8E4)),
  ];
  static const _sizes = [
    ('XS', 0),
    ('S', 9),
    ('M', 14),
    ('L', 2),
    ('XL', 6),
    ('XXL', 0),
  ];

  Widget _variantCard(MonoPickerThemeData t) {
    final q = _sizes[_size].$2;
    return _Card(
      title: 'Variant',
      badge: 'SwatchPicker · SizePicker',
      snippet:
          'MonoSwatchPicker(colors: tee.colors) · MonoSizePicker(sizes: tee.sizes)',
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Everyday tee',
                style: t.text(size: 16, weight: FontWeight.w600),
              ),
            ),
            Text('\$28', style: t.text(size: 16, color: t.muted)),
          ],
        ),
        Row(
          children: [
            Text('Color · ', style: t.text(size: 12, color: t.muted)),
            MonoSwapText(
              _colors[_color].$1,
              style: t.text(size: 12, weight: FontWeight.w600),
            ),
          ],
        ),
        MonoSwatchPicker(
          colors: [for (final c in _colors) c.$2],
          labels: [for (final c in _colors) c.$1],
          value: _color,
          onChanged: (i) => setState(() => _color = i),
        ),
        Text('Size', style: t.text(size: 12, color: t.muted)),
        MonoSizePicker(
          sizes: [for (final s in _sizes) s.$1],
          unavailable: {
            for (var i = 0; i < _sizes.length; i++)
              if (_sizes[i].$2 == 0) i,
          },
          value: _size,
          onChanged: (i) => setState(() => _size = i),
        ),
        q <= 3
            ? _caption(t, [
                ('Only ', false),
                ('$q left', true),
                (' in ${_sizes[_size].$1}', false),
              ])
            : _caption(t, [('In stock · ships tomorrow', false)]),
      ],
    );
  }

  // ───────────── Checkout ─────────────

  Widget _deliveryCard(MonoPickerThemeData t) {
    final arrive = _today().add(const Duration(days: 3));
    final opts = [
      MonoOption(
        value: 0,
        title: 'Standard',
        subtitle: 'Arrives ${_dateLabel(arrive)}',
        trailing: 'Free',
        icon: Icons.local_shipping_outlined,
      ),
      const MonoOption(
        value: 1,
        title: 'Express',
        subtitle: 'Tomorrow by 9 PM',
        trailing: '\$6.99',
        icon: Icons.bolt_rounded,
      ),
      const MonoOption(
        value: 2,
        title: 'Store pickup',
        subtitle: 'Ready today · 0.8 km away',
        trailing: 'Free',
        icon: Icons.storefront_outlined,
      ),
    ];
    return _Card(
      title: 'Delivery',
      badge: 'OptionPicker',
      snippet: 'MonoOptionPicker(options: deliveryOptions)',
      children: [
        MonoOptionPicker<int>(
          options: opts,
          value: _delivery,
          onChanged: (v) => setState(() => _delivery = v),
        ),
        _subtotal(
          t,
          const Text('Total'),
          _money(58 + (_delivery == 1 ? 6.99 : 0)),
        ),
      ],
    );
  }

  Widget _paymentCard(MonoPickerThemeData t) {
    const caps = [
      'Pay with credit •••• 4242',
      'Pay with debit •••• 1881',
      'Pay with wallet · \$120.00',
    ];
    return _Card(
      title: 'Payment',
      badge: 'CardCarousel',
      snippet: 'MonoCardCarousel(children: wallet.cards)',
      children: [
        MonoCardCarousel(
          value: _card,
          onChanged: (i) => setState(() => _card = i),
          children: const [
            MonoPaymentCard(title: 'Credit', number: '4242', expiry: '09/29'),
            MonoPaymentCard(
              title: 'Debit',
              style: MonoCardStyle.outline,
              number: '1881',
              expiry: '02/28',
            ),
            MonoPaymentCard(
              title: 'Wallet',
              style: MonoCardStyle.soft,
              balance: '\$120.00',
              footnote: 'Instant · no fees',
            ),
          ],
        ),
        Center(
          child: MonoSwapText(
            caps[_card],
            style: t.text(size: 13, color: t.muted),
          ),
        ),
      ],
    );
  }

  Widget _tipCard(MonoPickerThemeData t) => _Card(
    title: 'Tip',
    badge: 'TipPicker',
    snippet: 'MonoTipPicker(amount: 42.50, presets: [0, 10, 15, 20])',
    children: [
      _readout(
        t,
        _money(42.5 * _tip / 100),
        'tip',
        trailing: _pill(t, '$_tip%'),
      ),
      MonoTipPicker(
        amount: 42.5,
        value: _tip,
        onChanged: (v) => setState(() => _tip = v),
      ),
      _caption(t, [
        ('On a ', false),
        ('\$42.50', true),
        (' order · 100% goes to your courier', false),
      ]),
    ],
  );

  // ───────────── Travel ─────────────

  Widget _routeCard(MonoPickerThemeData t) {
    const prices = [189, 340, 720];
    return _Card(
      title: 'Flight',
      badge: 'RoutePicker',
      snippet: "MonoRoutePicker(from: MonoPlace('BGW', 'Baghdad'), to: …)",
      children: [
        MonoSegmented<int>(
          options: const [0, 1, 2],
          value: _trip,
          expand: true,
          labelBuilder: (i) => const ['One way', 'Round trip', 'Multi-city'][i],
          onChanged: (i) => setState(() => _trip = i),
        ),
        MonoRoutePicker(
          from: _from,
          to: _to,
          onSwap: () => setState(() {
            final f = _from;
            _from = _to;
            _to = f;
          }),
        ),
        MonoSegmented<int>(
          options: const [0, 1, 2],
          value: _cabin,
          expand: true,
          labelBuilder: (i) => const ['Economy', 'Premium', 'Business'][i],
          onChanged: (i) => setState(() => _cabin = i),
        ),
        _subtotal(
          t,
          Text(
            'Direct · 3 h 05 min · ${const ['one way', 'round trip', 'per leg'][_trip]}',
          ),
          '\$${(prices[_cabin] * (_trip == 1 ? 1.8 : 1)).round()}',
        ),
      ],
    );
  }

  Widget _calendarCard(MonoPickerThemeData t) {
    final nights = _stayStart != null && _stayEnd != null
        ? _stayEnd!.difference(_stayStart!).inDays
        : 0;
    String md(DateTime d) => '${_monthsShort[d.month - 1]} ${d.day}';
    return _Card(
      title: 'Stay dates',
      badge: 'RangeCalendar',
      snippet: 'MonoRangeCalendar(start: checkIn, end: checkOut)',
      children: [
        MonoRangeCalendar(
          start: _stayStart,
          end: _stayEnd,
          onChanged: (s, e) => setState(() {
            _stayStart = s;
            _stayEnd = e;
          }),
        ),
        _subtotal(
          t,
          _stayEnd == null
              ? const Text('Select check-out')
              : _caption(t, [
                  (md(_stayStart!), true),
                  (' → ', false),
                  (md(_stayEnd!), true),
                ]),
          '$nights ${nights == 1 ? 'night' : 'nights'}',
        ),
      ],
    );
  }

  Widget _guestsCard(MonoPickerThemeData t) {
    final g = _guests[0] + _guests[1];
    final parts = [
      '$g guest${g == 1 ? '' : 's'}',
      if (_guests[2] > 0) '${_guests[2]} infant${_guests[2] > 1 ? 's' : ''}',
      '${_guests[3]} room${_guests[3] > 1 ? 's' : ''}',
    ];
    return _Card(
      title: 'Guests',
      badge: 'CounterList',
      snippet: 'MonoCounterList(items: [adults, children, infants, rooms])',
      children: [
        MonoCounterList(
          items: const [
            MonoCounterItem(title: 'Adults', subtitle: 'Age 13+', min: 1),
            MonoCounterItem(title: 'Children', subtitle: 'Age 2–12'),
            MonoCounterItem(title: 'Infants', subtitle: 'Under 2', max: 4),
            MonoCounterItem(
              title: 'Rooms',
              subtitle: 'Max 4 guests each',
              min: 1,
            ),
          ],
          values: _guests,
          maxOf: (i, v) => i < 2
              ? 16 - (v[0] + v[1]) + v[i]
              : i == 2
              ? 4
              : math.max(1, math.min(8, v[0] + v[1])),
          onChanged: (v) => setState(() => _guests = v),
        ),
        _caption(t, [
          (parts.join(' · '), true),
          if (g > _guests[3] * 4)
            (' · add a room for more than 4 guests per room', false),
        ]),
      ],
    );
  }

  // ───────────── Tickets ─────────────

  static final _rows = [
    for (final r in 'ABCDEFG'.split(''))
      MonoSeatRow(label: r, seats: 10, gapsAfter: const [2, 8], price: 12),
    const MonoSeatRow(
      label: 'H',
      seats: 8,
      gapsAfter: [2, 6],
      wide: true,
      price: 18,
    ),
  ];
  static final _taken = {
    for (var r = 0; r < 8; r++)
      for (var s = 1; s <= 10; s++)
        if ((r * 11 + s * 7 + r * s) % 6 == 0 || (r == 4 && s >= 4 && s <= 7))
          '${'ABCDEFGH'[r]}$s',
  };

  Widget _seatsCard(MonoPickerThemeData t) {
    final ids = _seats.toList()..sort();
    final sum = ids.fold<double>(
      0,
      (a, id) => a + (id.startsWith('H') ? 18 : 12),
    );
    Widget lg(String text, Color? fill, Color? border, {double w = 14}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: w,
          height: 13,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(5),
              bottom: Radius.circular(3),
            ),
            border: border == null
                ? null
                : Border.all(color: border, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: t.text(size: 11.5, color: t.muted)),
      ],
    );
    return _Card(
      wide: true,
      title: 'Cinema seats',
      badge: 'SeatPicker',
      snippet:
          'MonoSeatPicker(rows: hall.rows, taken: hall.taken, maxSelection: 6)',
      children: [
        MonoSeatPicker(
          rows: _rows,
          taken: _taken,
          selected: _seats,
          onChanged: (s) => setState(() => _seats = s),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 6,
          children: [
            lg('Available', null, t.ink.withValues(alpha: 0.5)),
            lg('Selected', t.ink, t.ink),
            lg('Taken', t.line, null),
            lg('Recliner \$18', null, t.ink.withValues(alpha: 0.5), w: 19),
          ],
        ),
        _subtotal(
          t,
          ids.isEmpty
              ? const Text('Tap seats to select (up to 6)')
              : _caption(t, [
                  (ids.join(', '), true),
                  (' · ${ids.length} seat${ids.length > 1 ? 's' : ''}', false),
                ]),
          _money(sum),
        ),
      ],
    );
  }

  Widget _tiersCard(MonoPickerThemeData t) {
    final left = _earlyEnds.difference(DateTime.now());
    final s = math.max(0, left.inSeconds);
    String p2(int n) => n.toString().padLeft(2, '0');
    final badge = '${p2(s ~/ 3600)}:${p2(s ~/ 60 % 60)}:${p2(s % 60)}';
    const prices = [25.0, 35.0, 90.0, 240.0];
    final n = _tiers.fold<int>(0, (a, b) => a + b);
    final total = [
      for (var i = 0; i < 4; i++) _tiers[i] * prices[i],
    ].fold<double>(0, (a, b) => a + b);
    return _Card(
      title: 'Concert',
      badge: 'TierPicker',
      snippet: 'MonoTierPicker(tiers: event.tiers, maxPerOrder: 8)',
      children: [
        MonoTierPicker(
          tiers: [
            MonoTier(
              title: 'Early bird',
              subtitle: 'General admission',
              price: _money(25),
              badge: badge,
            ),
            MonoTier(
              title: 'General',
              subtitle: 'Standing · all areas',
              price: _money(35),
            ),
            MonoTier(
              title: 'VIP',
              subtitle: 'Lounge, fast entry, merch',
              price: _money(90),
            ),
            MonoTier(
              title: 'Backstage',
              subtitle: 'Meet the band',
              price: _money(240),
              soldOut: true,
            ),
          ],
          quantities: _tiers,
          onChanged: (q) => setState(() => _tiers = q),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: n == 0 ? 0.3 : 1,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: t.ink,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  n == 0
                      ? 'Select tickets'
                      : 'Checkout · $n ticket${n > 1 ? 's' : ''} · ',
                  style: t.text(
                    size: 14,
                    weight: FontWeight.w600,
                    color: t.onInk,
                  ),
                ),
                if (n > 0)
                  MonoOdometer(
                    _money(total),
                    style: t.text(
                      size: 14,
                      weight: FontWeight.w600,
                      color: t.onInk,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────── Booking ─────────────

  static const _slotLabels = [
    '09:00',
    '10:30',
    '12:00',
    '13:30',
    '15:00',
    '16:30',
    '18:00',
    '19:30',
  ];

  Widget _appointmentCard(MonoPickerThemeData t) {
    final di = _day.difference(_today()).inDays;
    bool free(int si) =>
        ((di * 7 + si * 13 + di * si) % 5) != 0 && !(di == 0 && si < 3);
    return _Card(
      title: 'Appointment',
      badge: 'DateStrip · SlotPicker',
      snippet: 'MonoDateStrip(days: 45) · MonoSlotPicker(slots: availability)',
      children: [
        MonoDateStrip(
          value: _day,
          isEnabled: (d) => d.weekday != DateTime.sunday,
          onChanged: (d) => setState(() {
            _day = d;
            _slot = null;
          }),
        ),
        MonoSlotPicker(
          slots: _slotLabels,
          value: _slot,
          isEnabled: free,
          onChanged: (i) => setState(() => _slot = i),
        ),
        _slot == null
            ? _caption(t, [('Pick a time', false)])
            : _caption(t, [
                (_dateLabel(_day), true),
                (' at ', false),
                (_slotLabels[_slot!], true),
              ]),
      ],
    );
  }

  Widget _alarmCard(MonoPickerThemeData t) {
    final now = TimeOfDay.now();
    var d =
        (_alarm.hour * 60 + _alarm.minute - now.hour * 60 - now.minute + 1440) %
        1440;
    if (d == 0) d = 1440;
    return _Card(
      title: 'Alarm',
      badge: 'TimePicker',
      snippet: 'MonoTimePicker(minuteInterval: 5, use24h: false)',
      children: [
        MonoTimePicker(
          value: _alarm,
          onChanged: (v) => setState(() => _alarm = v),
        ),
        _caption(t, [
          ('Rings in ', false),
          ('${d ~/ 60} h ${d % 60} min', true),
        ], align: TextAlign.center),
      ],
    );
  }

  // ───────────── Home & media ─────────────

  Widget _thermoCard(MonoPickerThemeData t) {
    const room = 19.0;
    final diff = _temp - room;
    final caption = _thermoMode == 2
        ? 'Auto'
        : diff.abs() < 0.25
        ? 'Holding'
        : diff > 0
        ? 'Heating'
        : 'Cooling';
    return _Card(
      title: 'Thermostat',
      badge: 'RingDial',
      snippet: "MonoRingDial(min: 10, max: 30, step: 0.5, unit: '°')",
      children: [
        MonoRingDial(
          value: _temp,
          ambient: room,
          caption: caption,
          onChanged: (v) => setState(() => _temp = v),
        ),
        MonoSegmented<int>(
          options: const [0, 1, 2],
          value: _thermoMode,
          expand: true,
          labelBuilder: (i) => const ['Heat', 'Cool', 'Auto'][i],
          onChanged: (i) => setState(() => _thermoMode = i),
        ),
        _caption(t, [
          ('Room is ', false),
          ('${room.toStringAsFixed(1)}°', true),
          (
            diff.abs() < 0.25
                ? ' · at target'
                : ' · reaches ${_temp.toStringAsFixed(1)}° in about ',
            false,
          ),
          if (diff.abs() >= 0.25) ('${(diff.abs() * 12).round()} min', true),
        ]),
      ],
    );
  }

  Widget _fillCard(MonoPickerThemeData t) => _Card(
    title: 'Controls',
    badge: 'FillSlider',
    snippet:
        'MonoFillSlider(value: 0.64, icon: (v, c) => MonoSunIcon(value: v, color: c))',
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (label, v, setter, icon) in [
            (
              'Brightness',
              _bright,
              (double x) => setState(() => _bright = x),
              (double v, Color c) => MonoSunIcon(value: v, color: c) as Widget,
            ),
            (
              'Volume',
              _vol,
              (double x) => setState(() => _vol = x),
              (double v, Color c) =>
                  MonoVolumeIcon(value: v, color: c) as Widget,
            ),
          ]) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  MonoFillSlider(
                    value: v,
                    onChanged: setter,
                    icon: icon,
                    semanticLabel: label,
                  ),
                  const SizedBox(height: 12),
                  Text(label, style: t.text(size: 12, color: t.muted)),
                  Text(
                    '${(v * 100).round()}%',
                    style: t.text(size: 15, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ],
  );

  // ───────────── Feedback ─────────────

  static const _rateLabels = ['Terrible', 'Bad', 'Okay', 'Good', 'Amazing'];

  Widget _ratingCard(MonoPickerThemeData t) {
    final tags = _rating <= 3
        ? const [
            'Late delivery',
            'Cold food',
            'Wrong item',
            'Packaging',
            'Courier',
          ]
        : const [
            'Fast delivery',
            'Tasty',
            'Friendly courier',
            'Good value',
            'Well packed',
          ];
    return _Card(
      title: 'Rating',
      badge: 'RatingPicker · TagPicker',
      snippet: 'MonoRatingPicker(max: 5) · MonoTagPicker(tags: reasons)',
      children: [
        Center(
          child: Text(
            'How was your order?',
            style: t.text(size: 20, weight: FontWeight.w600),
          ),
        ),
        MonoRatingPicker(
          value: _rating,
          labels: _rateLabels,
          onChanged: (v) => setState(() {
            if ((v <= 3) != (_rating <= 3)) _rateTags = {};
            _rating = v;
          }),
        ),
        Center(
          child: MonoSwapText(
            _rateLabels[_rating - 1],
            style: t.text(size: 14, weight: FontWeight.w600),
          ),
        ),
        MonoTagPicker(
          tags: tags,
          selected: _rateTags,
          onChanged: (s) => setState(() => _rateTags = s),
        ),
      ],
    );
  }

  Widget _moodCard(MonoPickerThemeData t) => _Card(
    title: 'Mood',
    badge: 'MoodPicker',
    snippet: 'MonoMoodPicker(value: 3, onChanged: (m) => …)',
    children: [
      MonoMoodPicker(value: _mood, onChanged: (v) => setState(() => _mood = v)),
    ],
  );

  // ───────────── Habits ─────────────

  Widget _habitsCard(MonoPickerThemeData t) {
    final habits = [
      MonoHabit(
        title: 'Read 20 min',
        icon: Icons.menu_book_outlined,
        days: _habitDays[0],
        streakBonus: 9,
      ),
      MonoHabit(
        title: 'Drink water',
        icon: Icons.water_drop_outlined,
        days: _habitDays[1],
        streakBonus: 23,
      ),
      MonoHabit(
        title: 'Meditate',
        icon: Icons.spa_outlined,
        days: _habitDays[2],
      ),
    ];
    final done = habits.where((h) => h.days[6]).length;
    return _Card(
      title: 'Today',
      badge: 'HabitCheck',
      snippet: 'MonoHabitCheck(habits: habits)',
      children: [
        MonoHabitCheck(
          habits: habits,
          onChanged: (h, d, v) => setState(() => _habitDays[h][d] = v),
        ),
        done == habits.length
            ? _caption(t, [('All done today', true), (' · nice work', false)])
            : _caption(t, [
                ('$done of ${habits.length}', true),
                (' habits done today', false),
              ]),
      ],
    );
  }

  Widget _waterCard(MonoPickerThemeData t) => _Card(
    title: 'Water',
    badge: 'CountPicker',
    snippet: 'MonoCountPicker(goal: 8, value: 5)',
    children: [
      _readout(t, '$_water', '/ 8 glasses'),
      MonoCountPicker(
        value: _water,
        onChanged: (v) => setState(() => _water = v),
      ),
      _water >= 8
          ? _caption(t, [('Goal reached', true), (' · 2.0 L today', false)])
          : _caption(t, [
              ('${(_water * 0.25).toStringAsFixed(2)} L', true),
              (' of 2.0 L · ${8 - _water} to go', false),
            ]),
    ],
  );

  Widget _todCard(MonoPickerThemeData t) => _Card(
    title: 'Reminder',
    badge: 'TimeOfDayPicker',
    snippet: 'MonoTimeOfDayPicker(value: 0)',
    children: [
      MonoTimeOfDayPicker(
        value: _tod,
        onChanged: (i) => setState(() => _tod = i),
      ),
      Center(
        child: MonoSwapText(
          'Remind me at ${const ['7:30 AM', '12:30 PM', '6:30 PM', '10:00 PM'][_tod]}',
          style: t.text(size: 13, color: t.muted),
        ),
      ),
    ],
  );
}

/// A gallery card: title, badge, content and a code snippet.
class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.badge,
    required this.snippet,
    required this.children,
    this.wide = false,
  });

  final String title;
  final String badge;
  final String snippet;
  final List<Widget> children;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final t = MonoPickerTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: t.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: t.text(size: 12, color: t.muted)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: t.line),
                ),
                child: Text(
                  badge.toUpperCase(),
                  style: t.text(size: 10, color: t.muted, letterSpacing: 0.4),
                ),
              ),
            ],
          ),
          for (final c in children) ...[const SizedBox(height: 14), c],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.line)),
            ),
            child: Text(
              snippet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: t
                  .text(size: 11, color: t.muted)
                  .copyWith(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const [
                      'SF Mono',
                      'Menlo',
                      'Roboto Mono',
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
