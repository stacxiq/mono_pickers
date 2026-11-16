import 'package:flutter/widgets.dart';

/// Text whose digits roll like an odometer when they change.
///
/// Non-digit characters (units, separators, currency) are drawn as-is.
/// Digits use tabular figures so the width stays stable while rolling.
class MonoOdometer extends StatelessWidget {
  /// Creates an odometer for [text].
  const MonoOdometer(
    this.text, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 550),
  });

  /// The text to show.
  final String text;

  /// Text style, merged over the ambient [DefaultTextStyle].
  final TextStyle? style;

  /// Roll duration.
  final Duration duration;

  static const _curve = Cubic(0.2, 0.9, 0.25, 1.12);

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style
        .merge(style)
        .copyWith(
          height: 1.15,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final tp = TextPainter(
      text: TextSpan(text: '0', style: base),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final w = tp.width;
    final h = tp.height;
    final chars = text.characters.toList();
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < chars.length; i++)
            if (_isDigit(chars[i]))
              _Digit(
                key: ValueKey('d$i'),
                digit: int.parse(chars[i]),
                width: w,
                height: h,
                style: base,
                duration: duration,
              )
            else
              Text(chars[i], key: ValueKey('c$i${chars[i]}'), style: base),
        ],
      ),
    );
  }

  static bool _isDigit(String c) =>
      c.length == 1 && c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}

class _Digit extends StatelessWidget {
  const _Digit({
    super.key,
    required this.digit,
    required this.width,
    required this.height,
    required this.style,
    required this.duration,
  });

  final int digit;
  final double width;
  final double height;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: digit.toDouble()),
      duration: duration,
      curve: MonoOdometer._curve,
      builder: (context, v, _) => SizedBox(
        width: width,
        height: height,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: height * 10,
            maxHeight: height * 10,
            child: Transform.translate(
              offset: Offset(0, -v * height),
              child: Column(
                children: [
                  for (var k = 0; k < 10; k++)
                    SizedBox(
                      height: height,
                      child: Center(child: Text('$k', style: style)),
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
