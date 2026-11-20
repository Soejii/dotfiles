import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

// Local LLM: one switch for llama-server.service, plus what it is costing.
// The model fills ~15 GB of the 16 GB card, so the switch is the point:
// off before a game, on when you want to chat or run Pi against it.
Item {
    id: pane

    function refresh() { poll.running = true; status.running = true; }
    function reset()   { poll.running = false; }
    Component.onDestruction: poll.running = false

    property string llmState: "off"        // off | loading | on | failed
    property string model: ""
    property real vramUsed: 0
    property real vramTotal: 1
    property bool busy: false           // a toggle is in flight
    property string gpuMv: ""           // live VDDGFX offset, e.g. "-30"
    property string gpuCap: ""          // live power cap in W
    property string gpuMode: ""         // "compute" while any ROCm process runs, else "game"

    Timer {
        id: poll
        interval: 1500; repeat: true; running: false
        onTriggered: status.running = true
    }

    Process {
        id: status
        command: ["/home/suji/.config/quickshell/scripts/llm.sh", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of this.text.trim().split("\n")) {
                    const eq = line.indexOf("=");
                    if (eq < 0) continue;
                    const k = line.slice(0, eq), v = line.slice(eq + 1);
                    if (k === "state") pane.llmState = v;
                    else if (k === "model") pane.model = v;
                    else if (k === "vram_used") pane.vramUsed = parseFloat(v);
                    else if (k === "vram_total") pane.vramTotal = parseFloat(v) || 1;
                    else if (k === "gpu_mv") pane.gpuMv = v;
                    else if (k === "gpu_cap") pane.gpuCap = v;
                    else if (k === "gpu_mode") pane.gpuMode = v;
                }
            }
        }
    }

    // The toggle script blocks until the model is loaded or the unit stopped,
    // so `running` doubles as the busy flag.
    Process {
        id: toggler
        command: ["/home/suji/.config/quickshell/scripts/llm.sh", "toggle"]
        onRunningChanged: { pane.busy = running; status.running = true; }
    }
    function toggle() {
        if (toggler.running) return;
        if (pane.llmState === "off" || pane.llmState === "failed") pane.llmState = "loading";
        toggler.running = true;
    }

    Process { id: runner }
    function run(cmd) { runner.command = cmd; runner.running = true; }

    readonly property bool isOn: pane.llmState === "on"
    function stateLabel() {
        if (pane.busy && pane.llmState === "on") return "STOPPING";
        return { off: "OFF", loading: "LOADING", on: "ON", failed: "FAILED" }[pane.llmState] || pane.llmState.toUpperCase();
    }
    function stateColor() {
        if (pane.llmState === "on") return Theme.ok;
        if (pane.llmState === "loading" || pane.busy) return "#f9e2af";
        if (pane.llmState === "failed") return Theme.danger;
        return Theme.muted;
    }
    function gb(b) { return (b / 1e9).toFixed(1) }
    function loadColor(f) {
        if (f >= 0.95) return Theme.danger;
        if (f >= 0.80) return Theme.warn;
        return Theme.accent;
    }

    component SectionLabel: Text {
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.letterSpacing: 1.2
        color: Theme.muted
    }

    component ActionRow: Rectangle {
        id: act
        property string icon: ""
        property string label: ""
        property string hint: ""
        property bool enabled_: true
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: Theme.radius
        opacity: enabled_ ? 1 : 0.4
        color: actMouse.containsMouse && enabled_ ? Theme.wash(0.15) : Theme.base
        Behavior on color { ColorAnimation { duration: Theme.anim } }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10
            Text {
                text: act.icon
                font.family: Theme.fontFamily
                font.pixelSize: 16
                color: Theme.accent
            }
            Text {
                Layout.fillWidth: true
                text: act.label
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: Theme.text
            }
            Text {
                text: act.hint
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.muted
            }
        }
        MouseArea {
            id: actMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: if (act.enabled_) act.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // ---- the switch ----
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            radius: Theme.radiusLarge
            color: pane.isOn ? Theme.wash(0.25)
                 : switchMouse.containsMouse ? Theme.wash(0.15)
                 : Theme.base
            Behavior on color { ColorAnimation { duration: Theme.anim } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10
                Text {
                    text: "󰚩"
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                    color: pane.stateColor()
                    Behavior on color { ColorAnimation { duration: Theme.anim } }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "LOCAL LLM"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.text
                    }
                    Text {
                        text: pane.isOn ? "click to unload" : pane.llmState === "loading" ? "loading into VRAM…" : "click to load"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.muted
                    }
                }
                Text {
                    text: pane.stateLabel()
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.bold: true
                    color: pane.stateColor()
                }
            }
            MouseArea {
                id: switchMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pane.busy ? Qt.BusyCursor : Qt.PointingHandCursor
                onClicked: pane.toggle()
            }
        }

        // ---- model ----
        SectionLabel { text: "MODEL"; Layout.topMargin: 4 }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: Theme.radius
            color: Theme.base
            Text {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                text: pane.model.length ? pane.model : "qwen3.8-27b-heretic"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                color: pane.isOn ? Theme.text : Theme.muted
            }
        }

        // ---- VRAM ----
        Rectangle {
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
                        text: "VRAM"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.subtext
                    }
                    Text {
                        text: pane.gb(pane.vramUsed) + " / " + pane.gb(pane.vramTotal) + " GB"
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
                        readonly property real f: Math.max(0, Math.min(1, pane.vramUsed / pane.vramTotal))
                        width: f * parent.width
                        height: parent.height
                        radius: 3
                        color: pane.loadColor(f)
                        Behavior on width { NumberAnimation { duration: Theme.anim } }
                        Behavior on color { ColorAnimation { duration: Theme.anim } }
                    }
                }
            }
        }

        // ---- use it ----
        // ---- GPU voltage mode (gpu-uv-moded) ----
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
                    Layout.fillWidth: true
                    text: "GPU MODE"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.subtext
                }
                Text {
                    text: (pane.gpuMode === "compute" ? "compute" : "game")
                          + "  " + (pane.gpuMv.length ? pane.gpuMv + " mV" : "–")
                          + "  " + (pane.gpuCap.length ? pane.gpuCap + " W" : "")
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: pane.gpuMode === "compute" ? Theme.accent : Theme.text
                }
            }
        }

        SectionLabel { text: "OPEN"; Layout.topMargin: 4 }
        ActionRow {
            icon: "󰖟"; label: "Chat in browser"; hint: ":8080"
            enabled_: pane.isOn
            onClicked: { pane.run(["xdg-open", "http://127.0.0.1:8080"]); }
        }
        ActionRow {
            icon: "󰆍"; label: "Pi with local model"; hint: "terminal"
            enabled_: pane.isOn
            onClicked: pane.run(["systemd-run", "--user", "--scope", "--quiet",
                                 "alacritty", "-e", "/home/suji/.local/bin/pi",
                                 "--provider", "local", "--model", "qwen3.8-27b-heretic"])
        }
        ActionRow {
            icon: "󰦪"; label: "Server log"; hint: "journal"
            onClicked: pane.run(["systemd-run", "--user", "--scope", "--quiet",
                                 "alacritty", "-e", "journalctl", "--user", "-u", "llama-server", "-f"])
        }

        Item { Layout.fillHeight: true }
    }
}
