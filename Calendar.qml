import Quickshell
import QtQuick
import QtQuick.Layouts

PopupWindow {
  id: calendarWindow
  visible: false
  color: "transparent"

  property var parentBar: null
  anchor.window: parentBar

  // Internal state for which month/year we're viewing
  property int viewYear: new Date().getFullYear()
  property int viewMonth: new Date().getMonth() // 0-indexed

  // Reset to current month when opened
  onVisibleChanged: {
    if (visible) {
      viewYear = new Date().getFullYear()
      viewMonth = new Date().getMonth()
    }
  }

  implicitWidth: 280
  implicitHeight: calendarLayout.implicitHeight + 24

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
          calendarWindow.visible = false
          hasHovered = false
        }
      }
    }

    ColumnLayout {
      id: calendarLayout
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        topMargin: 12
        leftMargin: 12
        rightMargin: 12
        bottomMargin: 12
      }
      spacing: 8

      // Month/year header with prev/next buttons
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "󰜱"
          color: prevArea.containsMouse ? Config.foreground : Config.inactive
          font.pixelSize: 14
          MouseArea {
            id: prevArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              if (calendarWindow.viewMonth === 0) {
                calendarWindow.viewMonth = 11
                calendarWindow.viewYear -= 1
              } else {
                calendarWindow.viewMonth -= 1
              }
            }
          }
        }

        Text {
          Layout.fillWidth: true
          horizontalAlignment: Text.AlignHCenter
          text: Qt.formatDate(new Date(calendarWindow.viewYear, calendarWindow.viewMonth, 1), "MMMM yyyy")
          color: Config.foreground
          font.pixelSize: 14
          font.bold: true
        }

        Text {
          text: "󰜴"
          color: nextArea.containsMouse ? Config.foreground : Config.inactive
          font.pixelSize: 14
          MouseArea {
            id: nextArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              if (calendarWindow.viewMonth === 11) {
                calendarWindow.viewMonth = 0
                calendarWindow.viewYear += 1
              } else {
                calendarWindow.viewMonth += 1
              }
            }
          }
        }
      }

      // Separator
      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Config.foreground
        opacity: 0.2
      }

      // Day of week headers
      Grid {
        Layout.fillWidth: true
        columns: 7
        spacing: 2

        Repeater {
          model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
          Text {
            width: (calendarLayout.width - 12) / 7
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            color: Config.inactive
            font.pixelSize: 11
          }
        }
      }

      // Day grid
      Grid {
        id: dayGrid
        Layout.fillWidth: true
        columns: 7
        spacing: 2

        property var today: new Date()
        property int todayDay: today.getDate()
        property int todayMonth: today.getMonth()
        property int todayYear: today.getFullYear()

        // Day of week the 1st falls on (0=Sun..6=Sat), shifted to Mon-first
        property int firstDayOfWeek: {
          var d = new Date(calendarWindow.viewYear, calendarWindow.viewMonth, 1).getDay()
          return (d + 6) % 7  // Monday = 0
        }

        property int daysInMonth: new Date(calendarWindow.viewYear, calendarWindow.viewMonth + 1, 0).getDate()
        property int totalCells: firstDayOfWeek + daysInMonth

        Repeater {
          model: Math.ceil(dayGrid.totalCells / 7) * 7

          Rectangle {
            width: (calendarLayout.width - 12) / 7
            height: width
            radius: width / 2
            color: {
              var day = index - dayGrid.firstDayOfWeek + 1
              if (day < 1 || day > dayGrid.daysInMonth) return "transparent"
              if (day === dayGrid.todayDay &&
                  calendarWindow.viewMonth === dayGrid.todayMonth &&
                  calendarWindow.viewYear === dayGrid.todayYear)
                return Config.selection
              return "transparent"
            }

            Text {
              anchors.centerIn: parent
              property int day: index - dayGrid.firstDayOfWeek + 1
              text: (day >= 1 && day <= dayGrid.daysInMonth) ? day : ""
              color: {
                if (day === dayGrid.todayDay &&
                    calendarWindow.viewMonth === dayGrid.todayMonth &&
                    calendarWindow.viewYear === dayGrid.todayYear)
                  return Config.foreground
                return day >= 1 && day <= dayGrid.daysInMonth ? Config.foreground : "transparent"
              }
              font.pixelSize: 12
            }
          }
        }
      }
    }
  }
}