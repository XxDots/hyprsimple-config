-- Your application keybinds. hyprsimple copies this file once and never
-- touches it again, so anything you bind here stays bound, and a binding
-- hyprsimple adds later will not appear here on its own.
--
-- Names looked up through the vars table come from your own overrides file in
-- ~/.config/hypr/, falling back to hyprsimple's defaults. One that hyprsimple
-- does not set answers with a notification saying so, rather than taking the
-- rest of this file down with it.

local vars = require("default.hypr.vars")
local home = os.getenv("HOME")

-- Scratchpad toggle (replaces SUPER+S Sound panel)
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle Scratchpad" })

-- Move focused window to Scratchpad (uses special:magic)
hl.bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { description = "Move to Scratchpad" })

-- Fullscreen toggle
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ action = "toggle" }), { description = "Fullscreen" })

-- File Manager (new binding)
hl.bind("SUPER + E", hl.dsp.exec_cmd(vars.fileManager), { description = "File Manager" })

-- Theme Switcher
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd(home .. "/.local/bin/theme-switcher.sh"),                 { description = "Theme Switcher" })
-- Wallpaper Picker
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd(home .. "/.local/bin/wallpaper-switcher.sh pick"),        { description = "Wallpaper Picker" })

-- Terminal
hl.bind("SUPER + T", hl.dsp.exec_cmd(vars.terminal),    { description = "Terminal" })
-- Browser
hl.bind("SUPER + B", hl.dsp.exec_cmd(vars.browser),     { description = "Browser" })
-- App Launcher
hl.bind("SUPER + A", hl.dsp.exec_cmd(vars.menu),        { description = "App Launcher" })

-- Clipboard Manager
hl.bind("SUPER + V", hl.dsp.exec_cmd(home .. "/.local/bin/hyprsimple-clipboard-menu.sh"),  { description = "Clipboard Manager" })
-- Color Picker
hl.bind("SUPER + M", hl.dsp.exec_cmd("sh -c '" .. vars.colorPicker .. " | wl-copy'"),                           { description = "Color Picker" })