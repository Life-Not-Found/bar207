// Battery.qml
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

RowLayout {
  id: root

  required property PanelWindow parentBar

  property var battery: UPower.displayDevice

  readonly property int pct: battery?.isPresent ?? false
    ? Math.round((battery.percentage ?? 0) * 100)
    : 75

  readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    || battery?.state === UPowerDeviceState.FullyCharged
    || battery?.state === UPowerDeviceState.PendingCharge

  readonly property string batteryIcon: {
    if (charging) {
      if (pct >= 90) return "󰂅"
      if (pct >= 80) return "󰂋"
      if (pct >= 70) return "󰂊"
      if (pct >= 60) return "󰢞"
      if (pct >= 50) return "󰂉"
      if (pct >= 40) return "󰢝"
      if (pct >= 30) return "󰂈"
      if (pct >= 20) return "󰂇"
      if (pct >= 10) return "󰂆"
      return "󰢜"
    } else {
      if (pct >= 90) return "󰂂"
      if (pct >= 80) return "󰂁"
      if (pct >= 70) return "󰂀"
      if (pct >= 60) return "󰁿"
      if (pct >= 50) return "󰁾"
      if (pct >= 40) return "󰁽"
      if (pct >= 30) return "󰁼"
      if (pct >= 20) return "󰁻"
      if (pct >= 10) return "󰁺"
      return "󰂎"
    }
  }

  readonly property color iconColor: {
    if (charging) return Config.foreground
    if (pct <= 10) return "#ff5555"
    if (pct <= 25) return "#ffb86c"
    return Config.foreground
  }

  readonly property string timeString: {
    var secs = charging ? (battery?.timeToFull ?? 0) : (battery?.timeToEmpty ?? 0)
    if (secs <= 0) return charging ? "Full" : ""
    var h = Math.floor(secs / 3600)
    var m = Math.floor((secs % 3600) / 60)
    if (h > 0) return h + "h " + m + "m"
    return m + "m"
  }

  spacing: 4

  Text {
    text: root.batteryIcon
    color: root.iconColor
  }

  Text {
    text: root.pct + "%"
    color: root.iconColor
    visible: Config.showBatteryPercent
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      var pos = root.mapToItem(null, 0, 0)
      batteryPopup.anchor.rect.x = pos.x - batteryPopup.implicitWidth / 2 + root.width / 2
      batteryPopup.anchor.rect.y = 48
      batteryPopup.visible = !batteryPopup.visible
    }
  }

  PopupWindow {
    id: batteryPopup
    visible: false
    anchor.window: root.parentBar
    anchor.rect.x: 0
    anchor.rect.y: 48

    implicitWidth: 200
    implicitHeight: batteryLayout.implicitHeight + 24
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      color: Config.background
      radius: 16
      border.width: 2
      border.color: Config.foreground

      HoverHandler {
        property bool hasHovered: false
        onHoveredChanged: {
          if (hovered) {
            hasHovered = true
          } else if (hasHovered && !hovered) {
            batteryPopup.visible = false
            hasHovered = false
          }
        }
      }

      ColumnLayout {
        id: batteryLayout
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
          topMargin: 16
          leftMargin: 16
          rightMargin: 16
        }
        spacing: 8

        Text {
          text: "Battery"
          color: Config.foreground
          font.pixelSize: 14
          font.bold: true
          Layout.bottomMargin: 4
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 12
          Text {
            text: root.batteryIcon
            color: root.iconColor
            font.pixelSize: 24
          }
          ColumnLayout {
            spacing: 2
            Text {
              text: root.pct + "%"
              color: Config.foreground
              font.pixelSize: 16
              font.bold: true
            }
            Text {
              text: {
                if (battery?.state === UPowerDeviceState.FullyCharged)
                  return "Fully charged"
                if (charging && timeString !== "" && timeString !== "Full")
                  return timeString + " until full"
                if (!charging && timeString !== "")
                  return timeString + " remaining"
                return charging ? "Charging" : "Discharging"
              }
              color: Config.inactive
              font.pixelSize: 12
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: 6
          radius: 3
          color: Config.inactive
          opacity: 0.4
          Rectangle {
            width: parent.width * (root.pct / 100)
            height: parent.height
            radius: parent.radius
            color: root.iconColor
            opacity: 1.0 / parent.opacity
          }
        }
      }
    }
  }
}