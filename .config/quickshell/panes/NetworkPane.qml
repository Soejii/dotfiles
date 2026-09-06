import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import ".."

Item {
    id: pane

    // Scanning costs power and airtime, so it runs only while this pane is on
    // screen. This has to be a binding rather than a direct assignment in
    // refresh(): Networking.devices populates asynchronously and is still
    // empty the first time the drawer opens, so an imperative set is a no-op
    // and the list silently falls back to NetworkManager's stale scan cache.
    Binding {
        target: pane.wifiDev
        property: "scannerEnabled"
        value: pane.scanning
        when: pane.wifiDev !== null
    }

    function refresh() { pane.scanning = true; }
    function reset()   {
        pane.scanning = false;
        pane.pskFor = null; pane.psk = ""; pane.failReason = "";
    }
    Component.onDestruction: if (wifiDev) wifiDev.scannerEnabled = false

    property bool scanning: false
    property var pskFor: null      // network awaiting a password
    property string psk: ""
    property string failReason: ""

    readonly property var wifiDev: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi) return d;
        return null;
    }
    readonly property var wiredDev: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wired) return d;
        return null;
    }
    readonly property var activeWifi: {
        if (!wifiDev) return null;
        for (const n of wifiDev.networks.values) if (n.connected) return n;
        return null;
    }
    // Everything except the one we are already on, strongest first.
    readonly property var scanned: {
        if (!wifiDev) return [];
        return wifiDev.networks.values
            .filter(n => !n.connected)
            .sort((a, b) => b.signalStrength - a.signalStrength);
    }

    function wifiIcon(s) {
        if (s >= 0.75) return "󰤨";
        if (s >= 0.50) return "󰤥";
        if (s >= 0.25) return "󰤢";
        if (s > 0)     return "󰤟";
        return "󰤯";
    }
    function isOpen(n) { return n.security === WifiSecurityType.Open
                             || n.security === WifiSecurityType.Unknown }

    function join(n) {
        pane.failReason = "";
        if (n.known || pane.isOpen(n)) { n.connect(); return; }
        pane.pskFor = n; pane.psk = "";
    }
    function submitPsk() {
        if (!pane.pskFor) return;
        const n = pane.pskFor;
        // Read the secret before clearing pskFor: that flips the row out of its
        // awaiting state, which wipes the TextInput and with it pane.psk.
        const secret = pane.psk;
        pane.pskFor = null;
        n.connectWithPsk(secret);
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

            // ---------------- wired ----------------
            SectionLabel { text: "WIRED"; visible: pane.wiredDev !== null }
            Rectangle {
                visible: pane.wiredDev !== null
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: Theme.radius
                color: Theme.base

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    Text {
                        text: (pane.wiredDev && pane.wiredDev.connected) ? "󰈁" : "󰈂"
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: (pane.wiredDev && pane.wiredDev.connected) ? Theme.ok : Theme.muted
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: pane.wiredDev ? pane.wiredDev.name : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.text
                        }
                        Text {
                            text: {
                                if (!pane.wiredDev) return "";
                                if (!pane.wiredDev.hasLink) return "no cable";
                                const sp = pane.wiredDev.linkSpeed;
                                return ConnectionState.toString(pane.wiredDev.state)
                                     + (sp ? "  ·  " + sp + " Mb/s" : "");
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.muted
                        }
                    }
                }
            }

            // ---------------- wifi ----------------
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                SectionLabel { text: "WI-FI"; Layout.fillWidth: true }
                // enable / disable radio
                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 18
                    radius: 9
                    color: Networking.wifiEnabled ? Theme.wash(0.55) : Qt.rgba(1, 1, 1, 0.10)
                    Behavior on color { ColorAnimation { duration: Theme.anim } }
                    opacity: Networking.wifiHardwareEnabled ? 1 : 0.4

                    Rectangle {
                        width: 14; height: 14; radius: 7
                        y: 2
                        x: Networking.wifiEnabled ? parent.width - 16 : 2
                        color: Networking.wifiEnabled ? Theme.accent : Theme.muted
                        Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: Networking.wifiHardwareEnabled
                        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

            // connected network, with disconnect
            Rectangle {
                visible: pane.activeWifi !== null
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                radius: Theme.radius
                color: Theme.wash(0.20)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    Text {
                        text: pane.activeWifi ? pane.wifiIcon(pane.activeWifi.signalStrength) : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                        color: Theme.accent
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: pane.activeWifi ? pane.activeWifi.name : ""
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.accent
                        }
                        Text {
                            text: pane.activeWifi
                                ? (pane.activeWifi.stateChanging
                                    ? ConnectionState.toString(pane.activeWifi.state) + "…"
                                    : Math.round(pane.activeWifi.signalStrength * 100) + "%  ·  "
                                      + WifiSecurityType.toString(pane.activeWifi.security))
                                : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.muted
                        }
                    }
                    Text {
                        text: "󰅖"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: dcMouse.containsMouse ? Theme.danger : Theme.muted
                        MouseArea {
                            id: dcMouse
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            onClicked: if (pane.activeWifi) pane.activeWifi.disconnect()
                        }
                    }
                }
            }

            Text {
                visible: pane.failReason.length > 0
                Layout.fillWidth: true
                text: pane.failReason
                wrapMode: Text.Wrap
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: Theme.danger
            }

            // available networks
            RowLayout {
                Layout.fillWidth: true
                visible: Networking.wifiEnabled
                SectionLabel { Layout.fillWidth: true; text: "NETWORKS" }
                Text {
                    visible: pane.scanned.length === 0
                    text: "scanning…"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.muted
                }
            }

            Repeater {
                model: Networking.wifiEnabled ? pane.scanned : []
                delegate: Rectangle {
                    id: netRow
                    required property var modelData
                    readonly property bool awaiting: pane.pskFor === modelData
                    onAwaitingChanged: if (!awaiting) pskInput.text = ""

                    Layout.fillWidth: true
                    Layout.preferredHeight: awaiting ? 78 : 40
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: Theme.anim } }
                    radius: Theme.radius
                    color: awaiting ? Theme.wash(0.14)
                         : netMouse.containsMouse ? Theme.wash(0.12) : Theme.base
                    Behavior on color { ColorAnimation { duration: Theme.anim } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Text {
                                text: pane.wifiIcon(netRow.modelData.signalStrength)
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                color: Theme.subtext
                            }
                            Text {
                                Layout.fillWidth: true
                                text: netRow.modelData.name || "<hidden>"
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: netRow.modelData.stateChanging ? Theme.accent : Theme.text
                            }
                            Text {
                                visible: netRow.modelData.known
                                text: "saved"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: Theme.ok
                            }
                            Text {
                                visible: !pane.isOpen(netRow.modelData)
                                text: "󰌾"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.muted
                            }
                        }

                        // password entry, only for an unknown secured network
                        RowLayout {
                            visible: netRow.awaiting
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                radius: 6
                                color: Theme.crust
                                border.width: 1
                                border.color: pskInput.activeFocus ? Theme.accent : "transparent"

                                TextInput {
                                    id: pskInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: TextInput.Password
                                    focus: netRow.awaiting
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    color: Theme.text
                                    selectionColor: Theme.wash(0.4)
                                    onTextChanged: pane.psk = text
                                    onAccepted: pane.submitPsk()
                                    Keys.onEscapePressed: { pane.pskFor = null; pane.psk = ""; }

                                    Text {
                                        visible: pskInput.text.length === 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "password"
                                        font: pskInput.font
                                        color: Theme.muted
                                    }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 54
                                Layout.preferredHeight: 28
                                radius: 6
                                color: joinMouse.containsMouse ? Theme.wash(0.35) : Theme.wash(0.20)
                                Text {
                                    anchors.centerIn: parent
                                    text: "Join"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.accent
                                }
                                MouseArea {
                                    id: joinMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: pane.submitPsk()
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !netRow.awaiting
                        onClicked: pane.join(netRow.modelData)
                    }

                    Connections {
                        target: netRow.modelData
                        function onConnectionFailed(reason) {
                            pane.failReason = (netRow.modelData.name || "network") + ": "
                                + ConnectionFailReason.toString(reason);
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }
        }
    }
}
