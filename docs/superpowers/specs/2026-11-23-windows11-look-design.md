# Snap11 1.4: back to a 1:1 Windows 11 look and feel

Approved 2026-11-23.

## Intent

Snap11's goal is to copy Windows 11 snapping 1:1, look and feel. Version
1.3.0 moved the look to the Plasma theme (pager tiles, KWin's tiling
outline, a picker laid out like KWin's Thumbnail Grid). That drifted away
from Windows 11. 1.4 brings the Windows 11 look back, drawn with the
Windows 11 (Fluent) design values, and closes the behavior gaps found in
the review.

## Goals

- Every overlay looks like its Windows 11 counterpart: Fluent surfaces
  (acrylic: blur plus a translucent tint, 8 px corners, 1 px stroke,
  shadow), Fluent text sizes, hover, pressed and focus states, Fluent
  motion (167 / 250 ms, decelerate easing).
- Light and dark come from the system (the Plasma color scheme), like
  Windows follows its app mode. The accent color comes from the system
  (Plasma's accent), with Windows' light/dark accent variants derived
  from it.
- Snap bar behaves like Windows 11 22H2+: a collapsed bar slides in at the
  top center as soon as a window is dragged, and expands when the dragged
  window's cursor reaches it.
- Windows 11 layout set and order: 50/50, 66/33, 33/33/33, 50 + 25/25,
  quarters, 25/50/25. Three-column layouts only on wide screens
  (work area width >= 1920 px), like Windows.
- Snap Assist like Windows 11: cards with icon and title on top and the
  thumbnail below, hover highlight, close button (red on hover), focus
  rectangle for keyboard use, the remaining empty zones shown as
  placeholders, a fade/scale-in.
- Drop preview like Windows 11: a free-standing acrylic rounded rectangle,
  inset from the work area edges, that grows out of the dragged window and
  morphs between targets.
- Fix: dragging along the top edge into a corner snaps to the quarter
  instead of maximizing.
- The notice about KDE's own edge snapping looks like a Windows 11 toast.

## Non-goals

- Snap groups (taskbar), Win+Z keyboard flow, snap suggestions with app
  icons (24H2).
- Window gaps: KDE's tile padding stays a KDE setting.

## Constraints

- KWin script (declarative QML), Plasma 6, Wayland. Overlays are
  PlasmaCore.Dialog windows (the only window type that shows reliably).
- KWin's blur effect blurs a script window only as a whole rectangle (the
  `kwin_blur` property; a region cannot be passed from QML). Each blurred
  surface therefore is its own window exactly the size of the surface; the
  rounded corners keep a hint of rectangular blur.
- No KWin in the development container: visuals are checked by rendering
  the QML offscreen with PySide6 against stub KDE modules.

## Approaches

1. **Draw everything with Fluent values in plain QtQuick (chosen).**
   Rectangles with Windows 11 colors, radii and strokes; blur through
   KWin's `kwin_blur`; colors switch with the system's light/dark scheme.
   The only way to get the Windows look 1:1.
2. Keep Plasma theme frames and retint them. Cannot reach the Windows
   shapes (Plasma SVG margins, pager tiles), so it fails the goal.
3. Ship a custom Plasma SVG theme for the overlays. Heavy, fragile across
   Plasma versions, and still limited by the frame model.

## Design

- `Fluent.qml`: one object with the Windows 11 tokens (dark/light picked
  from `Kirigami.Theme.backgroundColor` luminance), accent variants derived
  from `Kirigami.Theme.highlightColor`, radii, type ramp, durations,
  easing. All overlays read from it.
- `AcrylicSurface.qml`: the rounded surface (tint, stroke) used inside the
  blurred windows.
- `LayoutBar.qml`: collapsed/expanded states, single row of layouts, zones
  as rounded tiles, hovered zone filled with the accent.
- `SlotOutline.qml`: blurred window whose geometry animates.
- `SnapAssist.qml` + `ZonePlaceholder.qml`: active zone with cards, empty
  placeholders for the queued zones.
- `ConflictNotice.qml`: Windows 11 toast.
- Settings: Windows layout set on by default, new keys for 50 + 25/25 and
  25/50/25, "three columns only on wide screens" option, preview height
  follows the screen shape. Halves, 50 + 25/25 and quarters use KDE quick
  tiles; the other layouts use KDE custom tiles as before.

## Left to the builder

Exact pixel values where Windows publishes none (collapsed bar size,
preview inset, card spacing) are chosen to match Windows 11 screenshots.
