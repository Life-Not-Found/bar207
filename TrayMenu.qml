import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

PopupWindow {
  id: trayMenu
  visible: false
  color: "transparent"
  grabFocus: true

  property var trayItem: null
  property var parentBar: null

  anchor.window: parentBar

  implicitWidth: 200
  implicitHeight: menuLayout.implicitHeight + 23

  // QsMenuOpener is the correct way to access menu entries from a QsMenuHandle
  QsMenuOpener {
    id: menuOpener
    menu: trayMenu.trayItem?.menu ?? null
  }

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
          trayMenu.visible = false
          hasHovered = false
        }
      }
    }

    ColumnLayout {
      id: menuLayout
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        topMargin: 12
        leftMargin: 12
        rightMargin: 12
        bottomMargin: 12
      }
      spacing: 2

      // App title
      Text {
        text: trayMenu.trayItem?.title ?? ""
        color: Config.foreground
        font.pixelSize: 14
        font.bold: true
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        visible: text !== ""
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Config.foreground
        opacity: 0.2
        visible: (trayMenu.trayItem?.title ?? "") !== ""
      }

      // Menu entries via QsMenuOpener
      Repeater {
        model: menuOpener.children

        delegate: Rectangle {
          required property var modelData
          Layout.fillWidth: true
          implicitHeight: modelData.isSeparator ? 9 : entryText.implicitHeight + 8
          color: !modelData.isSeparator && entryArea.containsMouse
            ? Config.selection
            : "transparent"
          radius: 6

          // Separator
          Rectangle {
            visible: modelData.isSeparator
            anchors.centerIn: parent
            width: parent.width
            height: 1
            color: Config.foreground
            opacity: 0.2
          }

          // Label
          Text {
            id: entryText
            visible: !modelData.isSeparator
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
            text: modelData.text ?? ""
            color: (modelData.enabled ?? true) ? Config.foreground : Config.inactive
            font.pixelSize: 13
          }

          MouseArea {
            id: entryArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: !modelData.isSeparator && (modelData.enabled ?? true)
            onClicked: {
              modelData.triggered()
              trayMenu.visible = false
            }
          }
        }
      }
    }
  }
}