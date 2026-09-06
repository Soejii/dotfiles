import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

// Right-edge, full-height drawer. Owns the surface, the slide, the focus
// model and the dismissal. Panes are dumb children loaded into the slot,
// so adding Audio or Network later means adding one entry to `panes`.
PanelWindow {
    id: root

    property bool shown: false
    property string pane: "power"

    // Which output to appear on. Waybar resolves the focused monitor with
    // hyprctl and passes it in, because Hyprland.monitors reports an empty
    // model in Quickshell 0.3.1 and cannot be relied on here.
    property string monitorName: ""

    // The rail hides itself while only one pane exists, so it appears on
    // its own the day a second pane lands.
    readonly property var panes: [
        { id: "network",  icon: "󰤨", label: "Network",  src: "panes/NetworkPane.qml"  },
        { id: "audio",    icon: "󰕾", label: "Audio",    src: "panes/AudioPane.qml"    },
        { id: "power",    icon: "󰐥", label: "Power",    src: "panes/PowerPane.qml"    }
    ]

    function paneSrc(id) {
        for (let i = 0; i < panes.length; i++)
            if (panes[i].id === id) return panes[i].src;
        return panes[0].src;
    }

    function openPane(name, monitor) {
        if (monitor && monitor.length > 0) root.monitorName = monitor;
        if (name && name.length > 0) root.pane = name;
        root.shown = true;
    }
    // Clicking the glyph on the monitor the drawer is already on closes it.
    // Clicking it on the other monitor moves the drawer there instead.
    function toggle(name, monitor) {
        const samePane = !name || name === root.pane;
        const sameMon  = !monitor || monitor === root.monitorName;
        if (root.shown && samePane && sameMon) root.shown = false;
        else openPane(name, monitor);
    }
    function hide() { root.shown = false; }

    screen: {
        for (const s of Quickshell.screens)
            if (s.name === root.monitorName) return s;
        return Quickshell.screens[0];
    }

    anchors { top: true; bottom: true; right: true }
    implicitWidth: 340
    exclusiveZone: 0            // overlay, never push tiled windows aside
    color: "transparent"
    focusable: root.shown       // on-demand: released the moment we close
    visible: reveal > 0.001

    // 0 = fully off-screen, 1 = fully in. Drives both slide and fade.
    property real reveal: root.shown ? 1 : 0
    Behavior on reveal {
        NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
    }

    onShownChanged: {
        if (shown) { paneLoader.item && paneLoader.item.refresh && paneLoader.item.refresh(); keys.forceActiveFocus(); }
        else if (paneLoader.item && paneLoader.item.reset) paneLoader.item.reset();
    }

    // Click anywhere outside the drawer dismisses it.
    HyprlandFocusGrab {
        windows: [root]
        active: root.shown
        onCleared: root.hide()
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.hide()
    }

    Rectangle {
        id: panel
        width: parent.width
        height: parent.height
        x: (1 - root.reveal) * width
        opacity: root.reveal
        color: Qt.rgba(Theme.crust.r, Theme.crust.g, Theme.crust.b, 0.94)

        // Matches waybar's 1px hairline, on the leading edge instead.
        Rectangle {
            width: 1; height: parent.height
            color: Qt.rgba(1, 1, 1, 0.05)
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ---- pane rail (appears once a second pane exists) ----
            ColumnLayout {
                visible: root.panes.length > 1
                Layout.fillHeight: true
                Layout.preferredWidth: 48
                Layout.topMargin: 16
                spacing: 4

                Repeater {
                    model: root.panes
                    delegate: Rectangle {
                        required property var modelData
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignHCenter
                        radius: Theme.radius
                        color: root.pane === modelData.id ? Theme.wash(0.25)
                             : railMouse.containsMouse ? Theme.wash(0.15)
                             : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.anim } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                            color: root.pane === modelData.id ? Theme.accent : Theme.muted
                        }
                        MouseArea {
                            id: railMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.pane = modelData.id
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }

            // ---- pane content ----
            Loader {
                id: paneLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: root.paneSrc(root.pane)
                onLoaded: if (root.shown && item.refresh) item.refresh()
            }
        }
    }
}
