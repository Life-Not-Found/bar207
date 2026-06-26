// ToastNotifications.qml
import Quickshell
import Quickshell.Services.Notifications
import QtQuick.Layouts
import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects // Use QtGraphicalEffects 1.15 if on older Qt5

PanelWindow {
  id: toastWindow
  color: "transparent"
  
  focusable: true 
  exclusionMode: ExclusionMode.Ignore 

  anchors {
    top: true
  }
  
  margins {
    top: 48 
  }

  implicitWidth: 350
  implicitHeight: toastLayout.implicitHeight

  ColumnLayout {
    id: toastLayout
    width: 350
    spacing: 12

    Repeater {
      model: NotificationService.activePopups

      delegate: Rectangle {
        id: toastCard
        property var notification: model.notif 
        
        width: 350
        implicitHeight: mainCol.implicitHeight + 16
        color: Config.background 
        radius: 8
        
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: toastCard.width
                height: toastCard.height
                radius: toastCard.radius
            }
        }

        HoverHandler {
          id: cardHover
        }

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
                let img = toastCard.notification.image ? toastCard.notification.image.toString() : "";
                let icon = toastCard.notification.appIcon ? toastCard.notification.appIcon.toString() : "";
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
                text: toastCard.notification.summary
                color: Config.foreground
                font.bold: true
                Layout.fillWidth: true
                elide: Text.ElideRight 
              }
              Text {
                text: toastCard.notification.body
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
                  NotificationService.removePopup(toastCard.notification) 
                  toastCard.notification.dismiss() 
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            visible: toastCard.notification.hasInlineReply

            TextField {
              id: replyInput
              Layout.fillWidth: true
              placeholderText: toastCard.notification.inlineReplyPlaceholder !== "" ? toastCard.notification.inlineReplyPlaceholder : "Type a reply..."
              
              placeholderTextColor: Config.foreground 
              
              color: Config.foreground 
              font.pixelSize: 12
              
              background: Rectangle {
                color: Config.background
                border.color: replyInput.activeFocus ? Config.selection : Config.inactive
                border.width: 1
                radius: 6
              }
              onAccepted: {
                if (text !== "") {
                  toastCard.notification.sendInlineReply(text)
                  text = ""
                  NotificationService.removePopup(toastCard.notification)
                }
              }
            }

            Rectangle {
              implicitWidth: 32
              implicitHeight: replyInput.height
              border.color: Config.inactive
              border.width: 1
              radius: 6
              MouseArea {
                id: sendArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                  if (replyInput.text !== "") {
                    toastCard.notification.sendInlineReply(replyInput.text)
                    replyInput.text = ""
                    NotificationService.removePopup(toastCard.notification)
                  }
                }
              }
              color: sendArea.containsMouse ? Config.selection : "transparent"
              Text {
                anchors.centerIn: parent
                text: "󰒊" 
                color: Config.foreground
              }
            }
          }

          Flow {
            Layout.fillWidth: true
            spacing: 8
            visible: toastCard.notification.actions && toastCard.notification.actions.length > 0

            Repeater {
              model: toastCard.notification.actions
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
                    NotificationService.removePopup(toastCard.notification)
                  }
                }
              }
            }
          }
        }

        Rectangle {
          id: progressBar
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          height: 4
          color: Config.foreground 
          width: toastCard.width 
          
          NumberAnimation {
            id: timeoutAnim
            target: progressBar
            property: "width"
            to: 0
            
            // If the app gives a specific time (> 0), use it. 
            // If it asks for infinite (0) or default (-1), force 5000ms.
            duration: toastCard.notification.expireTimeout > 0 ? toastCard.notification.expireTimeout : 5000
            
            // ALWAYS run the timeout, ignoring apps that beg to stay open forever
            running: true 
            
            // Standard pausing logic
            paused: cardHover.hovered || !toastWindow.visible 
            
            onFinished: {
              NotificationService.removePopup(toastCard.notification)
            }
          }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Config.foreground 
            border.width: 1
            radius: 8
        }
      }
    }
  }
}