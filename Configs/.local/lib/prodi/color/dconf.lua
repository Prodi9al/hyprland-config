#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "../?.lua;" .. root .. "../?/init.lua;"
require("luautils.init")

local xdg = require("luautils.xdg")
local has_lgi, lgi = pcall(require, "lgi")
local Gio = has_lgi and lgi.Gio or nil

local function _s(v)
    if v == nil or v == "" then return nil end
    return tostring(v)
end

local function _f(font, size)
    local f = _s(font)
    if not f then return nil end
    local s = _s(size)
    if not s then return f end
    return f .. " " .. s
end

local lua_u = {}
local ok, ui = pcall(dofile, xdg.state .. "/prodi/lua_state/ui.lua")
if ok and ui then lua_u = ui.ui end

local function _r(key)
    return _s(lua_u[key])
        or _s(os.getenv("__" .. key:upper()))
        or _s(os.getenv(key:upper()))
end

local GTK_THEME         = _r("gtk_theme")         or "Wallbash-Gtk"
local ICON_THEME        = _r("icon_theme")
local COLOR_SCHEME      = _r("color_scheme")       or "prefer-dark"
local CURSOR_THEME      = _r("cursor_theme")
local CURSOR_SIZE       = tonumber(_r("cursor_size")) or 24
local FONT_NAME         = _f(_r("font"), _r("font_size"))
local DOC_FONT_NAME     = _f(_r("document_font"), _r("document_font_size"))
local MONO_FONT_NAME    = _f(_r("monospace_font"), _r("monospace_font_size"))
local FONT_ANTIALIASING = _r("font_antialiasing")  or "rgba"
local FONT_HINTING      = _r("font_hinting")       or "slight"
local BUTTON_LAYOUT     = _r("button_layout")      or ""
local TERMINAL          = _r("terminal")            or "kitty"

-- TERMINAL comes from the user's own config (prodi.config.ui.terminal), so a
-- quote in it must not break the probe or reach the shell unescaped (#1901).
local function shell_quote(arg)
    arg = tostring(arg)
    arg = arg:gsub("'", "'\\''")
    return "'" .. arg .. "'"
end

if Gio then
    local iface = Gio.Settings.new("org.gnome.desktop.interface")
    if GTK_THEME         then iface:set_string("gtk-theme",           GTK_THEME)         end
    if ICON_THEME        then iface:set_string("icon-theme",          ICON_THEME)        end
    if COLOR_SCHEME      then iface:set_string("color-scheme",        COLOR_SCHEME)      end
    if CURSOR_THEME      then iface:set_string("cursor-theme",        CURSOR_THEME)      end
    iface:set_int("cursor-size", CURSOR_SIZE)
    if FONT_NAME         then iface:set_string("font-name",           FONT_NAME)         end
    if DOC_FONT_NAME     then iface:set_string("document-font-name",  DOC_FONT_NAME)     end
    if MONO_FONT_NAME    then iface:set_string("monospace-font-name", MONO_FONT_NAME)    end
    if FONT_ANTIALIASING then iface:set_string("font-antialiasing",   FONT_ANTIALIASING) end
    if FONT_HINTING      then iface:set_string("font-hinting",        FONT_HINTING)      end
    Gio.Settings.sync()

    local wm = Gio.Settings.new("org.gnome.desktop.wm.preferences")
    if BUTTON_LAYOUT then wm:set_string("button-layout", BUTTON_LAYOUT) end
    Gio.Settings.sync()

    local ok_term, term = pcall(Gio.Settings.new, "org.gnome.desktop.default-applications.terminal")
    if ok_term and term then
        local handle = io.popen("command -v " .. shell_quote(TERMINAL) .. " 2>/dev/null")
        local bin = handle and handle:read("*l") or TERMINAL
        if handle then handle:close() end
        if bin and bin ~= "" then
            term:set_string("exec", bin)
            Gio.Settings.sync()
        end
    end
else
    -- Fallback to gsettings CLI if lgi is unavailable or incompatible with lua version
    local function gset(schema, key, val, is_int)
        if not val then return end
        local cmd
        if is_int then
            cmd = string.format("gsettings set %s %s %d 2>/dev/null", schema, key, val)
        else
            cmd = string.format("gsettings set %s %s %s 2>/dev/null", schema, key, shell_quote(val))
        end
        os.execute(cmd)
    end
    gset("org.gnome.desktop.interface", "gtk-theme", GTK_THEME)
    gset("org.gnome.desktop.interface", "icon-theme", ICON_THEME)
    gset("org.gnome.desktop.interface", "color-scheme", COLOR_SCHEME)
    gset("org.gnome.desktop.interface", "cursor-theme", CURSOR_THEME)
    gset("org.gnome.desktop.interface", "cursor-size", CURSOR_SIZE, true)
    gset("org.gnome.desktop.interface", "font-name", FONT_NAME)
    gset("org.gnome.desktop.interface", "document-font-name", DOC_FONT_NAME)
    gset("org.gnome.desktop.interface", "monospace-font-name", MONO_FONT_NAME)
    gset("org.gnome.desktop.interface", "font-antialiasing", FONT_ANTIALIASING)
    gset("org.gnome.desktop.interface", "font-hinting", FONT_HINTING)
    if BUTTON_LAYOUT ~= "" then
        gset("org.gnome.desktop.wm.preferences", "button-layout", BUTTON_LAYOUT)
    end
    local handle = io.popen("command -v " .. shell_quote(TERMINAL) .. " 2>/dev/null")
    local bin = handle and handle:read("*l") or TERMINAL
    if handle then handle:close() end
    if bin and bin ~= "" then
        gset("org.gnome.desktop.default-applications.terminal", "exec", bin)
    end
end

if os.getenv("HYPRLAND_INSTANCE_SIGNATURE") and CURSOR_THEME then
    os.execute(string.format("hyprctl setcursor %s %d", shell_quote(CURSOR_THEME), CURSOR_SIZE))
end
