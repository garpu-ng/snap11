# Snap11 1.4 Windows 11 look Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Plasma-theme look of Snap11's overlays with a 1:1 Windows 11 (Fluent) look and close the behavior gaps from the review.

**Architecture:** One `Fluent.qml` token object (light/dark from the system color scheme, accent from the system accent) feeds every overlay. Overlays are drawn with plain QtQuick; translucent ones (drop preview, Snap Assist, placeholders) are KWin-blurred windows exactly the size of the surface, near-opaque ones (bar, toast) draw their own shadow. A dev-only harness renders the real QML against stub KDE modules under Xvfb for tests and screenshots.

**Tech Stack:** QML (Qt 6, KWin declarative script API), Python 3 + PySide6 6.8 for the harness, Xvfb + Mesa llvmpipe.

**Spec:** `docs/superpowers/specs/2026-11-23-windows11-look-design.md`

## Global Constraints

- Light/dark: `Kirigami.Theme.backgroundColor` luminance < 0.5 means dark. Accent: `Kirigami.Theme.highlightColor`.
- Fluent values: overlay radius 8, control radius 4, caption 12 px, body 14 px, durations 167 / 250 ms scaled by `Kirigami.Units.longDuration / 200`, decelerate bezier (0,0,0,1), point-to-point bezier (0.55,0.55,0,1).
- Layout order: 50/50, 66/33, 33/33/33, 50 + 25/25, quarters, 25/50/25, then the extra 33/66. Three-column layouts only when the work area is >= 1920 px wide (option, on by default).
- Zones on screen are inset 8 px from work area edges and 4 px at inner edges.
- Only `snap11/` ships (tools/package.sh); the harness lives in `tools/preview/`.
- No PlasmaComponents / KSvg imports in overlays any more.

## Review Focus

1. Multi-monitor: bar, preview and assist must use the work area of the screen under the cursor, not the first screen.
2. A slot already filled is skipped by the assist and gets no placeholder.
3. Plasma animation speed set to instant (`longDuration` 0): nothing may wait on an animation to finish.
4. Light/dark switch while running: colors rebind (no cached colors).
5. Dragging along the top edge into a corner: quarter, not maximize.

---

### Task 1: Harness (stubs, simulator, runner)

**Files:**
- Create: `tools/preview/run.py`, `tools/preview/run.sh`, `tools/preview/Scene.qml`
- Create: `tools/preview/stubs/org/kde/kwin/{qmldir,Workspace.qml,KWin.qml,Options.qml,WindowThumbnail.qml}`
- Create: `tools/preview/stubs/org/kde/kirigami/{qmldir,Theme.qml,Units.qml,Icon.qml}`
- Create: `tools/preview/stubs/org/kde/plasma/core/{qmldir,Dialog.qml,Types.qml}`
- Create: `tools/preview/stubs/Snap11Sim/{qmldir,Sim.qml}`
- Create: `tools/preview/scenarios/smoke.qml`

**Interfaces:**
- Produces: `./tools/preview/run.sh <scenario> [outdir]` exits 0 when every check passed; PNGs land in outdir (default `dist/preview`).
- Scenario file: `QtObject { property var steps: [[delayMs, function() {...}], ...] }`.
- `Sim` singleton: `addWindow(props) -> window`, `dragStart(w, point)`, `dragTo(point)`, `dragEnd()`, `key(Qt.Key_*)`, `check(cond, msg)`, `shot(name)`, `setDark(bool)`, `setConfig(key, value)`, `snap` (the loaded main.qml root), `overlayLayer`, `nextZ()`, `calls` (list of quick tile slot names called).
- Stub `Workspace`: one 1920x1080 screen `"DP-1"`, work area 1920x1036 (44 px panel at the bottom), `clientArea`, `cursorPos`, `stackingOrder`, `activeWindow`, `slotWindowQuickTile*` (records the call, sets the active window to that rect, `tile = {}`), `rootTile()` returns null, signals `windowAdded/Removed/Activated`.
- Stub `Dialog`: an Item reparented into `Sim.overlayLayer`, sized to its first child, raised (`z = Sim.nextZ()`) when shown; with a `kwin_blur` property it draws the blurred desktop behind itself.

- [ ] **Step 1:** Write `scenarios/smoke.qml`: checks `Sim.snap !== null` and that `Sim.snap.watched.length === 2` after adding two windows.
- [ ] **Step 2:** Run `./tools/preview/run.sh smoke` before the stubs exist. Expected: FAIL (module not found).
- [ ] **Step 3:** Implement stubs, `Sim`, `Scene.qml` (wallpaper + fake windows layer + overlay layer + sequencer) and `run.py` (QQuickView, import path `tools/preview/stubs`, context object `runner` with `shot(name)`, `fail(msg)`, `done()`; exit code = number of failures).
- [ ] **Step 4:** Run `./tools/preview/run.sh smoke`. Expected: `PASS smoke`, exit 0. The current 1.3 overlays will not load (KSvg); that is fine for smoke as long as main.qml's own logic loads — stub `org.kde.ksvg` and `org.kde.plasma.components` minimally until Task 6 removes them.
- [ ] **Step 5:** Commit `tools/preview`.

### Task 2: Fluent tokens

**Files:**
- Create: `snap11/contents/ui/Fluent.qml`
- Modify: `snap11/contents/ui/main.qml` (instantiate `Fluent { id: fluent }`, pass `fluent: fluent` to overlays)
- Test: `tools/preview/scenarios/fluent.qml`

**Interfaces:**
- Produces (`QtObject`): `dark: bool`, colors `accentFill, textPrimary, textSecondary, flyoutFill, flyoutStroke, glassFill, glassStroke, zoneFill, zoneStroke, subtleHover, subtlePressed, closeHover, closePressed, focusOuter, focusInner, shadowColor`; ints `overlayRadius, controlRadius, captionSize, bodySize, durFast, durNormal, zoneInsetOuter, zoneInsetInner`; `fontFamily: string`; `decelerate, pointToPoint: list<real>` (6 values for `Easing.Bezier`); `accentVariant(c: color, dl: real): color` (HSL lightness shift, clamped 0.1..0.9); `zoneRect(r: rect, area: rect): rect`.
- Values: dark `textPrimary` #FFFFFF, `textSecondary` #C5FFFFFF, `subtleHover` #0FFFFFFF, `subtlePressed` #0AFFFFFF, `focusOuter` #FFFFFF, `focusInner` #B3000000, `flyoutFill` #F52C2C2C, accent fill = accentVariant(accent, +0.27); light `textPrimary` #E4000000, `textSecondary` #9E000000, `subtleHover` #09000000, `subtlePressed` #06000000, `focusOuter` #E4000000, `focusInner` #B3FFFFFF, `flyoutFill` #F5FCFCFC, accent fill = accentVariant(accent, -0.06); both `closeHover` #C42B1C, `closePressed` #E6C42B1C.

- [ ] **Step 1:** Test `fluent.qml`: dark theme → `fluent.dark`, `fluent.textPrimary == "#ffffff"`, `hslLightness(accentFill) > hslLightness(accent)` for accent #0078D4; light theme → `!fluent.dark`, accentFill darker; `zoneRect(Qt.rect(0,0,960,1036), Qt.rect(0,0,1920,1036))` equals `Qt.rect(8,8,948,1020)`.
- [ ] **Step 2:** Run `./tools/preview/run.sh fluent`. Expected: FAIL (`fluent` undefined).
- [ ] **Step 3:** Implement `Fluent.qml`, wire it in main.qml.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit.

### Task 3: Snap bar like Windows 11 (layouts, collapsed/expanded, corner fix)

**Files:**
- Modify: `snap11/contents/ui/LayoutBar.qml` (rewrite look and states)
- Modify: `snap11/contents/ui/main.qml` (`dragStarted`, `dragStepped`, `endTop`)
- Modify: `tools/gen_config.py`, `snap11/contents/ui/Config.qml` (regenerate `main.xml`, `config.ui`)
- Test: `tools/preview/scenarios/bar.qml`, `tools/preview/scenarios/corner.qml`

**Interfaces:**
- Consumes: `fluent` (Task 2).
- Produces (LayoutBar): `layoutsFor(width: int): list` ; `layouts` (for the current `area`); `expanded: bool`; `showOn(workArea: rect, screen)` shows collapsed; `track(p: point)` expands/collapses and updates `hoveredLayout/hoveredSlot`; `isNear(p)`, `slotRect(li, si)`, `slot(li, si)`, `bringToFront()`, `hide()` as today.
- Config keys: new `LayoutHalfQuarters` (Bool, true), `LayoutCenterWide` (Bool, true), `ThreeColumnsWideOnly` (Bool, true); changed defaults `LayoutTwoThirdsLeft` true, `LayoutQuarters` true, `PreviewWidth` 80; removed `PreviewHeight` (height follows the screen shape).
- Quick tiles: halves `left/right`; 50 + 25/25 `left/topRight/bottomRight`; quarters `topLeft/topRight/bottomLeft/bottomRight`. Others: custom.
- Metrics: padding 12, layout spacing 12, zone gap 4, zone radius 4, top margin 8, collapsed surface `max(120, 30 % of expanded width)` x 24; expand/collapse animates 250 ms decelerate; slide-in 167 ms.

- [ ] **Step 1:** `bar.qml`: drag start → `bar.visible && !bar.expanded`; cursor to the bar center → `bar.expanded`; `bar.layoutsFor(1920).length === 6` and `layoutsFor(1600).length === 4`; hover the left zone of layout 1 (66/33) → outline target `zoneRect(Qt.rect(0,0,1280,1036))`; drop → window frame `(0,0,1280,1036)`; screenshots `bar-collapsed`, `bar-expanded-dark`, `bar-expanded-light`.
- [ ] **Step 2:** `corner.qml`: drag start at (960,300), move to (960,2), then (3,2) → outline target `zoneRect` of the top-left quarter; drop → `Sim.calls` ends with `"topLeft"`.
- [ ] **Step 3:** Run both. Expected: FAIL.
- [ ] **Step 4:** Implement. In `dragStepped`, test `edgeAt()` before the top logic even while `topActive`, and call `endTop()` when it hits. Show the bar collapsed in `dragStarted` (move only, `cfg.layoutBar`), follow the cursor's screen in `dragStepped`.
- [ ] **Step 5:** Run both. Expected: PASS. Look at the screenshots.
- [ ] **Step 6:** Commit.

### Task 4: Drop preview

**Files:**
- Modify: `snap11/contents/ui/SlotOutline.qml` (rewrite)
- Test: `tools/preview/scenarios/outline.qml`

**Interfaces:**
- Consumes: `fluent.zoneRect`, `glassFill`, `glassStroke`, `overlayRadius`, `durNormal`, `pointToPoint`.
- Produces: `showAt(r: rect, workArea: rect, from: rect|null)`, `hide()`, `target: rect` (the inset rect), as today. The window itself is the surface (has `kwin_blur`) and animates its geometry from `from` (clipped, inset) to `target`.

- [ ] **Step 1:** `outline.qml`: drag a window to the left edge → after 400 ms the outline window's geometry equals `zoneRect(left half)`; move to the right edge → equals `zoneRect(right half)`; screenshot `outline-dark`.
- [ ] **Step 2:** Run. Expected: FAIL (geometry is the whole work area today).
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run. Expected: PASS.
- [ ] **Step 5:** Commit.

### Task 5: Snap Assist and placeholders

**Files:**
- Modify: `snap11/contents/ui/SnapAssist.qml` (rewrite)
- Create: `snap11/contents/ui/ZonePlaceholder.qml`
- Modify: `snap11/contents/ui/main.qml` (`assistNext`, `assistVisibleChanged`, placeholders `Instantiator`, model 3)
- Test: `tools/preview/scenarios/assist.qml`

**Interfaces:**
- SnapAssist keeps `open(slot, candidates)`, `dismiss(reason)`, `picked(window, slot)`, `currentIndex`, `openedAt`, `focusGraceMs`, `ignoreActivationUntil`; adds `keyboardNav: bool` (true after arrow/Tab keys, false on mouse hover); window = `fluent.zoneRect(slot.rect, workArea)`.
- Card: 8 px padding, header 32 px (16 px icon, 12 px title, close button 32x24, radius 4, visible on hover or selection, `closeHover` background with white glyph when hovered), thumbnail below, card radius 8 with `subtleHover` when selected, focus rectangle (2 px `focusOuter`, 1 px `focusInner`) when `keyboardNav`; card spacing 16; cards fade and scale in from 0.9 (167 ms decelerate).
- ZonePlaceholder: `show(slot, workArea)`, `hide()`; glass surface at `zoneRect`.
- main.qml: `showPlaceholders(slots)` / `hidePlaceholders()`; placeholders cover the queued, not yet filled slots after the active one.

- [ ] **Step 1:** `assist.qml`: three windows; drag one onto the left zone of the thirds layout → assist visible at `zoneRect(middle third)`, `candidates.length === 2`, placeholder 0 visible at `zoneRect(right third)`, placeholder 1 hidden; `Sim.key(Qt.Key_Right)` → `currentIndex === 0 && keyboardNav`; screenshots `assist-dark`, `assist-light`; Escape → assist and placeholders hidden.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run all scenarios. Expected: PASS.
- [ ] **Step 5:** Commit.

### Task 6: Toast notice, cleanup

**Files:**
- Modify: `snap11/contents/ui/ConflictNotice.qml` (rewrite as a Windows 11 toast)
- Modify: `snap11/contents/ui/main.qml` (pass `fluent`)
- Remove: KSvg / PlasmaComponents stubs from the harness once no file imports them
- Test: `tools/preview/scenarios/notice.qml`

**Interfaces:**
- Keeps `update(workArea, maximize, tiling)`. Surface 364 px wide, padding 16, header: 16 px icon + "Snap11" caption (secondary) + close button; title 14 px semibold; body 14 px; 12 px from the work area's bottom right corner; own shadow.

- [ ] **Step 1:** `notice.qml`: `Options.electricBorderTiling = true` then `configChanged()` → notice visible, its surface's right edge at 1920 - 12 and bottom at 1036 - 12; screenshot `notice-dark`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement; remove the KSvg / PlasmaComponents stubs; grep that no file in `snap11/` imports them.
- [ ] **Step 4:** Run all scenarios. Expected: PASS.
- [ ] **Step 5:** Commit.

### Task 7: Release 1.4.0 docs

**Files:**
- Modify: `snap11/metadata.json` (Version 1.4.0), `README.md`, `CHANGELOG.md`

- [ ] **Step 1:** CHANGELOG 1.4.0 entry (Windows 11 look back, light/dark and accent from the system, snap bar collapsed/expanded, Windows layout set, placeholders, corner fix, toast, option changes), README feature text and install commands to 1.4.0, a "Development" note on `tools/preview`.
- [ ] **Step 2:** Run `./tools/package.sh` (expected: `dist/snap11-1.4.0.kwinscript`) and all scenarios.
- [ ] **Step 3:** Commit and push.
