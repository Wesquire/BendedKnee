# Bended Knee Angle And Workflow

## What The App Measures

The app does not measure your true anatomical knee-joint angle.

It measures how much the phone in your front pocket tilts forward relative to gravity. Because the phone is fixed against your thigh, that tilt acts as a practical skating bend proxy.

## Raw Angle Math

The app uses `CMDeviceMotion.gravity` and computes:

`rawAngle = atan2(abs(gravity.z), max(0.001, -gravity.y)) * 180 / pi`

Meaning:

- `gravity.y` tracks how upright the phone is
- `gravity.z` tracks how far the phone has rotated forward
- `atan2` converts those gravity components into a forward tilt angle in degrees

## Baseline And Bend Proxy

During calibration:

1. The user stands upright and still in their skating pocket.
2. The app waits 3 seconds.
3. The app averages the sampled raw angles.
4. That average becomes the standing baseline.

During a session:

`bendProxyAngle = max(0, currentRawAngle - baselineAngle)`

So if your standing baseline is `6°` and your live raw angle is `24°`, the app reports a bend proxy of `18°`.

## Target Logic

The target is the number of degrees beyond the standing baseline that the skater wants to reach.

Example:

- baseline = `6°`
- target = `20°`
- required live raw angle to be on target = about `26°`

## Haptic Logic

The app computes:

`deficit = max(0, targetAngle - bendProxyAngle)`

Then it maps that deficit into haptic zones:

- `0..<0.5°`: no haptic
- `0.5..<5°`: gentle
- `5..<12°`: medium
- `12°+`: strong

The haptics are intentionally subtle and use cadence changes more than brute-force intensity.

## User Workflow

1. Open the app.
2. Confirm pocket side and target angle.
3. Place the phone in the front pocket, top-up, screen facing the thigh.
4. Stand upright and still.
5. Tap calibration.
6. Wait 3 seconds for baseline capture.
7. Start the session.
8. Skate while the app stays open and awake.
9. If you are not bent enough, the app increases haptic urgency based on the deficit.
10. If the phone leaves the pocket, haptics pause automatically.
11. When the phone returns to the pocket, the session resumes automatically.
