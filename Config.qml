pragma Singleton
import Quickshell
import QtQuick

Singleton {
  id: root
  readonly property color background: "#1f1d2e"
  readonly property color selection:  "#363151"
  readonly property color foreground: "#c4a7e7"
  readonly property color inactive:   "#6e6a86"
  readonly property bool showBatteryPercent: true
}