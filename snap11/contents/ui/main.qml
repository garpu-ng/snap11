/*
 * Snap11 - Windows 11 style snapping for KWin 6 (Wayland).
 *
 * Snap Assist after edge snapping:
 *   - Drag a window to the left/right screen edge. KDE's own quick tiling
 *     snaps it to that half.
 *   - Once the drag ends, we check whether the window now fills a half of
 *     its screen. If so, thumbnails of the other windows appear in the free
 *     half. Clicking one quick-tiles it there.
 *
 * Snap layout bar:
 *   - Drag a window to the top edge. A small bar with layouts (halves,
 *     thirds) appears at the top center. Drop the window on a slot and it
 *     lands there; then Snap Assist offers windows for the other slots,
 *     one slot after the other.
 *   - Dropping right at the top edge, but not on a slot, maximizes.
 *   - Needs KDE's "drag to top edge maximizes" turned off
 *     (kwinrc [Windows] ElectricBorderMaximize=false).
 *
 * In the picker, Escape or a click on empty space closes it.
 *
 * Debug output: journalctl --user -f | grep snap11
 */
import QtQuick
import QtQml
import org.kde.kwin

Item {
    id: root

    // Slack in px when comparing a window's geometry to a half of the screen.
    // Native quick tiles are inset by the tile padding (4px in kwinrc).
    readonly property int tolerance: 24
    // How close (px) the cursor must get to the top edge to open the bar.
    readonly property int topTrigger: cfg.topTrigger

    // Development only: reload.sh test flips this in its copy, so the
    // overlays open by themselves after loading and can be screenshotted.
    readonly property bool selfTest: false
    // Development only: reload.sh demo fills this with window classes. The
    // self test then runs on the smallest screen and only uses these
    // windows, so screenshots show nothing private.
    readonly property var demoClasses: []

    // Whether a window's current interactive operation is a move (not a
    // resize), keyed by internalId. Filled on drag start, read on drag end.
    property var moveStarted: ({})
    // Window whose drag just ended; checked after a short settle delay.
    property var pendingWindow: null
    // Drop on a bar slot (or maximize), applied right after the drag ended.
    property var pendingDrop: null
    // Cursor is at the top edge but not on a bar slot: dropping maximizes.
    property bool maximizeArmed: false
    // The drag reached the top edge (bar and/or maximize are in play), and
    // the work area of that screen.
    property bool topActive: false
    property rect topArea: Qt.rect(0, 0, 0, 0)
    // The cursor sits in the snap zone at an inner screen edge (where two
    // monitors meet): { slot, others }, or null.
    property var edgeArmed: null

    // Snap Assist chain: slots still to fill, and windows already placed
    // (they are not offered again).
    property var assistQueue: []
    property var assistPlaced: []

    function log(msg) {
        console.info("snap11: " + msg);
    }

    function isNormal(w) {
        return w && w.normalWindow && !w.skipTaskbar && !w.specialWindow
            && w.moveable && w.resizeable;
    }

    function onCurrentDesktop(w) {
        if (w.onAllDesktops)
            return true;
        const cur = Workspace.currentDesktop;
        for (let i = 0; i < w.desktops.length; i++) {
            if (w.desktops[i] === cur)
                return true;
        }
        return false;
    }

    // Usable area of a screen (without panels).
    function workArea(output) {
        return Workspace.clientArea(KWin.MaximizeArea, output, Workspace.currentDesktop);
    }

    // The whole screen, including panels.
    function screenArea(output) {
        return Workspace.clientArea(KWin.ScreenArea, output, Workspace.currentDesktop);
    }

    function halves(area) {
        const lw = Math.round(area.width / 2);
        return {
            "left": Qt.rect(area.x, area.y, lw, area.height),
            "right": Qt.rect(area.x + lw, area.y, area.width - lw, area.height)
        };
    }

    function matches(g, r) {
        const t = tolerance;
        return Math.abs(g.x - r.x) <= t && Math.abs(g.y - r.y) <= t
            && Math.abs(g.width - r.width) <= 2 * t && Math.abs(g.height - r.height) <= 2 * t;
    }

    // Other windows offered in the picker, topmost first. Minimized windows
    // show their icon instead of a thumbnail. With "same screen only", only
    // windows on the given output are offered.
    function candidatesFor(excluded, output) {
        const list = [];
        const stack = Workspace.stackingOrder;
        for (let i = stack.length - 1; i >= 0; i--) {
            const w = stack[i];
            // Our own overlays (pid -1, skipSwitcher) are not real windows.
            if (excluded.indexOf(w) >= 0 || !isNormal(w) || !onCurrentDesktop(w)
                    || w.skipSwitcher || w.pid <= 0)
                continue;
            if (!cfg.includeMinimized && w.minimized)
                continue;
            if (cfg.currentScreenOnly && output && w.output !== output)
                continue;
            list.push(w);
        }
        return list;
    }

    // Put a window into a slot. Halves use KDE's native quick tiling, so the
    // shared resize handle between two tiled windows keeps working.
    function place(w, slot) {
        log("placing '" + w.caption + "' into " + (slot.quickTile || "custom slot"));
        w.minimized = false;
        // Leave any native tile first, or KWin snaps the window back (and a
        // second quick tile to the same side would just untile it).
        if (w.tile)
            w.tile = null;
        w.setMaximize(false, false);
        // Move it onto the slot first. This also brings it to the right
        // screen: quick tiling always works on the window's current screen.
        w.frameGeometry = slot.rect;
        Workspace.activeWindow = w;
        if (slot.quickTile === "left")
            Workspace.slotWindowQuickTileLeft();
        else if (slot.quickTile === "right")
            Workspace.slotWindowQuickTileRight();
        log("  now at " + w.frameGeometry.x + "," + w.frameGeometry.y + " on " + w.output.name);
    }

    // Offer windows for each slot in the queue, one slot after the other.
    function startAssist(slots, placed) {
        assistQueue = slots;
        assistPlaced = placed;
        assistNext();
    }

    function assistNext() {
        if (assistQueue.length === 0)
            return;
        const slot = assistQueue[0];
        assistQueue = assistQueue.slice(1);
        const cands = candidatesFor(assistPlaced, slot.output);
        log("assist for next slot, " + cands.length + " candidates, " + assistQueue.length + " slots after this");
        if (cands.length > 0)
            openAssist(slot, cands);
        else
            assistQueue = [];
    }

    // Called shortly after a drag ended: did the window land in a half?
    function checkSnapped(w) {
        if (!cfg.edgeAssist || !isNormal(w))
            return;
        const h = halves(workArea(w.output));
        const g = w.frameGeometry;
        let slot = null;
        if (matches(g, h.left))
            slot = { "rect": h.right, "quickTile": "right", "output": w.output };
        else if (matches(g, h.right))
            slot = { "rect": h.left, "quickTile": "left", "output": w.output };
        if (!slot) {
            log("drag ended, not a half: " + g.x + "," + g.y + " " + g.width + "x" + g.height);
            return;
        }
        log("'" + w.caption + "' snapped to a half");
        startAssist([slot], [w]);
    }

    // Windows we watch for drags. A plain JS array, reassigned on change so
    // the Instantiator below rebuilds its per-window Connections. Using
    // Connections (instead of signal.connect) means everything disconnects
    // cleanly when the script is unloaded.
    property var watched: []

    function refreshWatched() {
        const list = [];
        const stack = Workspace.stackingOrder;
        for (let i = 0; i < stack.length; i++) {
            if (stack[i].normalWindow)
                list.push(stack[i]);
        }
        watched = list;
    }

    function dragStarted(w) {
        root.moveStarted[w.internalId.toString()] = w.move;
        if (assist.visible)
            assist.dismiss("new drag");
        assistQueue = [];
    }

    // While moving: at the top edge, open the bar and track the hovered
    // slot. Cursor right at the top edge but not on a slot means "maximize",
    // like KDE and Windows do.
    function dragStepped(w) {
        if (!root.moveStarted[w.internalId.toString()] || !isNormal(w))
            return;
        const p = Workspace.cursorPos;
        const atTop = p.y <= screenArea(w.output).y + topTrigger;
        // Inner screen edges: KDE only snaps at the outer edges, so handle
        // the edges between monitors here. The top edge takes priority.
        if (!atTop && !topActive) {
            const edge = innerEdgeAt(p);
            if (edge) {
                if (!edgeArmed || edgeArmed.slot.output !== edge.slot.output
                        || edgeArmed.slot.quickTile !== edge.slot.quickTile)
                    outline.showAt(edge.slot.rect);
                edgeArmed = edge;
                return;
            }
        }
        if (edgeArmed) {
            edgeArmed = null;
            outline.hide();
        }
        if (!topActive) {
            if (!atTop)
                return;
            topActive = true;
            topArea = workArea(w.output);
            if (cfg.layoutBar && bar.layouts.length > 0)
                bar.showOn(topArea, w.output);
        }
        // Anywhere along the top edge keeps the bar (and maximize) alive.
        if (!atTop && !(bar.visible && bar.isNear(p))) {
            endTop();
            return;
        }
        if (bar.visible)
            bar.hitTest(p);
        root.maximizeArmed = cfg.maximizeAtTop && atTop && bar.hoveredSlot < 0;
        const outlineWasVisible = outline.visible;
        if (bar.hoveredSlot >= 0)
            outline.showAt(bar.slotRect(bar.hoveredLayout, bar.hoveredSlot));
        else if (root.maximizeArmed)
            outline.showAt(topArea);
        else
            outline.hide();
        // A freshly shown outline lands on top; keep the bar above it.
        if (outline.visible && !outlineWasVisible && bar.visible)
            bar.bringToFront();
    }

    function screenAt(p) {
        const screens = Workspace.screens;
        for (let i = 0; i < screens.length; i++) {
            const g = screens[i].geometry;
            if (p.x >= g.x && p.x < g.x + g.width && p.y >= g.y && p.y < g.y + g.height)
                return screens[i];
        }
        return null;
    }

    // Is there another screen right next to s on that side, at height y?
    function hasNeighbour(s, side, y) {
        const g = s.geometry;
        const screens = Workspace.screens;
        for (let i = 0; i < screens.length; i++) {
            if (screens[i] === s)
                continue;
            const o = screens[i].geometry;
            if (y < o.y || y >= o.y + o.height)
                continue;
            if (side === "left" && Math.abs(o.x + o.width - g.x) <= 1)
                return true;
            if (side === "right" && Math.abs(o.x - (g.x + g.width)) <= 1)
                return true;
        }
        return false;
    }

    // Snap target when p is in the zone along an inner edge, else null.
    function innerEdgeAt(p) {
        if (!cfg.innerEdgeSnap)
            return null;
        const s = screenAt(p);
        if (!s)
            return null;
        const g = s.geometry;
        const zone = cfg.innerEdgeWidth;
        let side = "";
        if (p.x < g.x + zone && hasNeighbour(s, "left", p.y))
            side = "left";
        else if (p.x >= g.x + g.width - zone && hasNeighbour(s, "right", p.y))
            side = "right";
        if (!side)
            return null;
        const h = halves(workArea(s));
        const other = side === "left" ? "right" : "left";
        return {
            "slot": { "rect": h[side], "quickTile": side, "output": s },
            "others": [{ "rect": h[other], "quickTile": other, "output": s }]
        };
    }

    function endTop() {
        topActive = false;
        maximizeArmed = false;
        bar.hide();
        outline.hide();
    }

    function dragFinished(w) {
        const id = w.internalId.toString();
        const wasMove = root.moveStarted[id];
        delete root.moveStarted[id];
        if (!wasMove)
            return;
        if (bar.visible && bar.hoveredSlot >= 0) {
            const li = bar.hoveredLayout;
            const si = bar.hoveredSlot;
            const others = [];
            for (let i = 0; i < bar.layouts[li].length; i++) {
                if (i !== si)
                    others.push(bar.slot(li, i));
            }
            root.pendingDrop = { "window": w, "slot": bar.slot(li, si), "others": others };
            dropTimer.restart();
        } else if (topActive && root.maximizeArmed) {
            root.pendingDrop = { "window": w, "maximize": true };
            dropTimer.restart();
        } else if (edgeArmed) {
            root.pendingDrop = { "window": w, "slot": edgeArmed.slot, "others": edgeArmed.others,
                                 "edge": true };
            dropTimer.restart();
        } else {
            root.pendingWindow = w;
            settleTimer.restart();
        }
        edgeArmed = null;
        endTop();
    }

    Instantiator {
        model: root.watched
        delegate: Connections {
            required property var modelData
            target: modelData
            function onInteractiveMoveResizeStarted() {
                root.dragStarted(modelData);
            }
            function onInteractiveMoveResizeStepped() {
                root.dragStepped(modelData);
            }
            function onInteractiveMoveResizeFinished() {
                root.dragFinished(modelData);
            }
        }
    }

    // Give KWin a moment to finish applying the quick tile geometry.
    Timer {
        id: settleTimer
        interval: 200
        onTriggered: {
            const w = root.pendingWindow;
            root.pendingWindow = null;
            if (w)
                root.checkSnapped(w);
        }
    }

    // Apply a bar drop once KWin has finished the move; setting geometry
    // inside the finished signal can be overridden by the move itself.
    Timer {
        id: dropTimer
        interval: 50
        onTriggered: {
            const d = root.pendingDrop;
            root.pendingDrop = null;
            if (!d)
                return;
            if (d.maximize) {
                root.log("maximizing '" + d.window.caption + "'");
                if (d.window.tile)
                    d.window.tile = null;
                d.window.setMaximize(true, true);
                return;
            }
            root.place(d.window, d.slot);
            if (d.edge ? cfg.edgeAssist : cfg.assistAfterBarDrop)
                root.startAssist(d.others, [d.window]);
        }
    }

    // Delay between filling one slot and offering windows for the next.
    Timer {
        id: assistNextTimer
        interval: 150
        onTriggered: root.assistNext()
    }

    // Self test (also used to stage screenshots): on the largest screen,
    // show the bar hovering the middle third, then snap the topmost window
    // there to the left half and open the picker on the right, then close.
    function selfTestScreen() {
        const demo = demoClasses.length > 0;
        const screens = Workspace.screens;
        let best = screens[0];
        for (let i = 1; i < screens.length; i++) {
            const a = screens[i].geometry.width * screens[i].geometry.height;
            const b = best.geometry.width * best.geometry.height;
            if (demo ? a < b : a > b)
                best = screens[i];
        }
        return best;
    }

    function isDemoWindow(w) {
        return demoClasses.indexOf(w.resourceClass.toString()) >= 0;
    }

    function selfTestCandidates(excluded) {
        const all = candidatesFor(excluded, null);
        return demoClasses.length > 0 ? all.filter(isDemoWindow) : all;
    }

    // Demo: a tidy scene on the demo screen. Two windows side by side in
    // the background, the first demo class floating at the top center as if
    // it was being dragged there; the rest stay behind.
    function arrangeDemo() {
        const out = selfTestScreen();
        const a = workArea(out);
        const h = halves(a);
        const wins = selfTestCandidates([]);
        const byClass = {};
        for (let i = 0; i < wins.length; i++) {
            const w = wins[i];
            if (w.tile)
                w.tile = null;
            w.setMaximize(false, false);
            w.minimized = false;
            w.frameGeometry = Qt.rect(a.x + 80 + i * 40, a.y + 80 + i * 40,
                                      Math.round(a.width * 0.45), Math.round(a.height * 0.6));
            byClass[w.resourceClass.toString()] = w;
        }
        const left = byClass["org.kde.kate"];
        const right = byClass["org.kde.dolphin"];
        const front = byClass[demoClasses[0]];
        if (left) {
            left.frameGeometry = h.left;
            Workspace.activeWindow = left;
        }
        if (right) {
            right.frameGeometry = h.right;
            Workspace.activeWindow = right;
        }
        if (front) {
            const fw = Math.round(a.width * 0.5);
            const fh = Math.round(a.height * 0.55);
            front.frameGeometry = Qt.rect(a.x + Math.round((a.width - fw) / 2), a.y + 110, fw, fh);
            Workspace.activeWindow = front;
        }
        log("demo: arranged " + wins.length + " windows on " + out.name);
    }

    Timer {
        id: selfTestTimer
        interval: 500
        onTriggered: {
            const out = root.selfTestScreen();
            if (root.demoClasses.length > 0)
                root.arrangeDemo();
            root.log("self test on " + out.name + ": bar");
            bar.showOn(root.workArea(out), out);
            bar.hoveredLayout = bar.layouts.length - 1;
            bar.hoveredSlot = Math.min(1, bar.layouts[bar.hoveredLayout].length - 1);
            outline.showAt(bar.slotRect(bar.hoveredLayout, bar.hoveredSlot));
            bar.bringToFront();
            selfTestAssistTimer.start();
        }
    }

    Timer {
        id: selfTestAssistTimer
        interval: 4000
        onTriggered: {
            root.log("self test: assist");
            bar.hide();
            outline.hide();
            const out = root.selfTestScreen();
            const h = root.halves(root.workArea(out));
            const all = root.selfTestCandidates([]);
            // Demo: the first demo class goes left; otherwise the topmost
            // window on that screen.
            let anchor = null;
            for (let i = 0; i < all.length && !anchor; i++) {
                const ok = root.demoClasses.length > 0
                    ? all[i].resourceClass.toString() === root.demoClasses[0]
                    : all[i].output === out;
                if (ok && !all[i].minimized)
                    anchor = all[i];
            }
            // Only the demo moves windows; the plain self test leaves the
            // user's windows alone.
            if (anchor && root.demoClasses.length > 0)
                root.place(anchor, { "rect": h.left, "quickTile": "left" });
            selfTestAssistOpenTimer.anchor = anchor;
            selfTestAssistOpenTimer.start();
        }
    }

    // Open the picker once the snapped window has settled.
    Timer {
        id: selfTestAssistOpenTimer
        property var anchor: null
        interval: 400
        onTriggered: {
            const h = root.halves(root.workArea(root.selfTestScreen()));
            root.openAssist({ "rect": h.right, "quickTile": "right" },
                        root.selfTestCandidates(anchor ? [anchor] : []));
            assist.currentIndex = 0; // show the hover look
            selfTestEndTimer.start();
        }
    }

    Timer {
        id: selfTestEndTimer
        interval: 4000
        onTriggered: assist.dismiss("self test over")
    }

    Config {
        id: cfg
    }

    LayoutBar {
        id: bar
        cfg: cfg
    }

    ClickCatcher {
        id: catcher
        onClicked: function(pos) { root.catcherClicked(pos); }
    }

    // Plain and blurred variants of the overlays; the options pick one.
    SlotOutline {
        id: outlinePlain
        cfg: cfg
    }

    BlurredSlotOutline {
        id: outlineBlurred
        cfg: cfg
    }

    readonly property var outline: cfg.outlineBlur ? outlineBlurred : outlinePlain

    SnapAssist {
        id: assistPlain
        cfg: cfg
        onPicked: function(w, slot) { root.assistPicked(w, slot); }
        onVisibleChanged: root.assistVisibleChanged(visible)
    }

    BlurredSnapAssist {
        id: assistBlurred
        cfg: cfg
        onPicked: function(w, slot) { root.assistPicked(w, slot); }
        onVisibleChanged: root.assistVisibleChanged(visible)
    }

    readonly property var assist: cfg.assistBlur ? assistBlurred : assistPlain

    function assistPicked(w, slot) {
        assist.dismiss();
        place(w, slot);
        assistPlaced = assistPlaced.concat([w]);
        if (assistQueue.length > 0)
            assistNextTimer.restart();
    }

    // Show the click catcher first, so the picker (shown second) is
    // stacked above it.
    function openAssist(slot, cands) {
        catcher.showAll();
        assist.open(slot, cands);
    }

    // A click outside the picker: close it, stop the chain, and give the
    // click's target window the focus, as the click itself was swallowed.
    function catcherClicked(pos) {
        assist.dismiss("clicked elsewhere");
        root.assistQueue = [];
        const stack = Workspace.stackingOrder;
        for (let i = stack.length - 1; i >= 0; i--) {
            const w = stack[i];
            const g = w.frameGeometry;
            if (!isNormal(w) || w.minimized || w.pid <= 0 || !onCurrentDesktop(w))
                continue;
            if (pos.x >= g.x && pos.x < g.x + g.width && pos.y >= g.y && pos.y < g.y + g.height) {
                Workspace.activeWindow = w;
                break;
            }
        }
    }

    // Closed without picking (Escape, click outside): stop the chain.
    function assistVisibleChanged(visible) {
        if (!visible)
            catcher.hide();
        if (!visible && !assistNextTimer.running)
            Qt.callLater(function() {
                if (!assist.visible && !assistNextTimer.running)
                    root.assistQueue = [];
            });
    }

    Connections {
        target: Workspace
        function onWindowAdded(w) {
            root.refreshWatched();
        }
        function onWindowRemoved(w) {
            root.refreshWatched();
        }
        function onWindowActivated(w) {
            root.windowActivated(w);
        }
    }

    // A click anywhere else (another window, the desktop) activates that
    // window: close the picker and stop filling further slots. The picker
    // often never gets focus itself, so its own focus-out cannot be relied
    // on. Right after opening, KWin may still re-activate the dragged
    // window, hence the grace period.
    function windowActivated(w) {
        if (!assist.visible)
            return;
        if (w && w.pid <= 0)
            return; // one of our own overlays
        if (Date.now() - assist.openedAt < assist.focusGraceMs
                || Date.now() < assist.ignoreActivationUntil)
            return;
        assist.dismiss("clicked elsewhere");
    }

    // Re-read the options when they are changed in System Settings.
    Connections {
        target: Options
        function onConfigChanged() {
            cfg.load();
            root.log("options reloaded");
        }
    }

    Component.onCompleted: {
        cfg.load();
        refreshWatched();
        log("loaded, watching " + watched.length + " windows");
        if (selfTest)
            selfTestTimer.start();
    }
}
