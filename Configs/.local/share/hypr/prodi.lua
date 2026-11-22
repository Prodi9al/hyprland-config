--!      ░▒▒▒░░░▓▓           ___________
--!    ░░▒▒▒░░░░░▓▓        //___________/
--!   ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
--!   ░░▒▒░░░░░▓▓▓▓▓▓ | | | | |  | |  __/
--!    ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
--!     ░▒▒░░▓▓   ▓▓   \__  |____/ |____/
--!       ░▒▓▓   ▓▓  //____/

-- // ██████╗░░█████╗░  ███╗░░██╗░█████╗░████████╗  ███████╗██████╗░██╗████████╗
-- // ██╔══██╗██╔══██╗  ████╗░██║██╔══██╗╚══██╔══╝  ██╔════╝██╔══██╗██║╚══██╔══╝
-- // ██║░░██║██║░░██║  ██╔██╗██║██║░░██║░░░██║░░░  █████╗░░██║░░██║██║░░░██║░░░
-- // ██║░░██║██║░░██║  ██║╚████║██║░░██║░░░██║░░░  ██╔══╝░░██║░░██║██║░░░██║░░░
-- // ██████╔╝╚█████╔╝  ██║░╚███║╚█████╔╝░░░██║░░░  ███████╗██████╔╝██║░░░██║░░░
-- // ╚═════╝░░╚════╝░  ╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░  ╚══════╝╚═════╝░╚═╝░░░╚═╝░░░

-- require() resolves against the directory of the config Hyprland was started
-- with, which since v26.8.1 is the user's hyprland.lua, not this file. The
-- resolver is therefore loaded by its own path; everything below loads by name
-- from the search path it sets.
local root = assert(debug.getinfo(1, "S").source:match("^@(.*)/"), "not loaded from a file")

---@module "prodi"
prodi = prodi or {}
---@diagnostic disable-next-line: inject-field
prodi.path = dofile(root .. "/lua/prodi/path.lua")
package.loaded["prodi.path"] = prodi.path

local pkg_paths = {
	prodi.path.state .. "/prodi/?.lua", -- Lua state
	prodi.path.lib .. "/prodi/?.lua", -- lib scripts
	prodi.path.lib .. "/prodi/luautils/?.lua", -- lib scripts
	prodi.path.share .. "/hypr/lua/?.lua",
	prodi.path.state .. "/prodi/lua_env/share/lua/5.5/?.lua", -- virtual env for lua
	prodi.path.state .. "/prodi/lua_env/share/lua/5.5/?/init.lua", -- virtual env for lua
	prodi.path.config .. "/hypr/?.lua", -- expose main users config
	root .. "/lua/?.lua" -- this file's own tree, whatever prefix it sits under
}

package.path = package.path .. ";" .. table.concat(pkg_paths, ";") .. ";"
package.cpath = package.cpath
	.. ";"
	.. prodi.path.state
	.. "/prodi/lua_env/lib/lua/5.5/?.so" -- virtual env shared objects

-- Let's call it early so we can use it in other files
local utils = require("prodi.utils")
require("prodi.env")
require("prodi.config")
require("prodi.binds")
require("prodi.dispatcher")
require("prodi.handlers")

local check_require = utils.check_require

-- * Variables
require("variables")
-- * Default values
require("defaults")
--* Window rules
require("window_rules")
--* Layer rules
require("layer_rules")
-- * Environment variable Setup
require("env")
-- * Binds
require("key_binds")
--* Dynamic Stuff example theming and variable handlings
require("dynamic")
-- * Event handlers for more DE like experience
require("events")
--* Prodi's startup overridable too!
require("start_up")
-- * Automatically load generated monitor configs (e.g., from nwg-displays)
check_require("monitors")
-- * Load default layout (dwindle) and its gestures/keybindings
require("layouts.dwindle")
-- --* user now can have this file
check_require("hyprland")
-- --* workflows configuration overrides everything
check_require("lua_state.workflows")
