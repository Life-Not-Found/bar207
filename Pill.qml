import QtQuick

Rectangle {
  default property alias content: container.children

  radius: height / 3
  color: Colors.background
  implicitHeight: 32
  implicitWidth: container.implicitWidth + 24

  Item {
    id: container
    anchors.centerIn: parent
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
  }
}