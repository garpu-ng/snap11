# Changelog

## 1.4.1 (2026-11-23)

- Fixed: after snapping a window to a half or a layout zone, the mouse
  stopped working. Snap Assist failed to open in KWin, but its invisible
  click catcher over all screens was already up and stayed there,
  swallowing every click. Snap Assist opens again, and the click catcher
  never stays without it.
- Fixed: after moving the split between two snapped halves, the drop
  preview still showed 50/50 while the window landed at KDE's split.
  Halves, corner quarters and the snap bar's halves and quarters zones
  now follow KDE's split.
- For developers: the preview harness now provides `KWin` like KWin does
  (a global object, not part of the org.kde.kwin module), so this kind of
  error shows up in the tests. Quick tiles in the harness keep KDE's split.
  New scenarios: catcher, split.

## 1.4.0 (2026-11-23)

Back to the Windows 11 look and feel, 1:1.

- Everything is drawn like Windows 11 (Fluent): frosted glass, rounded
  corners, Windows' hover, pressed and focus states, Windows' motion.
  Light or dark and the accent color follow your system settings, like
  in Windows. The Plasma theme frames from 1.3 are gone.
- Snap bar like Windows 11: as soon as you drag a window, a small bar
  slides in at the top center; drag onto it and it opens with the
  layouts. The zone under the cursor fills with the accent color.
- Windows' layouts in Windows' order, on by default: 50/50, 66/33,
  33/33/33, half + two quarters (new), quarters, 25/50/25 (new).
  Three-column layouts only on screens 1920 px and wider, like Windows
  (option). One third + two thirds stays as an extra, off by default.
- Drop preview: floating frosted glass with the app's icon, inset from
  the screen edges, growing out of the window and gliding between zones.
- Snap Assist: cards like Windows 11 (icon and title on top, thumbnail
  below, close button turning red), Windows' focus rectangle for the
  keyboard, cards fade in, and the zones still to fill show as empty
  placeholders.
- The notice about KDE's own edge snapping is a Windows 11 toast.
- Fixed: dragging along the top edge into a corner maximized the window;
  it now snaps to that quarter.
- Halves + quarters layouts use KDE quick tiles.
- Settings: "Layout preview height" is gone (the layouts take the
  screen's shape); the layout width defaults to 80 px.
- New for developers: tools/preview runs the QML without KWin for tests
  and screenshots.

## 1.3.0 (2026-11-11)

Snap11 now looks like it is part of Plasma, and follows your theme.

- Fill available space, like Windows: with a window snapped against one
  side, snapping another window to the opposite edge makes it take exactly
  the space that is left (for example two thirds next to a third), and the
  outline shows that while you drag. Both windows become KDE quick tiles
  with the split where they meet, so dragging the border between them
  resizes both, like two halves. On by default (Behavior > Edge snapping).
- Layouts from the bar (thirds, two thirds + one third, quarters) use KDE's
  own tiles, so windows next to each other share a resize border there
  too. This replaces the layout from KDE's tile editor (Meta+T) on that
  screen; turn it off under Behavior > Snap layout bar.
- Drop preview: drawn like KWin's own quick tiling outline (the theme's
  translucent frame, no border along the screen edges) and slides out of
  the dragged window like KWin's does.
- Layout bar: Plasma's popup frame with the theme's blur, contrast and
  shadow; the layouts use the theme's pager tiles, the slot under the cursor
  lights up in your accent color.
- Window picker: laid out like KWin's "Thumbnail Grid" task switcher, in a
  Plasma popup frame: theme highlight on the selected window, app icon over
  the bottom of the thumbnail, title below, Plasma's own close button.
- The notice about KDE's own edge snapping looks like a Plasma
  notification; the warning on the settings page is KDE's warning banner.
- Sizes follow Plasma's spacing units, animations follow the global
  animation speed.
- Removed the color, opacity, dimming, blur and corner radius options: all
  of that comes from the Plasma theme now. Old values are ignored.

## 1.2.1 (2026-10-17)

- Warn when KDE's own edge snapping is still on: a notice in the bottom
  right corner (goes away by itself once it is off; the X hides it until
  the next login), and an orange note at the top of the settings page.

## 1.2.0 (2026-10-17)

- Snap11 now handles the outer screen edges itself too, with its own
  outline and blur, so every edge looks the same. Turn off KDE's own edge
  tiling (System Settings > Screen Edges) to use it.
- Corners snap to quarters.
- No Snap Assist over a part of the screen that a window is already
  snapped into, like in Windows.
- A window gets its old size back when you drag it out of a snap (halves,
  quarters and bar slots).

## 1.1.0 (2026-10-16)

- Snap at the edges between two monitors too. KDE only snaps at the outer
  screen edges; Snap11 now adds a small snap zone where monitors meet
  (options: on/off, zone width).
- Window picker cards behave like in Windows 11: icon and title on top,
  hover highlights the card and shows a close button, arrow keys and
  Enter work.

## 1.0.0 (2026-10-16)

First release.

- Snap Assist: snap a window to the left or right edge, pick a window for the
  free half from thumbnails.
- Snap layout bar at the top edge with halves and thirds; drop on a slot,
  then pick windows for the remaining slots.
- Drop at the top edge to maximize.
- Multi-monitor aware: picked windows move to the target screen.
- Click anywhere outside the window picker to close it and stop filling
  further slots; the clicked window gets the focus.
- Blur behind the drop outline and the window picker.
- Settings page with 24 options for behavior and appearance; optional extra
  layouts (two thirds + one third, one third + two thirds, quarters).
