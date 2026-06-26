// PowerMenu.qml
import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland

Scope {
  id: powerMenuRoot
  property bool active: false

  Process {
    id: cmdProcess
  }

  function runAction(cmd) {
    powerMenuRoot.active = false 
    if (cmd === "") return       
    
    if (cmd === "logout") {
      cmdProcess.command = ["hyprctl", "dispatch", "exit"]
    } else {
      cmdProcess.command = cmd.split(" ")
    }
    cmdProcess.running = true
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: menuWindow
      required property var modelData
      screen: modelData
      visible: powerMenuRoot.active
      
      exclusionMode: ExclusionMode.Ignore
      
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      
      color: Qt.rgba(0, 0, 0, 0.90)
      focusable: true

      onVisibleChanged: {
        if (visible) {
          focusItem.forceActiveFocus()
        }
      }

      Item {
        id: focusItem
        anchors.fill: parent
        focus: true
        
        Keys.onEscapePressed: powerMenuRoot.active = false

        MouseArea {
          anchors.fill: parent
          onClicked: powerMenuRoot.active = false
        }

        RowLayout {
          anchors.centerIn: parent
          spacing: 24

          // Only show controls on the monitor your mouse/focus is currently on
          visible: menuWindow.modelData.name === Hyprland.focusedMonitor?.name

          MouseArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            hoverEnabled: true
          }

          Repeater {
            model: [
              { icon: "󰐥", label: "Shutdown", cmd: "systemctl poweroff" },
              { icon: "󰜉", label: "Reboot", cmd: "systemctl reboot" },
              { icon: "󰒲", label: "Sleep", cmd: "systemctl suspend" },
              { icon: "󰋊", label: "Hibernate", cmd: "systemctl hibernate" },
              { icon: "", label: "Lock", cmd: "loginctl lock-session" },
              { icon: "󰗼", label: "Logout", cmd: "logout" },
              { icon: "󰜺", label: "Cancel", cmd: "" }
            ]

            Rectangle {
              required property var modelData
              width: 120
              height: 120
              radius: 16
              color: btnArea.containsMouse ? Config.selection : Config.background
              
              border.color: btnArea.containsMouse ? Config.foreground : "transparent"
              border.width: 1

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                  text: parent.parent.modelData.icon
                  font.pixelSize: 42
                  color: Config.foreground
                  Layout.alignment: Qt.AlignHCenter
                }
                Text {
                  text: parent.parent.modelData.label
                  color: Config.foreground
                  font.pixelSize: 14
                  Layout.alignment: Qt.AlignHCenter
                }
              }

              MouseArea {
                id: btnArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: runAction(modelData.cmd)
              }
            }
          }
        }
      }
    }
  }
}