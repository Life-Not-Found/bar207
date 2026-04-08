// shell.qml
import Quickshell
import Quickshell.Hyprland

Scope {
  // Instantiate the PowerMenu globally
  PowerMenu {
    id: powerMenu
  }

  Bar {}
  
  Variants {
    model: Quickshell.screens
    ToastNotifications {
      required property var modelData
      screen: modelData
      visible: modelData.name === Hyprland.focusedMonitor?.name
    }
  }
}