# Changelog

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
