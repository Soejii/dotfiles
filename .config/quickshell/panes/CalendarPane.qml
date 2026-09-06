import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Item {
    id: pane

    // The clock only ticks while the pane is on screen, same discipline as
    // the network scanner.
    function refresh() { pane.now = new Date(); pane.goToday(); tick.running = true; }
    function reset()   { tick.running = false; }

    property date now: new Date()
    // First of the month currently being displayed.
    property date shown: new Date(now.getFullYear(), now.getMonth(), 1)

    // 2026-01-04 was a Sunday; used to name the weekday columns without
    // depending on Qt's Locale day enum, which numbers days differently
    // from JavaScript's getDay().
    readonly property date sundayRef: new Date(2026, 0, 4)

    readonly property bool onCurrentMonth:
        shown.getFullYear() === now.getFullYear() && shown.getMonth() === now.getMonth()

    Timer {
        id: tick
        interval: 1000; repeat: true; running: false
        onTriggered: pane.now = new Date()
    }

    function goToday()  { shown = new Date(now.getFullYear(), now.getMonth(), 1); }
    function shiftMonth(d) { shown = new Date(shown.getFullYear(), shown.getMonth() + d, 1); }

    function isSameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth()    === b.getMonth()
            && a.getDate()     === b.getDate();
    }

    // 42 cells, six full weeks, so the grid never changes height between
    // months and the rows below it do not jump.
    readonly property var cells: {
        const first = new Date(shown.getFullYear(), shown.getMonth(), 1);
        const start = new Date(first);
        start.setDate(1 - first.getDay());          // back up to the Sunday
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === shown.getMonth(),
                isToday: pane.isSameDay(d, pane.now)
            });
        }
        return out;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // ---- live clock and full date ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 78
            radius: Theme.radius
            color: Theme.base

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatTime(pane.now, "HH:mm:ss")
                    font.family: Theme.fontFamily
                    font.pixelSize: 26
                    color: Theme.text
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDate(pane.now, "dddd, dd MMMM yyyy")
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.subtext
                }
            }
        }

        // ---- month navigation ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            component NavButton: Rectangle {
                property string glyph: ""
                signal activated()
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: Theme.radius
                color: navMouse.containsMouse ? Theme.wash(0.18) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.anim } }
                Text {
                    anchors.centerIn: parent
                    text: parent.glyph
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: navMouse.containsMouse ? Theme.accent : Theme.subtext
                }
                MouseArea {
                    id: navMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: parent.activated()
                }
            }

            NavButton { glyph: "󰅁"; onActivated: pane.shiftMonth(-1) }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(pane.shown, "MMMM yyyy")
                font.family: Theme.fontFamily
                font.pixelSize: 13
                color: Theme.text
            }
            NavButton { glyph: "󰅂"; onActivated: pane.shiftMonth(1) }
        }

        // ---- weekday header ----
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 2
            rowSpacing: 2
            Repeater {
                model: 7
                delegate: Text {
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(
                        new Date(pane.sundayRef.getFullYear(), pane.sundayRef.getMonth(),
                                 pane.sundayRef.getDate() + index), "ddd").charAt(0)
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.muted
                }
            }
        }

        // ---- the month itself ----
        GridLayout {
            Layout.fillWidth: true
            columns: 7
            columnSpacing: 2
            rowSpacing: 2

            Repeater {
                model: pane.cells
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Theme.radius
                    color: modelData.isToday ? Theme.wash(0.28) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: modelData.isToday
                        color: modelData.isToday ? Theme.accent
                             : modelData.inMonth ? Theme.text
                             : Theme.muted
                    }
                }
            }
        }

        // ---- jump back, only when it would do something ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            visible: !pane.onCurrentMonth
            radius: Theme.radius
            color: todayMouse.containsMouse ? Theme.wash(0.25) : Theme.base
            Behavior on color { ColorAnimation { duration: Theme.anim } }
            Text {
                anchors.centerIn: parent
                text: "Today"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.accent
            }
            MouseArea {
                id: todayMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: pane.goToday()
            }
        }

        Item { Layout.fillHeight: true }
    }

    // Scrolling anywhere over the pane shifts months, matching the behaviour
    // your waybar clock tooltip already has.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (w) => pane.shiftMonth(w.angleDelta.y > 0 ? -1 : 1)
    }
}
