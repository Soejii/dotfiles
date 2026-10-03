import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

// Readouts only, deliberately: no graphs and no process control. Graphs would
// need continuous polling to have any history by the time you open the drawer,
// and btop already does the job properly when you actually need it.
Item {
    id: pane

    function refresh() { poll.running = true; collector.running = true; caffeineStatus.running = true; }
    function reset()   { poll.running = false; }
    Component.onDestruction: poll.running = false

    property real cpuPct: 0
    property real memUsedKb: 0
    property real memTotalKb: 1
    property string tCpu: ""
    property string tGpu: ""
    property string tNvme: ""
    property string diskUsed: ""
    property string diskTotal: ""
    property real diskPct: 0
    property var procs: []
    property bool caffeine: false
    property string caffeineMode: ""     // "10", "30" or "always" while on
    property int caffeineLeft: -1         // seconds left in a timed mode, else -1

    // Previous /proc/stat sample, so the first tick produces no bogus spike.
    property real prevTotal: 0
    property real prevIdle: 0
    property bool haveSample: false

    Timer {
        id: poll
        interval: 2000; repeat: true; running: false
        onTriggered: { collector.running = true; caffeineStatus.running = true; }
    }

    // Caffeine state always comes from the live inhibitor list (via the
    // script), never from QML state, so it is right after a reload.
    Process {
        id: caffeineStatus
        command: ["/home/suji/.config/quickshell/scripts/caffeine.sh", "status"]
        stdout: StdioCollector {
            onStreamFinished: pane.readCaffeine(this.text)
        }
    }
    // One click steps off -> 10 min -> 30 min -> always -> off.
    Process {
        id: caffeineSet
        command: ["/home/suji/.config/quickshell/scripts/caffeine.sh", "cycle"]
        stdout: StdioCollector {
            onStreamFinished: pane.readCaffeine(this.text)
        }
    }
    function toggleCaffeine() { caffeineSet.running = true; }
    // Status is "off" or "on <10|30|always> <seconds left|->".
    function readCaffeine(text) {
        const p = text.trim().split(/\s+/);
        pane.caffeine = p[0] === "on";
        pane.caffeineMode = pane.caffeine ? (p[1] || "always") : "";
        const left = parseInt(p[2]);
        pane.caffeineLeft = isNaN(left) ? -1 : left;
    }
    function caffeineLabel() {
        if (!pane.caffeine) return "OFF";
        if (pane.caffeineMode === "always") return "ALWAYS";
        const l = Math.max(0, pane.caffeineLeft);
        const mm = Math.floor(l / 60), ss = l % 60;
        return pane.caffeineMode + " MIN · " + mm + ":" + (ss < 10 ? "0" : "") + ss;
    }

    Process {
        id: collector
        command: ["/home/suji/.config/quickshell/scripts/sysinfo.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of this.text.trim().split("\n")) {
                    const eq = line.indexOf("=");
                    if (eq < 0) continue;
                    const k = line.slice(0, eq), v = line.slice(eq + 1);
                    if (k === "cpu") {
                        const p = v.split(" ");
                        const total = parseFloat(p[0]), idle = parseFloat(p[1]);
                        if (pane.haveSample) {
                            const dt = total - pane.prevTotal, di = idle - pane.prevIdle;
                            if (dt > 0) pane.cpuPct = Math.max(0, Math.min(1, 1 - di / dt));
                        }
                        pane.prevTotal = total; pane.prevIdle = idle; pane.haveSample = true;
                    } else if (k === "mem") {
                        const p = v.split(" ");
                        pane.memTotalKb = parseFloat(p[0]);
                        pane.memUsedKb  = parseFloat(p[0]) - parseFloat(p[1]);
                    } else if (k === "tcpu")  pane.tCpu = v;
                    else if (k === "tgpu")    pane.tGpu = v;
                    else if (k === "tnvme")   pane.tNvme = v;
                    else if (k === "disk") {
                        const p = v.split(" ");
                        pane.diskUsed = p[0] || "–"; pane.diskTotal = p[1] || "–";
                        const pct = parseFloat(p[2]);
                        pane.diskPct = isNaN(pct) ? 0 : pct / 100;
                    } else if (k === "proc") {
                        const sp = v.lastIndexOf(" ");
                        out.push({ name: v.slice(0, sp), mb: parseInt(v.slice(sp + 1)) });
                    }
                }
                pane.procs = out;
            }
        }
    }

    function gb(kb) { return (kb / 1048576).toFixed(1) }
    function tempColor(t) {
        const v = parseInt(t);
        if (isNaN(v)) return Theme.muted;
        if (v >= 85) return Theme.danger;
        if (v >= 70) return Theme.warn;
        return Theme.ok;
    }
    function loadColor(f) {
        if (isNaN(f)) return Theme.muted;
        if (f >= 0.90) return Theme.danger;
        if (f >= 0.70) return Theme.warn;
        return Theme.accent;
    }

    component SectionLabel: Text {
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.letterSpacing: 1.2
        color: Theme.muted
    }

    // label, filled bar, and a value on the right
    component StatRow: Rectangle {
        property string label: ""
        property string value: ""
        property real fraction: 0
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: Theme.radius
        color: Theme.base

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 7
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: parent.parent.parent.label
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.subtext
                }
                Text {
                    text: parent.parent.parent.value
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.text
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 5
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.08)
                Rectangle {
                    width: Math.max(0, Math.min(1, parent.parent.parent.fraction || 0)) * parent.width
                    height: parent.height
                    radius: 3
                    color: pane.loadColor(parent.parent.parent.fraction)
                    Behavior on width { NumberAnimation { duration: Theme.anim } }
                    Behavior on color { ColorAnimation { duration: Theme.anim } }
                }
            }
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

            // ---- caffeine: click cycles off / 10 min / 30 min / always ----
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                radius: Theme.radius
                color: pane.caffeine ? Theme.wash(0.25)
                     : caffeineMouse.containsMouse ? Theme.wash(0.15)
                     : Theme.base
                Behavior on color { ColorAnimation { duration: Theme.anim } }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    Text {
                        text: "󰅶"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: pane.caffeine ? Theme.accent : Theme.muted
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "CAFFEINE"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.subtext
                    }
                    Text {
                        text: pane.caffeineLabel()
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: pane.caffeine ? Theme.ok : Theme.muted
                    }
                }
                MouseArea {
                    id: caffeineMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pane.toggleCaffeine()
                }
            }

            StatRow {
                label: "CPU"
                fraction: pane.cpuPct
                value: Math.round(pane.cpuPct * 100) + "%"
            }
            StatRow {
                label: "MEMORY"
                fraction: pane.memUsedKb / pane.memTotalKb
                value: pane.gb(pane.memUsedKb) + " / " + pane.gb(pane.memTotalKb) + " GB"
            }
            StatRow {
                label: "DISK  /"
                fraction: pane.diskPct
                value: pane.diskUsed + " / " + pane.diskTotal
            }

            // ---- temperatures ----
            SectionLabel { text: "TEMPERATURE"; Layout.topMargin: 4 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                component TempTile: Rectangle {
                    property string tag: ""
                    property string temp: ""
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: Theme.radius
                    color: Theme.base
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 1
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: parent.parent.temp.length ? parent.parent.temp + "°" : "–"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            color: pane.tempColor(parent.parent.temp)
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: parent.parent.tag
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            color: Theme.muted
                        }
                    }
                }

                TempTile { tag: "CPU";  temp: pane.tCpu }
                TempTile { tag: "GPU";  temp: pane.tGpu }
                TempTile { tag: "NVME"; temp: pane.tNvme }
            }

            // ---- heaviest processes ----
            SectionLabel { text: "TOP MEMORY"; Layout.topMargin: 4 }
            Repeater {
                model: pane.procs
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: Theme.radius
                    color: Theme.base
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.text
                        }
                        Text {
                            text: modelData.mb >= 1024
                                  ? (modelData.mb / 1024).toFixed(1) + " GB"
                                  : modelData.mb + " MB"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.subtext
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }
        }
    }
}
