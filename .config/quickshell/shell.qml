import Quickshell
import Quickshell.Io

// Entry point. Waybar drives the drawer through `qs ipc`, via
// ~/.config/waybar/scripts/drawer.sh which resolves the focused monitor:
//   qs ipc call drawer toggle power DP-1
ShellRoot {
    Drawer { id: drawer }

    IpcHandler {
        target: "drawer"

        function toggle(pane: string, monitor: string): void { drawer.toggle(pane, monitor); }
        function open(pane: string, monitor: string): void   { drawer.openPane(pane, monitor); }
        function close(): void                               { drawer.hide(); }
    }
}
