import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import ".."

Item {
    id: pane

    function refresh() {}
    function reset() {}

    // PipeWire node data only stays live while the nodes are tracked.
    PwObjectTracker { objects: Pipewire.nodes.values }

    readonly property var sinks: Pipewire.nodes.values.filter(
        n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(
        n => !n.isSink && !n.isStream && n.audio
             && (n.properties || {})["media.class"] === "Audio/Source")
    readonly property var streams: Pipewire.nodes.values.filter(
        n => n.isStream && n.isSink && n.audio)

    // node.nick is far more readable than the ALSA description pactl reports:
    // "MSI MAG 275QF" rather than "Navi 48 HDMI/DP Audio Controller Digital
    // Stereo (HDMI)". Fall back only when a node has no nickname at all.
    function label(n) {
        if (!n) return "none";
        return n.nickname || n.description || n.name || "unknown";
    }
    function appLabel(n) {
        const p = n.properties || {};
        return p["application.name"] || p["media.name"] || label(n);
    }
    function deviceIcon(n) {
        const p = n.properties || {};
        if ((n.name || "").indexOf("hdmi") >= 0) return "󰍹";
        if (p["device.bus"] === "usb") return "󰋋";
        return "󰓃";
    }

    // ---- reusable volume bar ----
    component VolumeBar: Item {
        id: bar
        property var node: null
        property color tint: Theme.accent
        readonly property real vol: node && node.audio ? node.audio.volume : 0
        implicitHeight: 20

        function setFromX(mx) {
            if (!node || !node.audio) return;
            node.audio.volume = Math.max(0, Math.min(1, mx / bar.width));
        }

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Qt.rgba(1, 1, 1, 0.08)

            Rectangle {
                width: Math.max(0, Math.min(1, bar.vol)) * parent.width
                height: parent.height
                radius: 3
                color: (bar.node && bar.node.audio && bar.node.audio.muted)
                       ? Theme.muted : bar.tint
                Behavior on color { ColorAnimation { duration: Theme.anim } }
            }
        }
        Rectangle {
            width: 12; height: 12; radius: 6
            color: Theme.text
            visible: drag.containsMouse || drag.pressed
            x: Math.max(0, Math.min(1, bar.vol)) * bar.width - 6
            anchors.verticalCenter: parent.verticalCenter
        }
        MouseArea {
            id: drag
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            // The MouseArea is inflated 6px on each side for an easier grab,
            // so its origin sits 6px left of the bar: convert by subtracting.
            onPressed: (m) => bar.setFromX(m.x - 6)
            onPositionChanged: (m) => { if (pressed) bar.setFromX(m.x - 6); }
        }
    }

    component SectionLabel: Text {
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.letterSpacing: 1.2
        color: Theme.muted
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
            spacing: 12

            // ---- current output, with the master slider ----
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 74
                radius: Theme.radius
                color: Theme.base

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        spacing: 8
                        Text {
                            text: (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
                                   && Pipewire.defaultAudioSink.audio.muted) ? "󰝟" : "󰕾"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            color: Theme.accent
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                onClicked: {
                                    const s = Pipewire.defaultAudioSink;
                                    if (s && s.audio) s.audio.muted = !s.audio.muted;
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: pane.label(Pipewire.defaultAudioSink)
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.text
                        }
                        Text {
                            text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
                                  ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%" : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.subtext
                        }
                    }
                    VolumeBar {
                        Layout.fillWidth: true
                        node: Pipewire.defaultAudioSink
                    }
                }
            }

            // ---- output devices ----
            SectionLabel { text: "OUTPUT" }
            Repeater {
                model: pane.sinks
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isDefault: Pipewire.defaultAudioSink === modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    radius: Theme.radius
                    color: isDefault ? Theme.wash(0.20)
                         : sinkMouse.containsMouse ? Theme.wash(0.12) : Theme.base
                    Behavior on color { ColorAnimation { duration: Theme.anim } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10
                        Text {
                            text: pane.deviceIcon(modelData)
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: isDefault ? Theme.accent : Theme.subtext
                        }
                        Text {
                            Layout.fillWidth: true
                            text: pane.label(modelData)
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: isDefault ? Theme.accent : Theme.text
                        }
                        Text {
                            visible: isDefault
                            text: "󰄬"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.accent
                        }
                    }
                    MouseArea {
                        id: sinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
            }

            // ---- input device + its level ----
            SectionLabel { text: "INPUT"; visible: pane.sources.length > 0 }
            Repeater {
                model: pane.sources
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isDefault: Pipewire.defaultAudioSource === modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: isDefault ? 60 : 38
                    radius: Theme.radius
                    color: isDefault ? Theme.wash(0.20)
                         : srcMouse.containsMouse ? Theme.wash(0.12) : Theme.base
                    Behavior on color { ColorAnimation { duration: Theme.anim } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6
                        RowLayout {
                            spacing: 10
                            Text {
                                text: (modelData.audio && modelData.audio.muted) ? "󰍭" : "󰍬"
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: isDefault ? Theme.accent : Theme.subtext
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    enabled: isDefault
                                    onClicked: if (modelData.audio)
                                        modelData.audio.muted = !modelData.audio.muted
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: pane.label(modelData)
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: isDefault ? Theme.accent : Theme.text
                            }
                            Text {
                                visible: isDefault && modelData.audio
                                text: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.subtext
                            }
                        }
                        VolumeBar {
                            Layout.fillWidth: true
                            visible: isDefault
                            node: modelData
                            tint: Theme.ok
                        }
                    }
                    MouseArea {
                        id: srcMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !isDefault
                        onClicked: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }
            }

            // ---- per-application playback volume ----
            SectionLabel { text: "APPS"; visible: pane.streams.length > 0 }
            Repeater {
                model: pane.streams
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    radius: Theme.radius
                    color: Theme.base

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6
                        RowLayout {
                            spacing: 8
                            Text {
                                text: (modelData.audio && modelData.audio.muted) ? "󰝟" : "󰝚"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                color: Theme.subtext
                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    onClicked: if (modelData.audio)
                                        modelData.audio.muted = !modelData.audio.muted
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: pane.appLabel(modelData)
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.text
                            }
                            Text {
                                text: modelData.audio ? Math.round(modelData.audio.volume * 100) + "%" : ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.subtext
                            }
                        }
                        VolumeBar {
                            Layout.fillWidth: true
                            node: modelData
                            tint: Theme.subtext
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }
        }
    }
}
