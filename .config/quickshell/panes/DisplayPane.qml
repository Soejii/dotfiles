import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

// Monitor arrangement: which output is main (the one in front of you), where
// every other output sits around it, and what mirrors it. All the thinking
// lives in ~/.local/bin/hypr-display, which owns display-layout.json and
// compiles it to the Lua that hyprland.lua reads, so a change made here is a
// config change and survives a reload. This pane only draws it and shells out.
//
// The arrangement is a canvas: drag a monitor anywhere and let go, and
// `hypr-display move` snaps it onto the nearest free edge of another monitor
// (start, centre or end aligned when the drop lands near one). The snapping is
// done there, not here, so the pane and the config can never disagree.
//
// Read on every open, and live while open: `hypr-display events` streams
// Hyprland's monitor add/remove events, so a monitor plugged in (or the phone
// starting to stream) shows up without closing the drawer. That listener only
// runs while the pane is on screen, like the Wi-Fi scanner.
Item {
    id: pane

    property var monitors: []
    property string mainName: ""
    property bool busy: false
    property bool live: false

    // Clearing `busy` here is the recovery path, since reset() no longer does:
    // reopening the drawer re-arms the controls, but only if nothing is running.
    function refresh() {
        if (!action.running) pane.busy = false;
        pane.live = true;
        loader.running = true;
    }
    // Deliberately does NOT clear `busy`. The drawer hides itself during the
    // reload, because the focus grab is cleared when the outputs are
    // reconfigured, and that calls reset() while the change is still being
    // applied. Clearing the flag there re-arms the controls mid-run, so a second
    // click reassigns a Process that is still working and kills it partway
    // through. `busy` belongs to the process, so only the process clears it.
    // Stopping the listener is safe here even mid-apply: it only triggers
    // re-reads, and the apply's own output refreshes the pane when it lands.
    function reset()   { pane.live = false; }

    function ingest(text) {
        try {
            const data = JSON.parse(text);
            pane.mainName = data.main || "";
            // A fresh array even when nothing moved, so a drop that snapped back
            // to where it started still rebuilds the boxes and their bindings.
            pane.monitors = (data.monitors || []).slice();
        } catch (e) {
            // Leave the last good arrangement on screen rather than blanking it.
            pane.monitors = pane.monitors.slice();
        }
    }

    Process {
        id: loader
        command: ["/home/suji/.local/bin/hypr-display", "state"]
        stdout: StdioCollector { onStreamFinished: pane.ingest(this.text) }
    }

    Process {
        id: events
        command: ["/home/suji/.local/bin/hypr-display", "events"]
        running: pane.live
        stdout: SplitParser { onRead: settle.restart() }
    }
    // One re-read per burst: a reload drops and re-adds every output at once.
    // Skipped while our own change is running; its output is the fresher read.
    Timer {
        id: settle
        interval: 600
        onTriggered: if (!pane.busy && !action.running) loader.running = true
    }

    // `set` and `move` print the arrangement they just applied, so one round
    // trip both changes the layout and refreshes the pane.
    Process {
        id: action
        stdout: StdioCollector { onStreamFinished: pane.ingest(this.text) }
        onRunningChanged: if (!running) pane.busy = false
    }

    function run(args) {
        if (pane.busy) return false;
        pane.busy = true;
        action.command = ["/home/suji/.local/bin/hypr-display"].concat(args);
        action.running = true;
        return true;
    }
    function setSlot(name, slot) { pane.run(["set", name, slot]); }
    function moveTo(name, x, y) {
        if (!pane.run(["move", name, String(Math.round(x)), String(Math.round(y))]))
            pane.monitors = pane.monitors.slice();     // busy: snap the box back
    }

    // Everything that has a place on the canvas; a standby output (the phone)
    // keeps its place while it is absent, drawn faded.
    readonly property var placed: pane.monitors.filter(
        m => m.slot === "main" || m.slot === "extend" || m.slot === "standby")

    component SectionLabel: Text {
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.letterSpacing: 1.2
        color: Theme.muted
    }

    // One cell of a monitor's segmented control.
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
        // A drag on a monitor box must move the box, not scroll the pane.
        interactive: !stage.dragging

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 10

            // ---- the arrangement, drawn to scale, draggable ----
            SectionLabel { text: "ARRANGEMENT" }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                radius: Theme.radius
                color: Theme.base

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Item {
                        id: stage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        property bool dragging: false

                        // Bounds of the whole arrangement in logical pixels.
                        readonly property real minX: pane.placed.reduce((a, m) => Math.min(a, m.x), Infinity)
                        readonly property real minY: pane.placed.reduce((a, m) => Math.min(a, m.y), Infinity)
                        readonly property real maxX: pane.placed.reduce((a, m) => Math.max(a, m.x + m.width), -Infinity)
                        readonly property real maxY: pane.placed.reduce((a, m) => Math.max(a, m.y + m.height), -Infinity)
                        readonly property real spanW: Math.max(1, maxX - minX)
                        readonly property real spanH: Math.max(1, maxY - minY)
                        // Room around the arrangement to drop a monitor beside,
                        // above or below everything that is already there.
                        readonly property real pad: 0.32
                        readonly property real k: pane.placed.length === 0 ? 0
                            : Math.min(stage.width / (stage.spanW * (1 + 2 * stage.pad)),
                                       stage.height / (stage.spanH * (1 + 2 * stage.pad)))
                        // Screen position of logical 0,0, centring the arrangement.
                        readonly property real ox: stage.width / 2 - (stage.minX + stage.spanW / 2) * stage.k
                        readonly property real oy: stage.height / 2 - (stage.minY + stage.spanH / 2) * stage.k

                        Repeater {
                            model: pane.placed
                            delegate: Rectangle {
                                id: box
                                required property var modelData
                                readonly property bool isMain: modelData.slot === "main"
                                readonly property bool absent: !modelData.connected

                                x: stage.ox + modelData.x * stage.k
                                y: stage.oy + modelData.y * stage.k
                                width:  Math.max(18, modelData.width  * stage.k)
                                height: Math.max(12, modelData.height * stage.k)
                                z: boxMouse.drag.active ? 10 : 1
                                radius: 4
                                opacity: boxMouse.drag.active ? 0.85 : box.absent ? 0.5 : 1
                                color: box.isMain ? Theme.wash(0.22)
                                     : boxMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.09)
                                     : Qt.rgba(1, 1, 1, 0.05)
                                border.width: 1
                                border.color: boxMouse.drag.active ? Theme.accent
                                            : box.isMain ? Theme.accent : Theme.surface

                                property real startX: 0
                                property real startY: 0

                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - 6
                                    spacing: 1
                                    Text {
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        text: box.modelData.label
                                        elide: Text.ElideRight
                                        visible: box.height >= 26
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        color: box.isMain ? Theme.accent : Theme.subtext
                                    }
                                    // Which block of ten lives there: the point of
                                    // the arrangement is which monitor owns which
                                    // workspaces, and where it sits.
                                    Text {
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        text: box.absent ? box.modelData.workspaces + " · standby"
                                                         : box.modelData.workspaces
                                        elide: Text.ElideRight
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        color: box.isMain ? Theme.accent : Theme.muted
                                    }
                                }

                                MouseArea {
                                    id: boxMouse
                                    anchors.fill: parent
                                    enabled: !pane.busy
                                    hoverEnabled: true
                                    cursorShape: pane.busy ? Qt.BusyCursor
                                               : drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                    drag.target: box
                                    drag.threshold: 3
                                    drag.minimumX: 0
                                    drag.minimumY: 0
                                    drag.maximumX: stage.width - box.width
                                    drag.maximumY: stage.height - box.height
                                    onPressed: { box.startX = box.x; box.startY = box.y; }
                                    drag.onActiveChanged: stage.dragging = drag.active
                                    onReleased: {
                                        // A click that never became a drag changes nothing.
                                        if (Math.abs(box.x - box.startX) < 3 && Math.abs(box.y - box.startY) < 3)
                                            return;
                                        pane.moveTo(box.modelData.name,
                                                    (box.x - stage.ox) / stage.k,
                                                    (box.y - stage.oy) / stage.k);
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: pane.busy ? "applying…"
                              : pane.placed.length ? "drag a monitor onto any edge of another"
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
                    readonly property bool mirroring: modelData.slot === "mirror"
                    readonly property bool standbyAbsent: modelData.slot === "standby"

                    Layout.fillWidth: true
                    Layout.preferredHeight: 84
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
                                          : card.mirroring
                                          ? card.modelData.name + " · mirroring " + pane.mainName
                                          : card.standbyAbsent
                                          ? card.modelData.name + " · appears while streaming"
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

                        // Position is the canvas's job now; the card only
                        // decides what the monitor IS: main, or a mirror of it.
                        RowLayout {
                            visible: !card.offline
                            Layout.fillWidth: true
                            spacing: 4

                            SlotCell {
                                owner: card.modelData.name; slotId: "main"; label: "Main"
                                current: card.isMain
                                usable: card.modelData.connected && !card.mirroring
                            }
                            SlotCell {
                                owner: card.modelData.name; slotId: "extend"; label: "Extend"
                                current: !card.isMain && !card.mirroring
                                usable: !card.isMain
                            }
                            SlotCell {
                                owner: card.modelData.name; slotId: "mirror"; label: "Mirror"
                                current: card.mirroring
                                usable: !card.isMain && !card.standbyAbsent
                            }
                        }

                        // A monitor that is gone for good keeps its place and
                        // block until it is forgotten; plug it back in first
                        // if it should keep them.
                        RowLayout {
                            visible: card.offline
                            Layout.fillWidth: true
                            spacing: 4
                            SlotCell {
                                owner: card.modelData.name; slotId: "forget"; label: "Forget this monitor"
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 2
                text: "Drag monitors to arrange them; they snap onto the nearest edge. Main keeps workspaces 1-10, then its row takes the next blocks (right of it first, then left), then anything above or below. Making a monitor main never moves anything."
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
