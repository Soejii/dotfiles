import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

// Monitor arrangement: which output is main (the one in front of you), what
// sits left and right of it, and what mirrors it. All the thinking lives in
// ~/.local/bin/hypr-display, which owns display-layout.json and compiles it to
// the Lua that hyprland.lua reads, so a change made here is a config change and
// survives a reload. This pane only draws it and shells out.
//
// Read once per open, never polled: the arrangement cannot change behind our
// back except by a hotplug, and re-reading on every open is cheap enough.
Item {
    id: pane

    property var monitors: []
    property string mainName: ""
    property bool busy: false

    // Clearing `busy` here is the recovery path, since reset() no longer does:
    // reopening the drawer re-arms the buttons, but only if nothing is running.
    function refresh() { if (!action.running) pane.busy = false; loader.running = true; }
    // Deliberately does NOT clear `busy`. The drawer hides itself during the
    // reload, because the focus grab is cleared when the outputs are
    // reconfigured, and that calls reset() while the change is still being
    // applied. Clearing the flag there re-arms the buttons mid-run, so a second
    // click reassigns a Process that is still working and kills it partway
    // through. `busy` belongs to the process, so only the process clears it.
    function reset()   {}

    function ingest(text) {
        try {
            const data = JSON.parse(text);
            pane.mainName = data.main || "";
            pane.monitors = data.monitors || [];
        } catch (e) {
            // Leave the last good arrangement on screen rather than blanking it.
        }
    }

    Process {
        id: loader
        command: ["/home/suji/.local/bin/hypr-display", "state"]
        stdout: StdioCollector { onStreamFinished: pane.ingest(this.text) }
    }

    // `set` prints the arrangement it just applied, so one round trip both
    // changes the layout and refreshes the pane.
    Process {
        id: action
        stdout: StdioCollector { onStreamFinished: pane.ingest(this.text) }
        onRunningChanged: if (!running) pane.busy = false
    }

    function setSlot(name, slot) {
        if (pane.busy) return;
        pane.busy = true;
        action.command = ["/home/suji/.local/bin/hypr-display", "set", name, slot];
        action.running = true;
    }

    readonly property var placed: pane.monitors.filter(m => m.slot !== "mirror" && m.slot !== "offline")

    component SectionLabel: Text {
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.letterSpacing: 1.2
        color: Theme.muted
    }

    // One cell of a monitor's four-way segmented control.
    component SlotCell: Rectangle {
        id: cell
        property string slotId: ""
        property string label: ""
        property string owner: ""
        property bool current: false
        property bool usable: true

        Layout.fillWidth: true
        Layout.preferredHeight: 26
        radius: 6
        color: !cell.usable ? "transparent"
              : cell.current ? Theme.wash(0.28)
              : cellMouse.containsMouse ? Theme.wash(0.14)
              : Qt.rgba(1, 1, 1, 0.04)
        Behavior on color { ColorAnimation { duration: Theme.anim } }

        Text {
            anchors.centerIn: parent
            text: cell.label
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: !cell.usable ? Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.45)
                 : cell.current ? Theme.accent : Theme.subtext
        }
        MouseArea {
            id: cellMouse
            anchors.fill: parent
            enabled: cell.usable && !cell.current && !pane.busy
            hoverEnabled: cell.usable
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: pane.setSlot(cell.owner, cell.slotId)
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 16
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 10

            // ---- the arrangement, drawn to scale ----
            SectionLabel { text: "ARRANGEMENT" }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 108
                radius: Theme.radius
                color: Theme.base

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    Item {
                        id: stage
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Drawn to scale and top-aligned, because that is exactly
                        // what the generated config does: every monitor gets y = 0.
                        readonly property real sumW: pane.placed.reduce((a, m) => a + (m.width || 0), 0)
                        readonly property real maxH: pane.placed.reduce((a, m) => Math.max(a, m.height || 0), 1)
                        readonly property real k: pane.placed.length === 0 ? 0
                            : Math.min(stage.height / stage.maxH,
                                       (stage.width - 4 * pane.placed.length) / Math.max(stage.sumW, 1))

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            spacing: 4

                            Repeater {
                                model: pane.placed
                                delegate: Rectangle {
                                    id: box
                                    required property var modelData
                                    readonly property bool isMain: modelData.name === pane.mainName
                                    width:  Math.max(24, (modelData.width  || 0) * stage.k)
                                    height: Math.max(16, (modelData.height || 0) * stage.k)
                                    radius: 4
                                    color: box.isMain ? Theme.wash(0.22) : Qt.rgba(1, 1, 1, 0.05)
                                    border.width: 1
                                    border.color: box.isMain ? Theme.accent : Theme.surface

                                    // The block of ten, in its place: the whole
                                    // point of the arrangement is which monitor
                                    // owns which workspaces, and where it sits.
                                    Text {
                                        anchors.centerIn: parent
                                        text: box.modelData.workspaces
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        color: box.isMain ? Theme.accent : Theme.muted
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: pane.placed.length ? "workspace blocks, left to right"
                                                 : "no monitors placed"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: Theme.muted
                    }
                }
            }

            // ---- one card per monitor ----
            SectionLabel { text: "MONITORS"; Layout.topMargin: 4 }

            Repeater {
                model: pane.monitors
                delegate: Rectangle {
                    id: card
                    required property var modelData
                    readonly property bool isMain: modelData.slot === "main"
                    readonly property bool offline: modelData.slot === "offline"

                    Layout.fillWidth: true
                    Layout.preferredHeight: card.offline ? 50 : 84
                    radius: Theme.radius
                    color: Theme.base
                    opacity: card.offline ? 0.55 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "󰍹"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: card.isMain ? Theme.accent : Theme.muted
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    Layout.fillWidth: true
                                    text: card.modelData.label
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    color: Theme.text
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: card.offline
                                          ? card.modelData.name + " · not connected"
                                          : card.modelData.slot === "mirror"
                                          ? card.modelData.name + " · mirroring " + pane.mainName

                                          : card.modelData.name + " · " + card.modelData.width + "×"
                                            + card.modelData.height + "@" + card.modelData.refresh
                                    elide: Text.ElideRight
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.muted
                                }
                            }
                            Rectangle {
                                visible: card.modelData.workspaces.length > 0 || card.modelData.merged > 0
                                Layout.preferredHeight: 18
                                Layout.preferredWidth: wsTag.implicitWidth + 12
                                radius: 5
                                color: Qt.rgba(1, 1, 1, 0.05)
                                Text {
                                    id: wsTag
                                    anchors.centerIn: parent
                                    text: card.modelData.workspaces.length > 0
                                          ? card.modelData.workspaces
                                          : "+" + card.modelData.merged + " ws"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.subtext
                                }
                            }
                        }

                        RowLayout {
                            visible: !card.offline
                            Layout.fillWidth: true
                            spacing: 4

                            SlotCell {
                                owner: card.modelData.name; slotId: "main";   label: "Main"
                                current: card.isMain
                            }
                            SlotCell {
                                owner: card.modelData.name; slotId: "left";   label: "Left"
                                current: card.modelData.slot === "left"
                                usable: !card.isMain
                            }
                            SlotCell {
                                owner: card.modelData.name; slotId: "right";  label: "Right"
                                current: card.modelData.slot === "right"
                                usable: !card.isMain
                            }
                            SlotCell {
                                owner: card.modelData.name; slotId: "mirror"; label: "Mirror"
                                current: card.modelData.slot === "mirror"
                                usable: !card.isMain
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: "Main keeps workspaces 1-10. Each monitor to its right takes the next block of ten, then the ones on its left. Left and right are where the monitor sits, so making one main never moves anything."
                wrapMode: Text.WordWrap
                font.family: Theme.fontFamily
                font.pixelSize: 9
                lineHeight: 1.3
                color: Theme.muted
            }

            Item { Layout.preferredHeight: 4 }
        }
    }
}
