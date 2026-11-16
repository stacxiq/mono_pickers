import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mono_pickers/mono_pickers.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(420, 900),
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
}

/// A harness holding a value so pickers can be driven like in an app.
class Harness<T> extends StatefulWidget {
  const Harness({super.key, required this.initial, required this.builder});
  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<Harness<T>> createState() => HarnessState<T>();
}

class HarnessState<T> extends State<Harness<T>> {
  late T value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(value, (v) => setState(() => value = v));
}

void main() {
  testWidgets('every picker renders in light and dark, phone and desktop', (
    tester,
  ) async {
    final today = DateTime.now();
    Widget all() => Column(
      children: [
        MonoRulerPicker(
          value: 72.5,
          min: 30,
          max: 200,
          step: 0.5,
          majorInterval: 5,
          midInterval: 1,
          onChanged: (_) {},
        ),
        MonoHeightPicker(cm: 178, onChanged: (_) {}),
        MonoHeightPicker(cm: 178, unit: MonoLengthUnit.ftIn, onChanged: (_) {}),
        MonoDrumPicker(
          items: [for (var i = 13; i < 90; i++) '$i'],
          value: 14,
          suffix: 'years',
          onChanged: (_) {},
        ),
        MonoBodyFatPicker(value: 18, onChanged: (_) {}),
        MonoBodyFatPicker(value: 30, sex: MonoSex.female, onChanged: (_) {}),
        MonoGoalPicker<int>(
          value: 1,
          onChanged: (_) {},
          options: const [
            MonoTileOption(
              value: 0,
              title: 'Lose fat',
              subtitle: 'Burn fat',
              icon: Icons.local_fire_department,
            ),
            MonoTileOption(
              value: 1,
              title: 'Build muscle',
              subtitle: 'Get stronger',
              icon: Icons.fitness_center,
            ),
            MonoTileOption(
              value: 2,
              title: 'Endurance',
              subtitle: 'Run longer',
              icon: Icons.monitor_heart,
            ),
          ],
        ),
        MonoLevelPicker(value: 2, onChanged: (_) {}),
        MonoWeekPicker(selected: const {0, 2}, onChanged: (_) {}),
        MonoDialPicker(value: const Duration(seconds: 90), onChanged: (_) {}),
        MonoStepper(label: 'Sets', value: 4, onChanged: (_) {}),
        MonoEffortPicker(value: 8, onChanged: (_) {}),
        MonoAddStepper(quantity: 0, onChanged: (_) {}),
        MonoAddStepper(quantity: 2, onChanged: (_) {}),
        MonoRangePicker(
          values: const RangeValues(120, 480),
          histogram: List.generate(30, (i) => (i % 7) / 7),
          onChanged: (_) {},
        ),
        MonoSwatchPicker(
          colors: const [Colors.black, Colors.teal, Colors.orange],
          value: 1,
          onChanged: (_) {},
        ),
        MonoSizePicker(
          sizes: const ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
          unavailable: const {0, 5},
          value: 2,
          onChanged: (_) {},
        ),
        MonoOptionPicker<int>(
          value: 0,
          onChanged: (_) {},
          options: const [
            MonoOption(
              value: 0,
              title: 'Standard',
              subtitle: 'Arrives Friday',
              trailing: 'Free',
              icon: Icons.local_shipping,
            ),
            MonoOption(value: 1, title: 'Express', trailing: '\$6.99'),
          ],
        ),
        MonoCardCarousel(
          value: 0,
          onChanged: (_) {},
          children: const [
            MonoPaymentCard(title: 'Credit', number: '4242', expiry: '09/29'),
            MonoPaymentCard(
              title: 'Wallet',
              style: MonoCardStyle.soft,
              balance: '\$120.00',
            ),
          ],
        ),
        MonoTipPicker(amount: 42.5, value: 15, onChanged: (_) {}),
        MonoRoutePicker(
          from: const MonoPlace('BGW', 'Baghdad'),
          to: const MonoPlace('IST', 'Istanbul'),
          onSwap: () {},
        ),
        MonoRangeCalendar(
          start: today.add(const Duration(days: 3)),
          end: today.add(const Duration(days: 7)),
          onChanged: (_, _) {},
        ),
        MonoCounterList(
          items: const [
            MonoCounterItem(title: 'Adults', subtitle: 'Age 13+', min: 1),
            MonoCounterItem(title: 'Children'),
          ],
          values: const [2, 0],
          onChanged: (_) {},
        ),
        MonoSeatPicker(
          rows: const [
            MonoSeatRow(label: 'A', seats: 10, gapsAfter: [2, 8]),
            MonoSeatRow(label: 'H', seats: 8, wide: true),
          ],
          taken: const {'A3'},
          selected: const {'A5'},
          onChanged: (_) {},
        ),
        MonoTierPicker(
          tiers: const [
            MonoTier(title: 'Early bird', price: '\$25', badge: '02:14:55'),
            MonoTier(title: 'Backstage', price: '\$240', soldOut: true),
          ],
          quantities: const [1, 0],
          onChanged: (_) {},
        ),
        MonoDateStrip(
          value: today.add(const Duration(days: 1)),
          isEnabled: (d) => d.weekday != 7,
          onChanged: (_) {},
        ),
        MonoSlotPicker(
          slots: const ['09:00', '10:30', '12:00'],
          value: 1,
          isEnabled: (i) => i != 2,
          onChanged: (_) {},
        ),
        MonoTimePicker(
          value: const TimeOfDay(hour: 7, minute: 30),
          onChanged: (_) {},
        ),
        MonoTimePicker(
          value: const TimeOfDay(hour: 19, minute: 45),
          use24h: true,
          onChanged: (_) {},
        ),
        MonoRingDial(
          value: 21.5,
          ambient: 19,
          caption: 'Heating',
          onChanged: (_) {},
        ),
        MonoFillSlider(
          value: 0.64,
          icon: (v, c) => MonoSunIcon(value: v, color: c),
          onChanged: (_) {},
        ),
        MonoFillSlider(
          value: 0,
          icon: (v, c) => MonoVolumeIcon(value: v, color: c),
          onChanged: (_) {},
        ),
        MonoRatingPicker(value: 4, onChanged: (_) {}),
        MonoTagPicker(
          tags: const ['Fast', 'Tasty'],
          selected: const {'Tasty'},
          onChanged: (_) {},
        ),
        MonoMoodPicker(value: 3, onChanged: (_) {}),
        MonoHabitCheck(
          habits: const [
            MonoHabit(
              title: 'Read',
              icon: Icons.book,
              days: [true, true, false, true, true, true, false],
            ),
          ],
          onChanged: (_, _, _) {},
        ),
        MonoCountPicker(value: 5, onChanged: (_) {}),
        MonoTimeOfDayPicker(value: 3, onChanged: (_) {}),
        MonoSegmented<String>(
          options: const ['kg', 'lb'],
          value: 'kg',
          onChanged: (_) {},
        ),
        MonoMiniStepper(value: 3, onChanged: (_) {}),
        const MonoOdometer('\$1,024.50'),
      ],
    );
    for (final size in const [Size(360, 900), Size(1200, 900)]) {
      for (final dark in const [false, true]) {
        await _pump(tester, all(), size: size, dark: dark);
        expect(tester.takeException(), isNull, reason: 'at $size, dark: $dark');
      }
    }
  });

  testWidgets('ruler: dragging changes the value and snaps to a step', (
    tester,
  ) async {
    double? v;
    await _pump(
      tester,
      Harness<double>(
        initial: 72.5,
        builder: (value, set) => MonoRulerPicker(
          value: value,
          min: 30,
          max: 200,
          step: 0.5,
          majorInterval: 5,
          onChanged: (x) {
            v = x;
            set(x);
          },
        ),
      ),
    );
    await tester.drag(find.byType(MonoRulerPicker), const Offset(-100, 0));
    await tester.pumpAndSettle();
    expect(v, isNotNull);
    expect(v! > 72.5, isTrue, reason: 'dragging left moves to higher values');
    expect((v! * 2) % 1, 0, reason: 'snaps to 0.5 steps');
  });

  testWidgets('ruler responds to arrow keys', (tester) async {
    late HarnessState<double> h;
    await _pump(
      tester,
      Harness<double>(
        initial: 50,
        builder: (value, set) => MonoRulerPicker(value: value, onChanged: set),
      ),
    );
    h = tester.state(find.byType(Harness<double>));
    await tester.tap(find.byType(MonoRulerPicker));
    await tester.pumpAndSettle();
    final before = h.value;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(h.value, before + 1);
  });

  testWidgets('drum: flick moves several items', (tester) async {
    late HarnessState<int> h;
    await _pump(
      tester,
      Harness<int>(
        initial: 10,
        builder: (value, set) => MonoDrumPicker(
          items: [for (var i = 0; i < 60; i++) '$i'],
          value: value,
          onChanged: set,
        ),
      ),
    );
    h = tester.state(find.byType(Harness<int>));
    await tester.fling(
      find.byType(MonoDrumPicker),
      const Offset(0, -150),
      1500,
    );
    await tester.pumpAndSettle();
    expect(h.value, greaterThan(12));
  });

  testWidgets('week: dragging paints days on', (tester) async {
    late HarnessState<Set<int>> h;
    await _pump(
      tester,
      Harness<Set<int>>(
        initial: const {},
        builder: (value, set) =>
            MonoWeekPicker(selected: value, onChanged: set),
      ),
    );
    h = tester.state(find.byType(Harness<Set<int>>));
    final r = tester.getRect(find.byType(MonoWeekPicker));
    final g = await tester.startGesture(
      Offset(r.left + r.width / 14, r.center.dy),
    );
    for (var i = 1; i <= 3; i++) {
      await g.moveTo(Offset(r.left + r.width * (2 * i + 1) / 14, r.center.dy));
      await tester.pump();
    }
    await g.up();
    await tester.pumpAndSettle();
    expect(h.value, {0, 1, 2, 3});
  });

  testWidgets('stepper: hold accelerates and respects max', (tester) async {
    late HarnessState<int> h;
    await _pump(
      tester,
      Harness<int>(
        initial: 1,
        builder: (value, set) =>
            MonoStepper(label: 'Reps', value: value, max: 6, onChanged: set),
      ),
    );
    h = tester.state(find.byType(Harness<int>));
    final g = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.add_rounded)),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await g.up();
    await tester.pumpAndSettle();
    expect(h.value, 6);
  });

  testWidgets('add stepper opens on Add and closes at zero', (tester) async {
    late HarnessState<int> h;
    await _pump(
      tester,
      Harness<int>(
        initial: 0,
        builder: (value, set) =>
            MonoAddStepper(quantity: value, onChanged: set),
      ),
    );
    h = tester.state(find.byType(Harness<int>));
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(h.value, 1);
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    expect(h.value, 0);
  });

  testWidgets('range keeps the minimum gap', (tester) async {
    late HarnessState<RangeValues> h;
    await _pump(
      tester,
      Harness<RangeValues>(
        initial: const RangeValues(100, 300),
        builder: (value, set) =>
            MonoRangePicker(values: value, minGap: 50, onChanged: set),
      ),
    );
    h = tester.state(find.byType(Harness<RangeValues>));
    final thumbs = find.byType(MonoThumb);
    await tester.drag(thumbs.first, const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(h.value.end - h.value.start, greaterThanOrEqualTo(50));
  });

  testWidgets('seats: limit and taken seats', (tester) async {
    late HarnessState<Set<String>> h;
    await _pump(
      tester,
      Harness<Set<String>>(
        initial: const {},
        builder: (value, set) => MonoSeatPicker(
          rows: const [MonoSeatRow(label: 'A', seats: 6)],
          taken: const {'A1'},
          maxSelection: 2,
          selected: value,
          onChanged: set,
        ),
      ),
    );
    h = tester.state(find.byType(Harness<Set<String>>));
    for (final label in [
      'Row A seat 1, taken',
      'Row A seat 2',
      'Row A seat 3',
      'Row A seat 4',
    ]) {
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pumpAndSettle();
    }
    expect(h.value, {'A2', 'A3'});
  });

  testWidgets('calendar: start then end, earlier date restarts', (
    tester,
  ) async {
    DateTime? s, e;
    final first = DateTime(2030, 1, 1);
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => MonoRangeCalendar(
          start: s,
          end: e,
          firstDate: first,
          initialMonth: first,
          onChanged: (a, b) => setState(() {
            s = a;
            e = b;
          }),
        ),
      ),
    );
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();
    expect(s, DateTime(2030, 1, 10));
    expect(e, DateTime(2030, 1, 14));
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    expect(s, DateTime(2030, 1, 5));
    expect(e, isNull);
  });

  testWidgets('time picker switches AM/PM', (tester) async {
    late HarnessState<TimeOfDay> h;
    await _pump(
      tester,
      Harness<TimeOfDay>(
        initial: const TimeOfDay(hour: 7, minute: 30),
        builder: (value, set) => MonoTimePicker(value: value, onChanged: set),
      ),
    );
    h = tester.state(find.byType(Harness<TimeOfDay>));
    await tester.tap(find.text('PM'));
    await tester.pumpAndSettle();
    expect(h.value, const TimeOfDay(hour: 19, minute: 30));
  });

  testWidgets('tip: custom percentage', (tester) async {
    late HarnessState<int> h;
    await _pump(
      tester,
      Harness<int>(
        initial: 15,
        builder: (value, set) =>
            MonoTipPicker(amount: 40, value: value, onChanged: set),
      ),
    );
    h = tester.state(find.byType(Harness<int>));
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    expect(h.value, 18);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(h.value, 19);
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(h.value, 0);
  });

  testWidgets('rating, mood and count respond to taps', (tester) async {
    var rating = 2, mood = 1, count = 3;
    await _pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Column(
          children: [
            MonoRatingPicker(
              value: rating,
              onChanged: (v) => setState(() => rating = v),
            ),
            MonoMoodPicker(
              value: mood,
              onChanged: (v) => setState(() => mood = v),
            ),
            MonoCountPicker(
              value: count,
              onChanged: (v) => setState(() => count = v),
            ),
          ],
        ),
      ),
    );
    final stars = tester.getRect(find.byType(MonoRatingPicker));
    await tester.tapAt(Offset(stars.center.dx + 60, stars.center.dy));
    await tester.pumpAndSettle();
    expect(rating, greaterThan(2));
    await tester.tap(find.bySemanticsLabel('Glass 3'));
    await tester.pumpAndSettle();
    expect(count, 2, reason: 'tapping the last filled glass empties it');
    await tester.tap(find.bySemanticsLabel('Glass 6'));
    await tester.pumpAndSettle();
    expect(count, 6);
  });

  testWidgets('theme feedback none does not call haptics', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (c) async {
        calls.add(c);
        return null;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MonoPickerTheme(
          data: const MonoPickerThemeData.light(feedback: MonoFeedback.none),
          child: Scaffold(
            body: Center(child: MonoLevelPicker(value: 0, onChanged: (_) {})),
          ),
        ),
      ),
    );
    await tester.tapAt(
      tester.getRect(find.byType(MonoLevelPicker)).centerRight -
          const Offset(10, 0),
    );
    await tester.pump();
    expect(calls.where((c) => c.method.startsWith('HapticFeedback')), isEmpty);
  });
}
