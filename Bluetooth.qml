// Bluetooth.qml
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PopupWindow {
  id: bluetoothWindow
  visible: false
  property var parentBar: null

  anchor.window: parentBar
  anchor.rect.x: 0
  anchor.rect.y: 32

  implicitWidth: 350
  implicitHeight: bluetoothLayout.implicitHeight + 23 
  color: "transparent"

  property bool manualScanActive: false

  function startScanTimer() { scanTimeoutTimer.restart() }
  function stopScanTimer() { scanTimeoutTimer.stop() }

  Timer {
    id: scanTimeoutTimer
    interval: 45000
    onTriggered: {
      bluetoothWindow.manualScanActive = false
      const adapter = Bluetooth.defaultAdapter
      if (adapter && adapter.discovering) {
        adapter.discovering = false
      }
    }
  }

  function deviceIcon(icon) {
    if (icon.includes("headset") || icon.includes("headphones")) return "󰋋"
    if (icon.includes("gaming") || icon.includes("joystick")) return "󰊗"
    if (icon.includes("keyboard")) return "󰌌"
    if (icon.includes("mouse")) return "󰍽"
    if (icon.includes("phone")) return "󰏲"
    return "󰂯" 
  }

  Rectangle {
    anchors.fill: parent
    color: Colors.background
    radius: 16
    border.width: 2
    border.color: Colors.foreground

    HoverHandler {
      property bool hasHovered: false
      onHoveredChanged: {
        if (hovered) {
          hasHovered = true
        } else if (hasHovered && !hovered) {
          bluetoothWindow.visible = false
          hasHovered = false
        }
      }
    }

    ColumnLayout {
      id: bluetoothLayout
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        topMargin: 16
        leftMargin: 16
        rightMargin: 16
      }
      spacing: 12

      // --- Header Row (Updated to match Wi-Fi layout!) ---
      RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        spacing: 12

        Text {
          text: "󰂯" 
          color: Colors.foreground
          font.pixelSize: 18
        }

        Text {
          text: "Bluetooth"
          color: Colors.foreground
          font.bold: true
          font.pixelSize: 13
        }

        // --- NEW: Toggle Switch for Bluetooth Power ---
        Rectangle {
          implicitWidth: 36
          implicitHeight: 20
          radius: 10
          
          // Safely check if the adapter exists to determine power state
          property bool btEnabled: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
          color: btEnabled ? Colors.selection : Colors.inactive

          MouseArea {
            anchors.fill: parent
            onClicked: {
              if (Bluetooth.defaultAdapter) {
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
              }
            }
          }

          Rectangle {
            width: 16
            height: 16
            radius: 8
            color: Colors.foreground
            anchors.verticalCenter: parent.verticalCenter
            x: parent.btEnabled ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: 150 } }
          }
        }

        Item { Layout.fillWidth: true } // Pushes scan button to the right
        
        Text {
          id: scanButton
          text: ""
          color: scanArea.containsMouse ? Colors.inactive : Colors.foreground
          font.pixelSize: 14
          
          // Hide the scan button if Bluetooth is turned off
          visible: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false

          property bool isScanning: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.discovering : false

          onIsScanningChanged: {
            if (isScanning) {
              spinAnim.start()
              if (bluetoothWindow.manualScanActive) {
                bluetoothWindow.startScanTimer()
              }
            } else {
              spinAnim.stop()
              scanButton.rotation = 0
              bluetoothWindow.manualScanActive = false
              bluetoothWindow.stopScanTimer()
            }
          }

          NumberAnimation {
            id: spinAnim
            target: scanButton
            property: "rotation"
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
          }

          MouseArea {
            id: scanArea
            anchors.fill: parent
            implicitWidth: 24
            implicitHeight: 24
            hoverEnabled: true
            onClicked: {
              const adapter = Bluetooth.defaultAdapter
              if (!adapter) return

              if (adapter.discovering) {
                bluetoothWindow.manualScanActive = false
                adapter.discovering = false
              } else {
                bluetoothWindow.manualScanActive = true
                adapter.discovering = true
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.inactive
        opacity: 0.3
        Layout.topMargin: 4
        Layout.bottomMargin: 4
      }

      ScrollView {
        Layout.fillWidth: true
        Layout.maximumHeight: 300
        clip: true 
        
        // Hide the device list if Bluetooth is turned off
        visible: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
        
        ColumnLayout {
          width: parent.width - 14
          spacing: 4
          
          Repeater {
            model: Bluetooth.defaultAdapter?.devices
            Rectangle {
              required property var modelData
              property bool isConnecting: false
              property bool connectionFailed: false

              Layout.fillWidth: true
              implicitHeight: deviceLayout.implicitHeight + 8
              color: "transparent"

              Connections {
                target: modelData
                function onConnectedChanged() {
                  if (modelData.connected) {
                    isConnecting = false
                    connectionFailed = false
                    timeoutTimer.stop()
                  }
                }
              }

              Timer {
                id: timeoutTimer
                interval: 8000
                onTriggered: {
                  if (!modelData.connected) {
                    isConnecting = false
                    connectionFailed = true
                    errorResetTimer.start()
                  }
                }
              }

              Timer {
                id: errorResetTimer
                interval: 3000
                onTriggered: connectionFailed = false
              }

              RowLayout {
                id: deviceLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                
                // Connection Icon
                Text {
                  text: isConnecting ? "󰔟" : (connectionFailed ? "󰂲" : deviceIcon(modelData.icon))
                  color: connectionFailed ? "#ff5555" : (modelData.connected ? Colors.foreground : Colors.inactive)
                  font.pixelSize: 16
                }

                // Device Name
                Text {
                  id: deviceText
                  text: modelData.name
                  color: modelData.connected 
                    ? (nameArea.containsMouse ? Colors.inactive : Colors.foreground) 
                    : (nameArea.containsMouse ? Colors.foreground : Colors.inactive)
                  Layout.fillWidth: true 
                  elide: Text.ElideRight
                  
                  MouseArea {
                    id: nameArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                      if (modelData.connected) {
                        modelData.disconnect()
                      } else {
                        isConnecting = true
                        connectionFailed = false
                        timeoutTimer.restart()
                        modelData.connect()
                      }
                    }
                  }
                }

                // Auto-connect (Trusted) Icon
                Text {
                  visible: modelData.paired
                  text: modelData.trusted ? "" : "" 
                  color: modelData.trusted
                    ? (trustArea.containsMouse ? Colors.inactive : Colors.foreground) 
                    : (trustArea.containsMouse ? Colors.foreground : Colors.inactive)
                  font.pixelSize: 16

                  ToolTip {
                    visible: trustArea.containsMouse
                    delay: 400
                    contentItem: Text {
                      text: "Auto-connect"
                      color: Colors.foreground
                      font.pixelSize: 12
                    }
                    background: Rectangle {
                      color: Colors.selection
                      radius: 6
                    }
                  }

                  MouseArea {
                    id: trustArea
                    anchors.fill: parent
                    hoverEnabled: true 
                    onClicked: modelData.trusted = !modelData.trusted
                  }
                }

                // Forget Device Icon
                Text {
                  visible: modelData.paired
                  text: "󰆴" 
                  color: forgetArea.containsMouse ? "#ff5555" : Colors.inactive
                  font.pixelSize: 16

                  ToolTip {
                    visible: forgetArea.containsMouse
                    delay: 400
                    contentItem: Text {
                      text: "Forget Device"
                      color: Colors.foreground
                      font.pixelSize: 12
                    }
                    background: Rectangle {
                      color: Colors.selection
                      radius: 6
                    }
                  }

                  MouseArea {
                    id: forgetArea
                    anchors.fill: parent
                    hoverEnabled: true 
                    onClicked: {
                      modelData.forget()
                    }
                  }
                }
              }
            }
          }
        }
      }
      
      // Optional: Message when Bluetooth is off
      Text {
        text: "Bluetooth is turned off"
        color: Colors.inactive
        font.pixelSize: 12
        Layout.alignment: Qt.AlignHCenter
        visible: Bluetooth.defaultAdapter ? !Bluetooth.defaultAdapter.enabled : true
      }
    }
  }
}