-- luautils/init.lua
-- Initializes Lua module search paths for Prodi using XDG base directories.
local xdg = require("luautils.xdg")

local XDG_DATA_HOME = xdg.data
local XDG_STATE_HOME = xdg.state
local XDG_CONFIG_HOME = xdg.config

local PRODI_STATE_HOME = os.getenv("PRODI_STATE_HOME") or (XDG_STATE_HOME .. "/prodi")
local PRODI_CONFIG_HOME = os.getenv("PRODI_CONFIG_HOME") or (XDG_CONFIG_HOME .. "/prodi")

local PRODI_SCRIPTS_PATH = os.getenv("PRODI_SCRIPTS_PATH")
if not PRODI_SCRIPTS_PATH then
    local src = debug.getinfo(1, "S").source
    if src and src:sub(1, 1) == "@" then
        local luautils_dir = src:sub(2):match("(.*/luautils)/")
        if luautils_dir then
            PRODI_SCRIPTS_PATH = luautils_dir:gsub("/luautils/$?", "")
        end
    end
end
PRODI_SCRIPTS_PATH = PRODI_SCRIPTS_PATH or (XDG_DATA_HOME .. "/prodi")
local lua_version = _VERSION:match("%d+%.%d+")

local pkg_paths = {
    PRODI_STATE_HOME .. "/?.lua",
    PRODI_SCRIPTS_PATH .. "/?.lua",
    PRODI_SCRIPTS_PATH .. "/luautils/?.lua",
    XDG_DATA_HOME .. "/hypr/lua/?.lua",
    PRODI_CONFIG_HOME .. "/hypr/?.lua",
    PRODI_STATE_HOME .. "/lua_env/share/lua/" .. lua_version .. "/?.lua",
    PRODI_STATE_HOME .. "/lua_env/share/lua/" .. lua_version .. "/?/init.lua"
}
for _, d in ipairs(xdg.dirs.config) do
    if d and d ~= "" then
        table.insert(pkg_paths, d .. "/prodi/?.lua")
        table.insert(pkg_paths, d .. "/prodi/?/init.lua")
    end
end
package.path = package.path .. ";" .. table.concat(pkg_paths, ";") .. ";"
package.cpath =
    package.cpath ..
    ";" ..
        PRODI_STATE_HOME ..
            "/lua_env/lib/lua/" ..
                lua_version .. "/?.so;" .. PRODI_STATE_HOME .. "/lua_env/lib/lua/" .. lua_version .. "/?/init.so;"
