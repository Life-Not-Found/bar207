// Network.qml
import Quickshell
import Quickshell.Networking
import Quickshell.Io 
import QtQuick.Layouts
import QtQuick
import QtQuick.Controls

PopupWindow {
  id: networkWindow
  visible: false
  property var parentBar: null

  anchor.window: parentBar
  anchor.rect.x: 0
  anchor.rect.y: 32

  implicitWidth: 320
  implicitHeight: networkLayout.implicitHeight + 24
  color: "transparent"

  // --- STATE TRACKERS ---
  property string expandedNetwork: ""
  property string currentPasswordDraft: "" 

  function startScanTimer() { scanTimeoutTimer.restart() }
  function stopScanTimer() { scanTimeoutTimer.stop() }

  Timer {
    id: scanTimeoutTimer
    interval: 45000 
    onTriggered: {
      if (wifiDevice && wifiDevice.scannerEnabled) {
        wifiDevice.scannerEnabled = false
      }
    }
  }

  onVisibleChanged: {
    if (visible) {
      if (!ethCheckProcess.running) ethCheckProcess.running = true
    } else {
      // Expanded state resets when closing, but scanning persists in background
      networkWindow.expandedNetwork = "" 
      networkWindow.currentPasswordDraft = ""
    }
  }

  // --- MULTI-PORT ETHERNET MODEL ---
  ListModel { id: ethModel }

  Process {
    id: ethCheckProcess
    command: ["bash", "-c", "nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev | grep -i ethernet"]
    
    stdout: StdioCollector {
      onStreamFinished: {
        let out = this.text.trim()
        if (out.length === 0) {
          ethModel.clear()
          return
        }
        let lines = out.split("\n")
        let currentIfaces = []
        for (let i = 0; i < lines.length; i++) {
          let parts = lines[i].split(":")
          if (parts.length < 3) continue;
          let iface = parts[0]
          let isConn = (parts[2] === "connected")
          let fName = (parts.length >= 4 && parts[3] !== "") ? parts[3] : ("Wired (" + iface + ")")
          currentIfaces.push(iface)
          let found = false
          for (let j = 0; j < ethModel.count; j++) {
            if (ethModel.get(j).iface === iface) {
              ethModel.setProperty(j, "connected", isConn)
              ethModel.setProperty(j, "name", fName)
              found = true
              break
            }
          }
          if (!found) {
            ethModel.append({ "iface": iface, "connected": isConn, "name": fName })
          }
        }
        for (let j = ethModel.count - 1; j >= 0; j--) {
          if (!currentIfaces.includes(ethModel.get(j).iface)) {
            ethModel.remove(j)
          }
        }
      }
    }
  }

  Timer {
    id: ethTimer
    interval: 2000 
    running: networkWindow.visible
    repeat: true
    onTriggered: if (!ethCheckProcess.running) ethCheckProcess.running = true
  }

  // --- Quickshell Native Wi-Fi ---
  property WifiDevice wifiDevice: {
    for (let i = 0; i < Networking.devices.values.length; i++) {
      let dev = Networking.devices.values[i]
      if (dev.type === DeviceType.Wifi) return dev
    }
    return null
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
          networkWindow.visible = false
          hasHovered = false
        }
      }
    }

    ColumnLayout {
      id: networkLayout
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        topMargin: 16
        leftMargin: 16
        rightMargin: 16
      }
      spacing: 12

      // --- Header Row ---
      RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        Text {
          text: "Network"
          color: Config.foreground
          font.pixelSize: 14
          font.bold: true
        }
        Item { Layout.fillWidth: true } 
      }

      // --- Ethernet Block ---
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8 
        visible: ethModel.count > 0 
        Repeater {
          model: ethModel
          delegate: RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Text {
              text: "󰈀"
              color: model.connected ? Config.foreground : Config.inactive
              font.pixelSize: 16
            }
            Text {
              text: model.name 
              color: model.connected ? Config.foreground : Config.inactive
              font.bold: model.connected
              font.pixelSize: 13
              Layout.fillWidth: true
              elide: Text.ElideRight
            }
            Text {
              text: "󰄬"
              color: Config.foreground
              font.pixelSize: 12
              visible: model.connected
            }
            Rectangle {
              implicitWidth: 36
              implicitHeight: 20
              radius: 10
              color: model.connected ? Config.selection : Config.inactive
              Process { id: ethToggleProcess }
              MouseArea {
                anchors.fill: parent
                onClicked: {
                  let willConnect = !model.connected
                  ethModel.setProperty(index, "connected", willConnect)
                  if (!willConnect) {
                    ethToggleProcess.command = ["nmcli", "device", "disconnect", model.iface]
                  } else {
                    ethToggleProcess.command = ["nmcli", "device", "connect", model.iface]
                  }
                  ethToggleProcess.running = true
                }
              }
              Rectangle {
                width: 16
                height: 16
                radius: 8
                color: Config.foreground
                anchors.verticalCenter: parent.verticalCenter
                x: model.connected ? parent.width - width - 2 : 2
                Behavior on x { NumberAnimation { duration: 150 } }
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Config.inactive
        opacity: 0.3
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        visible: ethModel.count > 0
      }

      // --- Wi-Fi Header ---
      RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Text {
          text: "" 
          color: Config.foreground
          font.pixelSize: 18
        }

        Text {
          text: "Wi-Fi"
          color: Config.foreground
          font.bold: true
          font.pixelSize: 13
        }

        // Toggle Switch for Wi-Fi Power
        Rectangle {
          implicitWidth: 36
          implicitHeight: 20
          radius: 10
          color: Networking.wifiEnabled ? Config.selection : Config.inactive

          MouseArea {
            anchors.fill: parent
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
          }

          Rectangle {
            width: 16
            height: 16
            radius: 8
            color: Config.foreground
            anchors.verticalCenter: parent.verticalCenter
            x: Networking.wifiEnabled ? parent.width - width - 2 : 2
            Behavior on x { NumberAnimation { duration: 150 } }
          }
        }

        Item { Layout.fillWidth: true } // Pushes scan button to the right
        
        // --- Icon-only Scan Button ---
        Text {
          id: scanIcon
          text: ""
          font.pixelSize: 14
          // Logic: Changes color on hover, stays highlighted if active
          color: scanArea.containsMouse ? Config.inactive : Config.foreground

          // State tracking mirroring Bluetooth style
          property bool isScanning: networkWindow.wifiDevice ? networkWindow.wifiDevice.scannerEnabled : false

          onIsScanningChanged: {
            if (isScanning) {
              spinAnim.start()
            } else {
              spinAnim.stop()
              rotation = 0 // Snap back to upright
            }
          }

          NumberAnimation {
            id: spinAnim
            target: scanIcon
            property: "rotation"
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
            running: scanIcon.isScanning
          }

          MouseArea {
            id: scanArea
            anchors.fill: parent
            // Important: Set padding/size so it's easier to click
            implicitWidth: 24
            implicitHeight: 24
            hoverEnabled: true
            
            onClicked: {
              if (networkWindow.wifiDevice) {
                let willScan = !networkWindow.wifiDevice.scannerEnabled
                networkWindow.wifiDevice.scannerEnabled = willScan
                if (willScan) networkWindow.startScanTimer()
                else networkWindow.stopScanTimer()
              }
            }
          }
        }
      }

      // --- Wi-Fi Network List ---
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4 
        Layout.topMargin: 4
        visible: Networking.wifiEnabled && networkWindow.wifiDevice !== null
        Text {
          text: "Available Networks"
          color: Config.inactive
          font.pixelSize: 12
          font.bold: true
          Layout.bottomMargin: 4
        }
        Repeater {
          model: networkWindow.wifiDevice ? networkWindow.wifiDevice.networks.values : []
          delegate: Rectangle {
            id: networkCard
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: networkCol.implicitHeight + 16 
            color: (networkArea.containsMouse || networkWindow.expandedNetwork === modelData.name) ? Config.selection : "transparent"
            radius: 6 
            ColumnLayout {
              id: networkCol
              anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8
              spacing: 8
              RowLayout {
                Layout.fillWidth: true; spacing: 12
                Text {
                  text: modelData.signalStrength > 0.66 ? "󰤨" : modelData.signalStrength > 0.33 ? "󰤥" : "󰤢"
                  color: (modelData.connected || modelData.known) ? Config.foreground : Config.inactive
                  font.pixelSize: 16
                }
                Text {
                  text: modelData.name ?? ""
                  color: (modelData.connected || modelData.known) ? Config.foreground : Config.inactive 
                  font.pixelSize: 13; Layout.fillWidth: true; elide: Text.ElideRight; font.bold: modelData.connected
                }
                Text {
                  text: modelData.connected ? "󰄬" : ""
                  color: (modelData.connected || modelData.known) ? Config.foreground : Config.inactive
                  font.pixelSize: 12
                  visible: modelData.connected || (!modelData.known && modelData.security !== 0 && modelData.security !== WifiSecurityType.None && modelData.security !== 10)
                }
              }
              RowLayout {
                Layout.fillWidth: true
                visible: networkWindow.expandedNetwork === modelData.name
                spacing: 8
                RowLayout {
                  Layout.fillWidth: true
                  visible: !modelData.connected && modelData.security !== 0 && modelData.security !== WifiSecurityType.None && modelData.security !== 10 && !modelData.known
                  spacing: 8
                  TextField {
                    id: passwordInput; Layout.fillWidth: true; placeholderText: "Password..."; echoMode: TextInput.Password 
                    color: Config.foreground; font.pixelSize: 12
                    text: (networkWindow.expandedNetwork === modelData.name) ? networkWindow.currentPasswordDraft : ""
                    onTextEdited: networkWindow.currentPasswordDraft = text
                    Component.onCompleted: if (networkWindow.expandedNetwork === modelData.name) { forceActiveFocus(); cursorPosition = text.length }
                    background: Rectangle { color: Config.background; border.color: Config.inactive; radius: 4 }
                    onAccepted: (mouse) => connectButtonArea.clicked(mouse) 
                  }
                  Rectangle {
                    implicitWidth: 60; implicitHeight: passwordInput.height
                    color: connectButtonArea.containsMouse ? Config.selection : Config.background
                    border.color: Config.inactive; border.width: 1; radius: 4
                    Process { id: connectProcess }
                    Text { anchors.centerIn: parent; text: "Connect"; color: Config.foreground; font.pixelSize: 11 }
                    MouseArea {
                      id: connectButtonArea; anchors.fill: parent; hoverEnabled: true
                      onClicked: (mouse) => {
                        if (passwordInput.text === "") return;
                        connectProcess.command = ["bash", "-c", "echo \"$1\" | nmcli --ask device wifi connect \"$2\"", "--", passwordInput.text, modelData.name]
                        connectProcess.running = true; networkWindow.expandedNetwork = ""; networkWindow.currentPasswordDraft = ""
                      }
                    }
                  }
                }
                ColumnLayout {
                  Layout.fillWidth: true; visible: modelData.connected || modelData.known; spacing: 12
                  RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    Text { text: "Auto-Connect"; color: Config.foreground; font.pixelSize: 12; Layout.fillWidth: true }
                    Rectangle {
                      implicitWidth: 32; implicitHeight: 18; radius: 9
                      property bool autoConnectState: modelData.autoConnect !== undefined ? modelData.autoConnect : true 
                      color: Config.inactive
                      Process { id: autoconnectProcess }
                      MouseArea {
                        anchors.fill: parent
                        onClicked: {
                          parent.autoConnectState = !parent.autoConnectState
                          let stateStr = parent.autoConnectState ? "yes" : "no"
                          autoconnectProcess.command = ["nmcli", "connection", "modify", modelData.name, "connection.autoconnect", stateStr]
                          autoconnectProcess.running = true
                        }
                      }
                      Rectangle {
                        width: 14; height: 14; radius: 7; color: Config.foreground; anchors.verticalCenter: parent.verticalCenter
                        x: parent.autoConnectState ? parent.width - width - 2 : 2
                        Behavior on x { NumberAnimation { duration: 150 } }
                      }
                    }
                  }
                  RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Rectangle {
                      Layout.fillWidth: true; implicitHeight: 28; color: toggleBtnArea.containsMouse ? Config.inactive : Config.selection
                      border.color: Config.inactive; border.width: 1; radius: 4
                      Text { anchors.centerIn: parent; text: modelData.connected ? "Disconnect" : "Connect"; color: Config.foreground; font.pixelSize: 11 }
                      MouseArea {
                        id: toggleBtnArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: (mouse) => { if (modelData.connected) modelData.disconnect(); else modelData.connect(); networkWindow.expandedNetwork = "" }
                      }
                    }
                    Rectangle {
                      Layout.fillWidth: true; implicitHeight: 28; color: forgetBtnArea.containsMouse ? Config.inactive : Config.selection
                      border.color: Config.inactive; border.width: 1; radius: 4; visible: modelData.known
                      Process { id: forgetProcess }
                      Text { anchors.centerIn: parent; text: "Forget"; color: Config.foreground; font.pixelSize: 11 }
                      MouseArea {
                        id: forgetBtnArea; anchors.fill: parent; hoverEnabled: true
                        onClicked: (mouse) => {
                          forgetProcess.command = ["nmcli", "connection", "delete", "id", modelData.name]
                          forgetProcess.running = true; if (modelData.connected) modelData.disconnect(); networkWindow.expandedNetwork = ""
                        }
                      }
                    }
                  }
                }
              }
            }
            MouseArea {
              id: networkArea; anchors.fill: parent; z: -1; hoverEnabled: true
              onClicked: (mouse) => {
                if (networkWindow.expandedNetwork === modelData.name) {
                  networkWindow.expandedNetwork = ""; networkWindow.currentPasswordDraft = ""; return
                }
                networkWindow.expandedNetwork = modelData.name; networkWindow.currentPasswordDraft = ""
                if (!modelData.connected && (modelData.security === 0 || modelData.security === WifiSecurityType.None || modelData.security === 10) && !modelData.known) {
                  modelData.connect(); networkWindow.expandedNetwork = ""
                }
              }
            }
          }
        }
        Text {
          text: "No networks found"; color: Config.inactive; font.pixelSize: 12
          visible: networkWindow.wifiDevice && networkWindow.wifiDevice.networks.values.length === 0
          Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: 4
        }
      }
    }
  }
}