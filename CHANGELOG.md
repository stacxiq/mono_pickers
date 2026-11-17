## 0.1.1

- Shorten the package description to fit pub.dev's 180-character limit.

- Silence the `package:flutter/material.dart` deprecation reported by newer analyzers, keeping support for older Flutter versions.
## 0.1.0

- Initial release: 31 animated, monochrome pickers.
  - Fitness: ruler, stadiometer height, 3D drum, morphing body-fat silhouette, goal tiles, activity levels, week days (drag to paint).
  - Workout: spring dial, press-and-hold stepper, effort (RPE) segments.
  - Shopping & checkout: add-to-cart stepper, histogram range, swatches, sizes, delivery options, card carousel + payment card, tip.
  - Travel & tickets: route swap, range calendar, counter list, cinema seats, ticket tiers.
  - Booking: date strip, time slots, time drums with AM/PM.
  - Home, feedback & habits: thermostat ring, fill sliders, star rating, tags, mood face, habit check, water glasses, time-of-day sun arc.
- Building blocks: `MonoOdometer`, `MonoSegmented`, `MonoMiniStepper`, `MonoAdjustable`, `MonoPop`, `MonoShake`, `MonoSwapText`, physics helpers.
- Light/dark `MonoPickerThemeData`, haptic/sound feedback, keyboard and screen-reader support, RTL.
