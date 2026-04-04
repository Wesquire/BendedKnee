# Drop UX/UI Redesign Plan

> The goal: make Drop the most beautiful and user-friendly app in the world.
> Every phase builds on the last. No shortcuts. No skipped steps.

---

## Phase 1: Session Screen — The Hero Screenshot [COMPLETE]

The session screen is the single most important screen in the app. It's the screenshot that wins the award. Everything else exists to get the user here.

### 1.1 Neon Number Display
- Replace the current angle display with a massive number (50%+ screen width)
- Add stacked `.shadow()` layers to create a neon tube glow effect
- Glow color matches the current zone (gold = on target, coral = strong, cream = gentle, amber = medium)
- Zone color transitions animate with a 0.3s crossfade
- Add a subtle 1.0 to 1.04 scale pulse when zone changes

### 1.2 Arc Gauge
- Replace the rectangular progress bar with a 270-degree circular arc gauge
- Arc wraps above and around the angle number
- Fill progresses from left to right as angle approaches target
- Empty = faint cream outline, filled = zone color
- Thin stroke (3pt) — elegant, not chunky
- "TARGET 20°" in small caps centered below the number inside the arc

### 1.3 Simplified Session Layout
- Remove: primarySessionTitle text, primarySessionDetail paragraph, target-change tip paragraph
- Keep: neon number, arc gauge, target label, state badge (simplified), end session button
- End session button moved to bottom, low contrast, or swipe-down gesture
- Phone-removed state: number fades to 10% opacity, arc dims, a single pulsing circle appears center-screen

### 1.4 Near-Black Session Background
- Replace the plum-blue-ink gradient with near-black (#08080C) solid
- Add a single subtle plum radial glow at the top (ambient, not distracting)
- The neon number pops against true darkness

---

## Phase 2: Home Screen — The Instrument Panel [COMPLETE]

### 2.1 Arc Gauge on Home
- Same arc gauge component from the session screen, reused on home
- Uncalibrated state: dotted outline arc, "—°" inside, subtle breathing pulse
- Calibrated state: arc shows live angle, fills toward target
- Centered on screen, dominant element

### 2.2 Single Action Button
- Below the gauge: ONE button that changes label based on state
  - Uncalibrated: "Calibrate" (posterCoral)
  - Calibrating: transforms into countdown ring (fills over 7 seconds, number counts down inside)
  - Ready: "Skate" (posterGold on dark)
  - Post-session: "Skate Again"
- No other action buttons visible on the main surface

### 2.3 Tuning Drawer
- Small handle bar at bottom of screen (thin line + subtle chevron)
- Drag up to reveal half-sheet with frosted glass background
- Contents: target slider, haptics toggle, volume slider, test buttons, placement reference
- Collapsed by default
- Small gear icon in top-right corner also opens drawer

### 2.4 Remove All Redundant Copy
- Delete: hero card title/eyebrow/summary/guidance text, instructions card, calibration card paragraphs
- Keep only: angle number, "TARGET 20°", action button label
- All setup instructions move into the tuning drawer

### 2.5 Remove Welcome Back Screen
- Delete WelcomeBackView entirely
- Returning users go: Splash (2.5s) -> Home
- Remove showWelcomeBack from SessionViewModel and RootView

---

## Phase 3: Living Background & Breathing Gauge [COMPLETE]

### 3.1 Living Background (Lava Lamp)
- Use TimelineView to create slowly drifting color blobs
- Home mode: warm gold/coral/teal blobs on cream field, drifting with sinusoidal offsets
- Session mode: deep plum/midnight blobs on near-black, very subtle
- Movement is glacial — 30+ second cycles, never repeating exactly
- Respect Reduce Motion: static gradient fallback

### 3.2 Breathing Gauge Animation
- Idle gauge has a slow ambient pulse (opacity 0.7 to 1.0 over 3 seconds)
- Breathing rate quickens as deficit increases (syncs with haptic interval)
- On target: breathing stops, steady glow — visual peace as the reward
- Respect Reduce Motion: static fill, no pulse

---

## Phase 4: Haptic Choreography [COMPLETE]

### 4.1 Rhythmic Patterns Per Zone
- Gentle: single tap ... pause ... single tap (every 0.75s)
- Medium: double-tap ... pause ... double-tap (every 0.5s)
- Strong: triple rapid pulse ... pause ... triple rapid pulse (every 0.33s)
- Implement via CHHapticPattern with multiple events per pattern
- Each pulse within a pattern separated by 80-100ms

### 4.2 Musical Calibration Sequence
- Prep countdown: each second tick has a haptic + descending note
- Capture start: single firm tap
- Success: rising two-note pattern (strong tap, pause, stronger tap)
- Failure: descending two-note pattern (medium tap, pause, softer tap)

---

## Phase 5: Sound Redesign — Pentatonic Musical Tones [COMPLETE]

### 5.1 Zone Tones as Musical Notes
- Gentle: C5 (523 Hz) — soft, warm
- Medium: E5 (659 Hz) — present, noticeable
- Strong: G5 (784 Hz) — bright, urgent
- All notes from the same major pentatonic chord — they sound good in any order
- Tone envelope: soft attack (5ms fade-in), short sustain, gentle decay — not a hard sine beep

### 5.2 Calibration Sound Design
- Prep countdown: descending phrase (G4, F4, E4, D4, C4) — one note per second, getting quieter
- Success: rising perfect fifth (C5 then G5) — sounds like arrival
- Failure: descending minor second (E4 then Eb4) — gentle disappointment, not alarm
- Keep-alive tone: unchanged (inaudible, functional only)

### 5.3 Test Tone Preview
- Test sound button plays the gentle-medium-strong sequence in rapid succession
- User hears the musical relationship before skating

---

## Phase 6: Palette & Typography Unification [COMPLETE]

### 6.1 Three-Layer Palette
- Poster layer (backgrounds): cream (#FDF3D7), sunset gold (#F5B618), coral (#E84A2E)
- Neon layer (data/interactive): neon gold (#FFD54F), neon coral (#FF6B4A), neon teal (#00E5CC)
- Ink layer (text): deep ink (#1A0C10), muted ink (#4A2A24), faint ink (#6B4840 at 50%)
- Update AppTheme.swift with new values
- Map semantic roles: poster = surfaces, neon = data/actions, ink = reading

### 6.2 Unified Type Scale
- Metric: 160pt black rounded (session number only)
- Display: 64pt black rounded (home gauge number)
- Title: 24pt black rounded (section headings)
- Body: 16pt semibold rounded (primary text)
- Label: 13pt bold rounded (buttons, captions)
- Micro: 11pt bold rounded (eyebrows, badges)
- Remove all serif usage
- Update AppType with strict scale

### 6.3 Propagate Palette Through All Screens
- Update every view to use the new semantic color roles
- Ensure neon colors only appear on dark surfaces
- Ensure poster colors only appear on light surfaces
- Verify WCAG AA contrast for all text/background pairs

---

## Phase 7: Onboarding Cinema [COMPLETE]

### 7.1 Full-Screen Storytelling
- Remove the card container — content floats on the gradient
- Three frames with crossfade transitions between them
- Frame 1: phone-in-pocket illustration + "Phone in your left pocket."
- Frame 2: bending leg with angle lines + "Drop measures how deep you bend."
- Frame 3: pulse rings from phone + "Faster pulses mean: bend more."
- Build illustrations with SwiftUI shapes and animations

### 7.2 Swipe Navigation
- Add horizontal swipe gesture between frames
- Page dots at bottom (small, subtle)
- "Get Started" button only on final frame — large, warm gold, inviting
- No back button — swipe is the navigation

### 7.3 Remove Brand Bar
- No icon/title at top of onboarding — user just saw the splash
- Full screen for content

---

## Phase 8: Splash & Transitions [COMPLETE]

### 8.1 Splash Simplification
- Reduce to 2.5 seconds
- Icon only, centered, with spring scale animation (0.85 -> 1.0)
- App name fades in 0.5s after icon appears
- Remove secondary tagline paragraph and tertiary text
- Remove "Pocket coach for deeper knee bend" poster title

### 8.2 Screen Transition Animations
- Splash to onboarding/home: opacity crossfade (0.35s)
- Home to session: matched geometry on the arc gauge + crossfade
- Onboarding frame transitions: horizontal slide with parallax
- Drawer reveal: spring slide from bottom with backdrop blur

---

## Phase 9: Accessibility [COMPLETE]

### 9.1 Dynamic Type Support
- All label/body text scales with user's type size preference
- Gauge number uses minimum size but labels scale
- Drawer content reflows for larger sizes

### 9.2 VoiceOver
- Gauge: "Current bend angle: 18 degrees. Target: 20 degrees. 90 percent progress."
- Action button: "Calibrate standing position" / "Start skating session"
- Zone state: "Coaching zone: slightly upright. Bend a little more."

### 9.3 Reduce Motion
- Living background becomes static gradient
- Breathing gauge becomes static fill
- Zone changes are instant color swaps, no scale pulse
- Onboarding uses instant transitions, no parallax

### 9.4 Increase Contrast
- Neon glows become solid outlines
- Panel fills become fully opaque
- Text contrast jumps to WCAG AAA
- Arc gauge stroke thickens to 5pt

---

## Phase 10: Cleanup & Testing [COMPLETE]

### 10.1 Remove Dead Code
- Delete WelcomeBackView.swift
- Remove showWelcomeBack from SessionViewModel
- Remove welcome back UI test
- Remove any unused color/font definitions from AppTheme

### 10.2 Comprehensive Test Suite
- Update all existing tests for new UI structure
- Add tests for arc gauge calculations
- Add tests for drawer state management
- Add tests for haptic pattern sequencing
- Add tests for musical tone frequencies
- Add accessibility audit tests
- Run all tests, fix all failures

### 10.3 Full Build Verification
- Clean build
- Install on simulator
- Walk through every user flow
- Screenshot every state for verification

---

## Sequencing Rules

1. Each phase is self-contained and leaves the app in a buildable state
2. Tests are updated within each phase as needed (not deferred)
3. After each phase completes, both this plan and PROGRESS.md are updated
4. No phase begins until the user gives permission
5. the_rules.md is re-read before starting each new phase
