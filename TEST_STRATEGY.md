# Bended Knee Test Strategy

## Scope

This document defines the testing strategy for the planned iOS Swift app.

## Test Layers

### Unit Tests

- Baseline averaging
- Angle normalization
- Bend proxy calculation
- Target deficit calculation
- Haptic zone mapping
- Hysteresis and threshold stability
- Pocket-side/orientation normalization

### Integration Tests

- Calibration countdown flow
- Calibration success/failure
- Session start/stop transitions
- Recalibration behavior
- Signal-loss and invalid-calibration recovery
- Settings persistence

### UI Tests

- Onboarding flow
- Calibration flow
- Target adjustment
- Session controls
- Error/recovery flows
- Accessibility labels for primary controls

### Manual Device Validation

- Standing calibration
- Shallow bend
- Deep bend
- Left/right pocket behavior if supported
- Screen-facing-body vs screen-facing-out if supported
- Tight vs loose pocket stability
- Haptic audibility and subtlety
- Battery impact over session time
- Real-device run validation

## Mandatory Truthfulness Constraint

- No test may be claimed as passing unless it has actually been run and passed.
- If tests fail, the failures must be resolved before completion is claimed.

## Current Status

- Blocked pending project scaffolding and finalized requirements.
