import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: pane

    // ---- system facts, read once per open, never polled ----
    property string uptimeText: "…"
    property bool rebootPending: false

    // Index of the row currently awaiting a second press, -1 for none.
    property int armed: -1

    function refresh() { facts.running = true; }
    function reset()   { pane.armed = -1; }

    // One subprocess for both facts. The reboot check works by asking
    // whether the running kernel's modules directory still exists: pacman
    // removes it when it replaces the package, so no version string ever
    // needs parsing.
    Process {
        id: facts
        command: ["sh", "-c",
            "cut -d. -f1 /proc/uptime; test -d /usr/lib/modules/$(uname -r) && echo ok || echo stale"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                const secs = parseInt(lines[0]);
                if (!isNaN(secs)) {
                    const d = Math.floor(secs / 86400);
                    const h = Math.floor((secs % 86400) / 3600);
                    const m = Math.floor((secs % 3600) / 60);
                    pane.uptimeText = d > 0 ? `${d}d ${h}h` : h > 0 ? `${h}h ${m}m` : `${m}m`;
                }
                pane.rebootPending = (lines[1] || "").trim() === "stale";
            }
        }
    }

    Process { id: runner }

    function run(cmd) { runner.command = cmd; runner.running = true; }

    readonly property var actions: [
        // hyprlock goes into its own systemd scope so a Quickshell restart
        // cannot SIGKILL the locker and strand a session lock.
        { label: "Lock",     icon: "󰌾", confirm: false,
          cmd: ["systemd-run", "--user", "--scope", "--quiet", "hyprlock"] },
        { label: "Suspend",  icon: "󰒲", confirm: false, cmd: ["systemctl", "suspend"] },
        { label: "Logout",   icon: "󰍃", confirm: false, cmd: ["hyprctl", "dispatch", "exit"] },
        { label: "Reboot",   icon: "󰜉", confirm: true,  cmd: ["systemctl", "reboot"] },
        { label: "Shutdown", icon: "󰐥", confirm: true,  cmd: ["systemctl", "poweroff"] }
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // ---- header: uptime and reboot state, as one line ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: Theme.radius
            color: Theme.base

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: "󰅐"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: Theme.muted
                }
                Text {
                    text: "up " + pane.uptimeText
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    color: Theme.subtext
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    visible: pane.rebootPending
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: badge.implicitWidth + 16
                    radius: 6
                    color: Theme.danger_(0.20)
                    Text {
                        id: badge
                        anchors.centerIn: parent
                        text: "󰀦 reboot pending"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.danger
                    }
                }
            }
        }

        // ---- action rows ----
        Repeater {
            model: pane.actions
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index

                readonly property bool isArmed: pane.armed === index

                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: Theme.radius
                color: isArmed ? Theme.danger_(0.14)
                     : rowMouse.containsMouse ? Theme.wash(0.15)
                     : Theme.base
                Behavior on color { ColorAnimation { duration: Theme.anim } }

                // Normal state: icon and label, whole row is the target.
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12
                    visible: !row.isArmed

                    Text {
                        text: row.modelData.icon
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        color: rowMouse.containsMouse ? Theme.accent : Theme.text
                    }
                    Text {
                        text: row.modelData.label
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: rowMouse.containsMouse ? Theme.accent : Theme.text
                    }
                    Item { Layout.fillWidth: true }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !row.isArmed
                    onClicked: {
                        if (row.modelData.confirm) pane.armed = row.index;
                        else { pane.run(row.modelData.cmd); pane.armed = -1; }
                    }
                }

                // Armed state: the row becomes Confirm / Cancel, so the
                // second press lands on a different target than the first.
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6
                    visible: row.isArmed

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        color: confirmMouse.containsMouse ? Theme.danger_(0.45) : Theme.danger_(0.28)
                        Behavior on color { ColorAnimation { duration: Theme.anim } }
                        Text {
                            anchors.centerIn: parent
                            text: row.modelData.label + "?"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.danger
                        }
                        MouseArea {
                            id: confirmMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { pane.run(row.modelData.cmd); pane.armed = -1; }
                        }
                    }
                    Rectangle {
                        Layout.preferredWidth: 84
                        Layout.fillHeight: true
                        radius: 6
                        color: cancelMouse.containsMouse ? Theme.wash(0.20) : Qt.rgba(1, 1, 1, 0.06)
                        Behavior on color { ColorAnimation { duration: Theme.anim } }
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.subtext
                        }
                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: pane.armed = -1
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
