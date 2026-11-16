import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Plays tick feedback according to the ambient [MonoPickerThemeData].
abstract final class MonoTick {
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  /// Plays a tick. [strong] marks a major value (for example every 10 kg).
  /// Calls closer than 28 ms apart are dropped so fast flicks stay pleasant.
  static void play(BuildContext context, {bool strong = false}) {
    final mode = MonoPickerTheme.of(context).feedback;
    if (mode == MonoFeedback.none) return;
    final now = DateTime.now();
    if (now.difference(_last) < const Duration(milliseconds: 28)) return;
    _last = now;
    if (mode == MonoFeedback.haptic) {
      strong ? HapticFeedback.lightImpact() : HapticFeedback.selectionClick();
    } else {
      SystemSound.play(SystemSoundType.click);
    }
  }
}
