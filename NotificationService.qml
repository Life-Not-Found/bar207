// NotificationService.qml
pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
  id: root

  // --- NEW: A safe list specifically for active on-screen popups
  ListModel { id: popupModel }
  property alias activePopups: popupModel

  NotificationServer {
    id: server
    keepOnReload: true
    
    bodySupported: true
    persistenceSupported: true
    actionsSupported: true
    imageSupported: true
    inlineReplySupported: true

    onNotification: (notification) => {
      console.log("🔔 NOTIFICATION ARRIVED:", notification.summary)
      notification.tracked = true 
      
      // NEW: Add the incoming notification to our popup list!
      // We insert at index 0 so newest notifications stack at the top
      root.activePopups.insert(0, { "notif": notification })
    }
  }

  readonly property var notifications: server.trackedNotifications

  // --- NEW: A helper function to hide the toast when the timer expires 
  // (This hides the popup, but safely keeps it in your main history window!)
  function removePopup(notification) {
    for (let i = 0; i < root.activePopups.count; i++) {
      if (root.activePopups.get(i).notif === notification) {
        root.activePopups.remove(i, 1)
        break
      }
    }
  }
}