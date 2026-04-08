// Bar.qml
import Quickshell
import QtQuick.Layouts
import QtQuick
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications

Scope {
  Variants {
    model: Quickshell.screens

    Scope {
      required property var modelData

      PanelWindow {
        id: bar
        screen: modelData
        focusable: true
        anchors {
          top: true
          left: true
          right: true
        }

        implicitHeight: 40
        color: "transparent"

        Item {
          anchors {
            fill: parent
            topMargin: 8
            leftMargin: 8
            rightMargin: 8
          }

          // left
          Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Pill {
              RowLayout {
                spacing: 4
                Repeater {
                  model: Hyprland.workspaces
                  Rectangle {
                    required property var modelData
                    radius: height / 3
                    color: modelData.focused ? Colors.selection : "transparent"
                    implicitWidth: wsLabel.implicitWidth + 12
                    implicitHeight: 20
                    Text {
                      id: wsLabel
                      anchors.centerIn: parent
                      text: modelData.id
                      color: modelData.focused ? Colors.foreground : Colors.inactive
                    }
                    MouseArea {
                      anchors.fill: parent
                      onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    }
                  }
                }
              }
            }
            Pill {
              id: mediaPill
              visible: Mpris.players.values.length > 0
              RowLayout {
                Text {
                  text: "󰒮" // back
                  color: Colors.foreground
                  MouseArea {
                    anchors.fill: parent
                    onClicked: Mpris.players.values[0]?.previous()
                  }
                }
                Text {
                  text: Mpris.players.values[0]?.playbackState === MprisPlaybackState.Playing ? "" : "" 
                  color: Colors.foreground
                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      if (Mpris.players.values[0]?.playbackState === MprisPlaybackState.Playing) {
                        Mpris.players.values[0].pause()
                      } else {
                        Mpris.players.values[0]?.play() 
                      }
                    }
                  }
                }
                Text {
                  text: "󰒭" // next
                  color: Colors.foreground
                  MouseArea {
                    anchors.fill: parent
                    onClicked: Mpris.players.values[0]?.next()
                  }
                }
                Text {
                  property var player: Mpris.players.values[0]
                  text: player ? (player.metadata["xesam:title"] + " - " + player.metadata["xesam:artist"]) : ""
                  color: Colors.foreground
                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      var pos = mediaPill.mapToItem(null, 0, mediaPill.height)
                      media_player.anchor.rect.x = pos.x
                      media_player.anchor.rect.y = 48
                      media_player.visible = !media_player.visible
                    }
                  }
                }
              }
            }
          }
          Pill {
            id: clockPill
            anchors.centerIn: parent
            Clock {
              MouseArea {
                anchors.fill: parent
                onClicked: {
                  var pos = clockPill.mapToItem(null, 0, 0)
                  calendar.anchor.rect.x = pos.x - calendar.implicitWidth / 2 + clockPill.width / 2
                  calendar.anchor.rect.y = 48
                  calendar.visible = !calendar.visible
                }
              }
            }
          }

          Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Pill {
              RowLayout {
                spacing: 4
                Repeater {
                  model: SystemTray.items
                  Image {
                    id: trayIcon
                    required property var modelData
                    source: modelData.icon
                    width: 16
                    height: 16
                    sourceSize: Qt.size(16, 16)

                    MouseArea {
                      anchors.centerIn: parent
                      width: 28
                      height: 28
                      acceptedButtons: Qt.LeftButton | Qt.RightButton
                      onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                          if (modelData.onlyMenu) {
                            var pos = trayIcon.mapToItem(null, 0, 0)
                            trayMenu.trayItem = modelData
                            trayMenu.anchor.rect.x = pos.x
                            trayMenu.anchor.rect.y = 48
                            trayMenu.visible = true
                          } else {
                            modelData.activate()
                          }
                        } else if (mouse.button === Qt.RightButton) {
                          if (!modelData.hasMenu) return
                          var pos = trayIcon.mapToItem(null, 0, 0)
                          trayMenu.trayItem = modelData
                          trayMenu.anchor.rect.x = pos.x
                          trayMenu.anchor.rect.y = 48
                          trayMenu.visible = true
                        }
                      }
                    }
                  }
                }
              }
            }
            Pill {
              id: volumePill
              anchors.verticalCenter: parent.verticalCenter
              RowLayout {
              spacing: 12
                Text {
                  text: "  " + Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%"
                  color: Colors.foreground
                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      var pos = volumePill.mapToItem(null, 0, 0)
                      volume_mixer.anchor.rect.x = pos.x - volume_mixer.implicitWidth + volumePill.width
                      volume_mixer.anchor.rect.y = 48
                      volume_mixer.visible = !volume_mixer.visible
                    }
                  }
                }
                Text {
                  text: "" // Network
                  color: Colors.foreground
                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      var pos = volumePill.mapToItem(null, 0, 0)
                      network.anchor.rect.x = pos.x - network.implicitWidth + volumePill.width
                      network.anchor.rect.y = 48
                      network.visible = !network.visible
                    }
                  }
                }
                Text {
                  text: "" // Notifications
                  color: Colors.foreground
                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      var pos = volumePill.mapToItem(null, 0, 0)
                      notifications.anchor.rect.x = pos.x - notifications.implicitWidth + volumePill.width
                      notifications.anchor.rect.y = 48
                      notifications.visible = !notifications.visible
                    }
                  }
                }
                Text {
                  text: "󰂯" // Bluetooth
                  color: Colors.foreground
                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      var pos = volumePill.mapToItem(null, 0, 0)
                      bluetooth.anchor.rect.x = pos.x - bluetooth.implicitWidth + volumePill.width
                      bluetooth.anchor.rect.y = 48
                      bluetooth.visible = !bluetooth.visible
                    }
                  }
                }
                Text {
                  text: "󰐥" 
                  color: Colors.foreground
                  MouseArea {
                    anchors.fill: parent
                    onClicked: powerMenu.active = true
                  }
                }
              }
            }
          }
        }
        Media_Player {
          id: media_player
          parentBar: bar
        }
        Volume_Mixer {
          id: volume_mixer
          parentBar: bar
        }
        Bluetooth {
          id: bluetooth
          parentBar: bar
        }
        Notifications {
          id: notifications
          parentBar: bar
        }
        Network {
          id: network
          parentBar: bar
        }
        TrayMenu {
          id: trayMenu
          parentBar: bar
        }
        Calendar {
          id: calendar
          parentBar: bar
        }
      }
    }
  }
}