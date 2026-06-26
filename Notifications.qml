// Notifications.qml

import Quickshell
import Quickshell.Services.Notifications
import QtQuick.Layouts
import QtQuick
import QtQuick.Controls

PopupWindow {
  id: notificationsWindow
  visible: false
  property var parentBar: null
  property bool isDismissing: false

  Timer {
    id: dismissGraceTimer
    interval: 500
    onTriggered: {
      isDismissing = false
      if (!hoverHandler.hovered && hoverHandler.hasHovered) {
        notificationsWindow.visible = false
        hoverHandler.hasHovered = false
      }
    }
  }

  anchor.window: parentBar
  anchor.rect.x: 0
  anchor.rect.y: 32

  implicitWidth: 350
  implicitHeight: notificationsLayout.implicitHeight + 23
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    color: Config.background
    radius: 16
    border.width: 2
    border.color: Config.foreground

    HoverHandler {
      id: hoverHandler
      property bool hasHovered: false
      onHoveredChanged: {
        if (hovered) {
          hasHovered = true
        } else if (hasHovered && !hovered && !isDismissing) {
          notificationsWindow.visible = false
          hasHovered = false
        }
      }
    }

    ColumnLayout {
      id: notificationsLayout
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        topMargin: 12
        leftMargin: 12
        rightMargin: 12
      }

      Text {
        text: "Notifications (" + notificationList.count + ")"
        color: Config.foreground
        font.pixelSize: 14
        font.bold: true
        Layout.bottomMargin: 8
      }

      ListView {
        id: notificationList
        Layout.fillWidth: true
        Layout.maximumHeight: 400
        implicitHeight: contentHeight
        clip: true
        spacing: 8
        model: NotificationService.notifications

        delegate: Rectangle {
          id: notificationCard
          required property var modelData
          property var notification: modelData
          width: notificationList.width
          implicitHeight: mainCol.implicitHeight + 16
          color: "transparent"
          border.color: Config.inactive
          border.width: 1
          radius: 8

          ColumnLayout {
            id: mainCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 12

            RowLayout {
              Layout.fillWidth: true
              spacing: 12

              Image {
                property string validSource: {
                  let img = notificationCard.notification.image
                    ? notificationCard.notification.image.toString()
                    : "";
                  let icon = notificationCard.notification.appIcon
                    ? notificationCard.notification.appIcon.toString()
                    : "";
                  if (img !== "") return img;
                  if (icon.startsWith("/") || icon.startsWith("file://")) return icon;
                  return "";
                }
                source: validSource
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                visible: validSource !== ""
                fillMode: Image.PreserveAspectCrop
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                  text: notificationCard.notification.summary
                  color: Config.foreground
                  font.bold: true
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Text {
                  text: notificationCard.notification.body
                  color: Config.inactive
                  font.pixelSize: 12
                  Layout.fillWidth: true
                  wrapMode: Text.Wrap
                }
              }

              Text {
                text: " 󰅖"
                color: closeArea.containsMouse ? "#ff5555" : Config.inactive
                font.pixelSize: 16
                Layout.alignment: Qt.AlignTop

                MouseArea {
                  id: closeArea
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    isDismissing = true
                    dismissGraceTimer.restart()
                    notificationCard.notification.dismiss()
                  }
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              visible: notificationCard.notification.hasInlineReply

              TextField {
                id: replyInput
                Layout.fillWidth: true
                placeholderText: notificationCard.notification.inlineReplyPlaceholder !== ""
                  ? notificationCard.notification.inlineReplyPlaceholder
                  : "Type a reply..."
                color: Config.foreground
                font.pixelSize: 12

                placeholderTextColor: Config.foreground 

                background: Rectangle {
                  color: Config.background
                  border.color: Config.inactive
                  radius: 6
                }

                onAccepted: {
                  if (text !== "") {
                    notificationCard.notification.sendInlineReply(text)
                    text = ""
                    isDismissing = true
                    dismissGraceTimer.restart()
                  }
                }
              }

              Rectangle {
                implicitWidth: 32
                implicitHeight: replyInput.height
                color: sendArea.containsMouse ? Config.selection : "transparent"
                border.color: Config.inactive
                border.width: 1
                radius: 6

                Text {
                  anchors.centerIn: parent
                  text: "󰒊"
                  color: Config.foreground
                }

                MouseArea {
                  id: sendArea
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    if (replyInput.text !== "") {
                      notificationCard.notification.sendInlineReply(replyInput.text)
                      replyInput.text = ""
                      isDismissing = true
                      dismissGraceTimer.restart()
                    }
                  }
                }
              }
            }

            Flow {
              Layout.fillWidth: true
              spacing: 8
              visible: notificationCard.notification.actions
                && notificationCard.notification.actions.length > 0

              Repeater {
                model: notificationCard.notification.actions

                delegate: Rectangle {
                  required property var modelData
                  visible: modelData.id !== "inline-reply" && modelData.id !== "default"
                  implicitWidth: actionText.implicitWidth + 16
                  implicitHeight: actionText.implicitHeight + 8
                  color: actionArea.containsMouse ? Config.selection : "transparent"
                  border.color: Config.inactive
                  border.width: 1
                  radius: 6

                  Text {
                    id: actionText
                    anchors.centerIn: parent
                    text: modelData.text
                    color: Config.foreground
                    font.pixelSize: 12
                  }

                  MouseArea {
                    id: actionArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                      modelData.invoke()
                      isDismissing = true
                      dismissGraceTimer.restart()
                      notificationCard.notification.dismiss()
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}