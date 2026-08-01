-- Hyprland config (Lua, native format for 0.55+). LAPTOP variant.
-- Adapted from the desktop branch's hyprland.lua for this machine's single
-- internal panel (eDP-1, 1920x1080@60). Dropped vs desktop: dual-monitor
-- config (DP-1 + HDMI-A-1) and per-monitor workspace pinning, PC-only game
-- window-rules, the gamepad-idle-inhibit autostart, and the Alt+Tab win-cycle
-- bind (script not present on this machine). Added: hyprsunset (blue-light).
-- The old hyprlang config is kept as hyprland.conf.pre-lua-bak as a fallback.
-- Wiki: https://wiki.hypr.land/Configuring/Start/

------------------
---- MONITORS ----
------------------
-- Single internal panel. Catch-all covers any external output if plugged in.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0",  scale = 1 })
hl.monitor({ output = "",      mode = "preferred", position = "auto", scale = 1 })

---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "alacritty"
local fileManager = "thunar"
local menu        = "wofi --show drun"
local browser     = "firefox"

-------------------
---- AUTOSTART ----
-------------------
-- exec-once equivalents: run once on Hyprland start (not on reload).
hl.on("hyprland.start", function()
    hl.exec_cmd("/home/suji/.local/bin/start-hyprpaper")
    hl.exec_cmd(browser)
    hl.exec_cmd("waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets,ssh")
    hl.exec_cmd(terminal)
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("hypridle")   -- run directly (this machine has no hypridle user service active)
    hl.exec_cmd("hyprsunset") -- blue-light filter (laptop-specific)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("dunst")
    hl.exec_cmd("/home/suji/.local/bin/hypr-compact-workspaces")
    hl.exec_cmd("systemd-cat -t video-idle-inhibit /home/suji/.local/bin/video-idle-inhibit")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GTK_THEME", "Catppuccin-Blue-Dark")

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 15,

        border_size = 2,

        col = {
            active_border   = "rgba(89b4faee)",
            inactive_border = "rgba(31324400)",
        },

        resize_on_border = true,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a, -- rgba(1a1a1aee)
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        -- 0.55 renamed new_window_takes_over_fullscreen -> on_focus_under_fullscreen
        -- and flipped the default to 2 (exit_fullscreen). 0 = ignore: keep the
        -- fullscreen window fullscreen when a new/tiled window grabs focus.
        on_focus_under_fullscreen = 0,
    },

    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },

    xwayland = {
        force_zero_scaling = true,
    },

    cursor = {
        -- Without this, keyboard-driven focus changes warp the mouse cursor to
        -- the center of the newly focused window.
        no_warps = true,
    },
})

-- Animation curves + timings (migrated 1:1 from the old bezier/animation lines).
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1} } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

---------------
---- INPUT ----
---------------
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Leftover example per-device config (kept as-is from the old config).
hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("/home/suji/.local/bin/hypr-cheatsheet"))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd([[cliphist list | wofi --dmenu --width=1200 --height=600 --prompt="Clipboard" | cliphist decode | wl-copy]]))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("alacritty --class sysmon -e btop"))
hl.bind(mainMod .. " + W", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit()) -- quit Hyprland
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("/home/suji/.local/bin/hyprsunset-toggle")) -- blue-light toggle
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

-- Mod+O: workspace overview (wofi picker)
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("/home/suji/.local/bin/ws-overview"))

-- Scratchpad (special workspace "magic")
hl.bind(mainMod .. " + S",             hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:magic" }))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "d" }))

-- Move active window with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))

-- Resize active window with mainMod + CTRL + arrow keys (40px steps)
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40,  y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })

-- Switch (Mod+1-0) and move (Mod+Shift+1-0) workspaces, via single-monitor scripts.
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.exec_cmd("/home/suji/.local/bin/ws-switch " .. i))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("/home/suji/.local/bin/ws-move " .. i))
end

-- Scroll through existing workspaces with mainMod + scroll (via ws-cycle).
hl.bind(mainMod .. " + mouse_down", hl.dsp.exec_cmd("/home/suji/.local/bin/ws-cycle next"))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.exec_cmd("/home/suji/.local/bin/ws-cycle prev"))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"))
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("pactl set-source-mute @DEFAULT_SOURCE@ toggle"))

-- LCD brightness (locked + repeating)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Media keys (locked). Requires playerctl.
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshots (save + copy + notify)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("/home/suji/.local/bin/screenshot area"))
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.exec_cmd("/home/suji/.local/bin/screenshot screen"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Force true fullscreen for Slay the Spire (XWayland doesn't signal it properly).
hl.window_rule({ name = "slaytheSpire-fs", match = { class = "^(Slay the Spire)$" }, fullscreen = true })

-- Android Emulator: floating + centered (relevant for Flutter dev on this machine).
hl.window_rule({ name = "emulator", match = { class = "^(Emulator)$" }, float = true, center = true })

-- Super+I cheatsheet: float, centered, sized.
hl.window_rule({ name = "cheatsheet", match = { class = "^(hypr-cheatsheet)$" }, float = true, center = true, size = {600, 500} })

-- btop task manager popup (Super+Escape): float, centered, roomy.
hl.window_rule({ name = "sysmon", match = { class = "^(sysmon)$" }, float = true, center = true, size = {1200, 800} })
