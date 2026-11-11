# Changelog

## 1.3.0 (2026-11-11)

Snap11 now looks like it is part of Plasma, and follows your theme.

- Fill available space, like Windows: with a window snapped against one
  side, snapping another window to the opposite edge makes it take exactly
  the space that is left (for example two thirds next to a third), and the
  outline shows that while you drag. Both windows become KDE quick tiles
  with the split where they meet, so dragging the border between them
  resizes both, like two halves. On by default (Behavior > Edge snapping).
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
