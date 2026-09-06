pragma Singleton
import QtQuick
import Quickshell

// Catppuccin Mocha, kept in step with ~/.config/waybar/style.css.
// Every surface in this shell reads its colours from here so a future
// Audio or Network pane inherits the palette instead of redefining it.
Singleton {
    readonly property color crust:   "#11111b"  // panel ground
    readonly property color base:    "#1e1e2e"  // inset / row ground
    readonly property color surface: "#313244"
    readonly property color text:    "#cdd6f4"
    readonly property color subtext: "#a6adc8"
    readonly property color muted:   "#6c7086"
    readonly property color accent:  "#89b4fa"
    readonly property color danger:  "#f38ba8"
    readonly property color ok:      "#a6e3a1"
    readonly property color warn:    "#fab387"  // peach, for temperature bands

    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    readonly property int radius:      8
    readonly property int radiusLarge: 12
    readonly property int anim:      200   // matches waybar's 0.2s ease

    // Translucent accent washes, same alphas waybar uses for hover/active.
    function wash(a)   { return Qt.rgba(accent.r, accent.g, accent.b, a) }
    function danger_(a){ return Qt.rgba(danger.r, danger.g, danger.b, a) }
}
