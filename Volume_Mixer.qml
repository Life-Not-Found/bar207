import Quickshell
import Quickshell.Services.Pipewire
import QtQuick.Layouts
import QtQuick
import QtQuick.Controls

PopupWindow {
  id: mixerWindow
  visible: false
  property var parentBar: null

  anchor.window: parentBar
  anchor.rect.x: 0
  anchor.rect.y: 32

  implicitWidth: 350
  implicitHeight: mixerLayout.implicitHeight + 23
  color: "transparent"

  component VolumeSlider: RowLayout {
    property var audioNode: null
    spacing: 16

    Slider {
      id: control
      Layout.fillWidth: true
      from: 0
      to: 1

      value: audioNode ? audioNode.volume : 0
      onMoved: if (audioNode) audioNode.volume = value

      background: Rectangle {
        implicitHeight: 16
        color: Colors.inactive
        radius: 6
        Rectangle {
          width: control.visualPosition * parent.width
          height: parent.height
          color: Colors.foreground
          radius: 6
        }
      }
      handle: Item {}
    }

    Text {
      text: Math.round(control.value * 100) + "%"
      color: Colors.foreground
      Layout.preferredWidth: 35
      horizontalAlignment: Text.AlignRight
    }
  }

  component DeviceLabel: Item {
    property string labelText: ""
    property bool isChecked: false
    property var sinkNode: null

    Layout.fillWidth: true
    implicitHeight: innerLayout.implicitHeight

    RowLayout {
      id: innerLayout
      anchors.fill: parent
      spacing: 6

      Rectangle {
        width: 14
        height: 14
        radius: 7
        color: "transparent"
        border.color: Colors.foreground
        border.width: 1.5

        Rectangle {
          anchors.centerIn: parent
          width: 8
          height: 8
          radius: 4
          color: Colors.foreground
          visible: isChecked
        }
      }

      Text {
        text: labelText
        color: Colors.foreground
        elide: Text.ElideRight
        Layout.maximumWidth: 252
        Layout.fillWidth: true
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: if (sinkNode) Pipewire.preferredDefaultAudioSink = sinkNode
    }
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
          mixerWindow.visible = false
          hasHovered = false
        }
      }
    }

    ColumnLayout {
      id: mixerLayout
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        topMargin: 12
        leftMargin: 12
        rightMargin: 12
      }

      Text {
        text: "Audio mixer"
        color: Colors.foreground
        font.pixelSize: 14
        font.bold: true
        Layout.fillWidth: true
      }

      ColumnLayout {
        PwObjectTracker {
          objects: [Pipewire.defaultAudioSink]
        }
        DeviceLabel {
          labelText: "Output: " + (Pipewire.defaultAudioSink?.description || Pipewire.defaultAudioSink?.name || "Unknown")
          isChecked: true
          sinkNode: Pipewire.defaultAudioSink
        }
        VolumeSlider {
          audioNode: Pipewire.defaultAudioSink?.audio
        }
      }

      Repeater {
        model: Pipewire.nodes
        ColumnLayout {
          required property var modelData
          visible: modelData.isSink && modelData.properties["node.virtual"] === "true" && !modelData.isStream && modelData.name !== Pipewire.defaultAudioSink?.name
          PwObjectTracker { objects: [modelData] }
          DeviceLabel {
            labelText: modelData.description || modelData.name || "Unknown Device"
            isChecked: false
            sinkNode: modelData
          }
          VolumeSlider { audioNode: modelData.audio }
        }
      }

      Repeater {
        model: Pipewire.nodes
        ColumnLayout {
          required property var modelData
          visible: modelData.isSink && !modelData.isStream && modelData.properties["node.virtual"] !== "true" && modelData.name !== Pipewire.defaultAudioSink?.name
          PwObjectTracker { objects: [modelData] }
          DeviceLabel {
            labelText: modelData.description || modelData.name || "Unknown Device"
            isChecked: false
            sinkNode: modelData
          }
          VolumeSlider { audioNode: modelData.audio }
        }
      }
    }
  }
}