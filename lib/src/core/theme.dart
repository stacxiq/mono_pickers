import 'package:flutter/material.dart';

/// Feedback played when a picker crosses a value.
enum MonoFeedback {
  /// No feedback.
  none,

  /// Haptic ticks (selection clicks; stronger on major values).
  haptic,

  /// System click sounds.
  sound,
}

/// Colors and feedback for mono pickers.
///
/// mono pickers are monochrome: everything is drawn with [ink] at different
/// opacities on top of [surface], so a single color re-themes every picker.
@immutable
class MonoPickerThemeData {
  /// Creates a theme.
  const MonoPickerThemeData({
    required this.ink,
    required this.onInk,
    required this.surface,
    required this.muted,
    required this.line,
    required this.soft,
    this.feedback = MonoFeedback.haptic,
    this.fontFamily,
  });

  /// The light theme.
  const MonoPickerThemeData.light({
    this.feedback = MonoFeedback.haptic,
    this.fontFamily,
  }) : ink = const Color(0xFF111111),
       onInk = const Color(0xFFF3F3F1),
       surface = const Color(0xFFFFFFFF),
       muted = const Color(0xFF8A8A86),
       line = const Color(0x17000000),
       soft = const Color(0x0A000000);

  /// The dark theme.
  const MonoPickerThemeData.dark({
    this.feedback = MonoFeedback.haptic,
    this.fontFamily,
  }) : ink = const Color(0xFFF2F2F0),
       onInk = const Color(0xFF0A0A0B),
       surface = const Color(0xFF141415),
       muted = const Color(0xFF77777B),
       line = const Color(0x17FFFFFF),
       soft = const Color(0x0DFFFFFF);

  /// Primary drawing color (text, ticks, selected fills).
  final Color ink;

  /// Color drawn on top of [ink] (selected labels).
  final Color onInk;

  /// Card / knob fill.
  final Color surface;

  /// Secondary text.
  final Color muted;

  /// Hairlines and borders.
  final Color line;

  /// Subtle fills (unselected chips, tracks).
  final Color soft;

  /// Tick feedback.
  final MonoFeedback feedback;

  /// Font family for labels. Null uses the ambient font.
  final String? fontFamily;

  /// Returns a copy with the given fields replaced.
  MonoPickerThemeData copyWith({
    Color? ink,
    Color? onInk,
    Color? surface,
    Color? muted,
    Color? line,
    Color? soft,
    MonoFeedback? feedback,
    String? fontFamily,
  }) => MonoPickerThemeData(
    ink: ink ?? this.ink,
    onInk: onInk ?? this.onInk,
    surface: surface ?? this.surface,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    soft: soft ?? this.soft,
    feedback: feedback ?? this.feedback,
    fontFamily: fontFamily ?? this.fontFamily,
  );

  /// A text style in this theme.
  TextStyle text({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    color: color ?? ink,
    height: height,
    letterSpacing: letterSpacing ?? (size >= 24 ? -size * 0.025 : null),
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  bool operator ==(Object other) =>
      other is MonoPickerThemeData &&
      other.ink == ink &&
      other.onInk == onInk &&
      other.surface == surface &&
      other.muted == muted &&
      other.line == line &&
      other.soft == soft &&
      other.feedback == feedback &&
      other.fontFamily == fontFamily;

  @override
  int get hashCode =>
      Object.hash(ink, onInk, surface, muted, line, soft, feedback, fontFamily);
}

/// Provides a [MonoPickerThemeData] to the pickers below it.
class MonoPickerTheme extends InheritedWidget {
  /// Creates a theme scope.
  const MonoPickerTheme({super.key, required this.data, required super.child});

  /// The theme.
  final MonoPickerThemeData data;

  /// The nearest theme, or light/dark based on [Theme.of].
  static MonoPickerThemeData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MonoPickerTheme>();
    if (scope != null) return scope.data;
    return Theme.of(context).brightness == Brightness.dark
        ? const MonoPickerThemeData.dark()
        : const MonoPickerThemeData.light();
  }

  @override
  bool updateShouldNotify(MonoPickerTheme oldWidget) => oldWidget.data != data;
}

/// Spring-like curve used for selections and indicators.
const Curve monoSpring = Cubic(0.3, 1.3, 0.5, 1);

/// Bouncier curve used for pops.
const Curve monoBounce = Cubic(0.3, 1.5, 0.5, 1);

/// Smooth decelerating curve used for fades.
const Curve monoEase = Cubic(0.2, 0.8, 0.2, 1);
