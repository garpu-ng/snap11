#!/usr/bin/env python3
"""Run a Snap11 preview scenario without KWin.

Loads tools/preview/Scene.qml, which loads the real snap11/contents/ui/main.qml
against stub KDE modules (tools/preview/stubs), then plays the scenario's
steps. Checks that fail, QML errors and warnings all count as failures.

Usage: run.py <scenario name> <output dir>
Exit code: number of failures (0 = all passed).

Needs PySide6 and a display with OpenGL (run.sh starts Xvfb).
"""
import sys
from pathlib import Path

from PySide6.QtCore import (QObject, QPoint, QTimer, QUrl, Property, Qt, Slot,
                            QtMsgType, qInstallMessageHandler)
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtTest import QTest

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
TIMEOUT_MS = 60000


class Runner(QObject):
    def __init__(self, view, scenario, outdir):
        super().__init__()
        self.view = view
        self.scenario = scenario
        self.outdir = Path(outdir)
        self.failures = 0
        self.checks = 0

    @Property(str, constant=True)
    def scenarioUrl(self):
        return QUrl.fromLocalFile(str(HERE / "scenarios" / (self.scenario + ".qml"))).toString()

    @Property(str, constant=True)
    def mainUrl(self):
        return QUrl.fromLocalFile(str(ROOT / "snap11" / "contents" / "ui" / "main.qml")).toString()

    @Slot(str)
    def passed(self, msg):
        self.checks += 1
        print("  ok   " + msg, flush=True)

    @Slot(str)
    def fail(self, msg):
        self.checks += 1
        self.failures += 1
        print("  FAIL " + msg, flush=True)

    @Slot(str)
    def shot(self, name):
        path = self.outdir / (name + ".png")
        self.view.grabWindow().save(str(path))
        print("  shot " + str(path), flush=True)

    @Slot(int)
    def key(self, code):
        QTest.keyClick(self.view, Qt.Key(code))

    @Slot(int, int)
    def mouseMove(self, x, y):
        # Only the first screen is on the virtual display.
        if 0 <= x < self.view.width() and 0 <= y < self.view.height():
            QTest.mouseMove(self.view, QPoint(x, y))

    @Slot(int, int)
    def click(self, x, y):
        QTest.mouseClick(self.view, Qt.LeftButton, Qt.NoModifier, QPoint(x, y))

    @Slot()
    def done(self):
        QTimer.singleShot(0, QGuiApplication.quit)


def main():
    scenario, outdir = sys.argv[1], sys.argv[2]
    Path(outdir).mkdir(parents=True, exist_ok=True)
    app = QGuiApplication(sys.argv[:1])
    view = QQuickView()
    runner = Runner(view, scenario, outdir)

    def on_message(mode, context, message):
        # console.info from the script (snap11: ...) is just a log line.
        if mode == QtMsgType.QtInfoMsg or mode == QtMsgType.QtDebugMsg:
            print("       " + message, flush=True)
            return
        # Qt's own noise about the virtual display is not ours.
        if "qt.qpa" in (context.category or "") or "XDG_RUNTIME_DIR" in message:
            return
        runner.fail("Qt: " + message)

    qInstallMessageHandler(on_message)
    view.engine().addImportPath(str(HERE / "stubs"))
    view.rootContext().setContextProperty("runner", runner)
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(1920, 1080)
    view.setSource(QUrl.fromLocalFile(str(HERE / "Scene.qml")))
    if view.status() != QQuickView.Ready:
        for e in view.errors():
            runner.fail("load: " + e.toString())
        return max(1, runner.failures)
    view.show()

    def timeout():
        runner.fail("timeout: scenario did not finish")
        QGuiApplication.quit()

    QTimer.singleShot(TIMEOUT_MS, timeout)
    app.exec()
    if runner.checks == 0:
        runner.fail("no checks ran")
    print(("PASS " if runner.failures == 0 else "FAIL ") + scenario
          + " (%d checks, %d failed)" % (runner.checks, runner.failures), flush=True)
    return min(runner.failures, 100)


if __name__ == "__main__":
    sys.exit(main())
