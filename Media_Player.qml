import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

PopupWindow {
  id: mediaPopup
  property var parentBar: null
  property string artUrl: ""
  property int playerIndex: 0
  property var player: Mpris.players.values[playerIndex] ?? Mpris.players.values[0]
  implicitWidth: 300
  implicitHeight: 320
  color: "transparent"

  anchor.window: parentBar
  anchor.rect.x: 0
  anchor.rect.y: 32

  onPlayerIndexChanged: {
    var url = mediaPopup.player?.metadata["mpris:artUrl"] ?? ""
    if (url === "") url = Mpris.players.values[0]?.metadata["mpris:artUrl"] ?? ""
    if (url !== "") mediaPopup.artUrl = url
  }

  property var artCache: ({})

  onPlayerChanged: {
    updateArt()
  }

  function getYoutubeThumbnail(url) {
    if (!url) return ""
    var match = url.match(/[?&]v=([^&]+)/)
    if (match) return "https://img.youtube.com/vi/" + match[1] + "/maxresdefault.jpg"
    return ""
  }

  function updateArt() {
    var url = mediaPopup.player?.metadata["mpris:artUrl"] ?? ""
    if (url === "") url = getYoutubeThumbnail(mediaPopup.player?.metadata["xesam:url"] ?? "")
    if (url !== "") {
      var cache = Object.assign({}, mediaPopup.artCache)
      cache[mediaPopup.playerIndex] = url
      mediaPopup.artCache = cache
    }
  }

  Connections {
    target: mediaPopup.player || null
    function onMetadataChanged() { 
      updateArt()
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: 12
    color: Config.background
    border.width: 2
    border.color: Config.foreground
    clip: true

    HoverHandler {
      property bool hasHovered: false
      onHoveredChanged: {
        if (hovered) {
          hasHovered = true 
        } else if (hasHovered && !hovered) {
          mediaPopup.visible = false 
          hasHovered = false 
        }
      }
    }

    Item {
      anchors.fill: parent
      anchors.margins: 2

      Image {
        id: artImage
        anchors.fill: parent
        source: mediaPopup.artCache[mediaPopup.playerIndex] ?? ""
        fillMode: Image.PreserveAspectCrop
        opacity: 0.3
        cache: false
        visible: false
      }

      Rectangle {
        id: artMask
        anchors.fill: parent
        radius: 12
        visible: false
      }

      OpacityMask {
        anchors.fill: parent
        source: artImage
        maskSource: artMask
        opacity: 0.3
      }
    }

    // prev player - left side
    Text {
      visible: Mpris.players.values.length > 1
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      text: ""
      color: Config.foreground
      font.pixelSize: 24
      MouseArea {
        anchors.fill: parent
        onClicked: mediaPopup.playerIndex = (mediaPopup.playerIndex + 1) % Mpris.players.values.length
      }
    }

    // next player - right side
    Text {
      visible: Mpris.players.values.length > 1
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      text: ""
      color: Config.foreground
      font.pixelSize: 24
      MouseArea {
        anchors.fill: parent
        onClicked: mediaPopup.playerIndex = (mediaPopup.playerIndex + 1) % Mpris.players.values.length
      }
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      Item { Layout.fillHeight: true }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.margins: 16
        spacing: 4

        Text {
          Layout.fillWidth: true
          text: mediaPopup.player?.metadata["xesam:title"] ?? "Nothing playing"
          color: Config.foreground
          font.pixelSize: 16
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: mediaPopup.player?.metadata["xesam:artist"]?.join(", ") ?? ""
          color: Config.inactive
          font.pixelSize: 13
          elide: Text.ElideRight
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 8
        implicitHeight: 4

        Rectangle {
          id: progressTrack
          anchors.fill: parent
          radius: 2
          color: Config.inactive

          Rectangle {
            width: progressTrack.width * (mediaPopup.player?.position / mediaPopup.player?.length ?? 0)
            height: parent.height
            radius: 2
            color: Config.foreground
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: (mouse) => {
            if (mediaPopup.player)
              mediaPopup.player.position = (mouse.x / width) * mediaPopup.player.length
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.bottomMargin: 16
        spacing: 8

        Text {
          text: "󰒮"
          color: Config.foreground
          font.pixelSize: 20
          MouseArea {
            anchors.fill: parent
            onClicked: mediaPopup.player?.previous()
          }
        }

        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: mediaPopup.player?.playbackState === MprisPlaybackState.Playing ? "" : ""
          color: Config.foreground
          font.pixelSize: 24
          MouseArea {
            anchors.fill: parent
            onClicked: {
              if (mediaPopup.player?.playbackState === MprisPlaybackState.Playing)
                mediaPopup.player.pause()
              else
                mediaPopup.player?.play()
            }
          }
        }

        Text {
          text: "󰒭"
          color: Config.foreground
          font.pixelSize: 20
          MouseArea {
            anchors.fill: parent
            onClicked: mediaPopup.player?.next()
          }
        }
      }
    }
  }
}