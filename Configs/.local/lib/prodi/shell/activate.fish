#!/usr/bin/env fish

# Prevent re‑activation
if set -q PRODI_ACTIVATED
    exit 0
end

set -x PRODI_ACTIVATED 1
set -x PRODI_MODE ""
set -x HYPRLAND_CONFIG ""

# A per-user runtime directory. Falling back to a shared directory would put
# sockets from every session into one namespace, so the fallback is private and
# only readable by its owner.
function prodi_runtime_dir
    set -l uid (id -u 2>/dev/null)
    if test -n "$uid" -a -d "/run/user/$uid" -a -w "/run/user/$uid"
        echo "/run/user/$uid"
        return 0
    end
    set -l tmp $TMPDIR
    test -n "$tmp"; or set tmp /tmp
    set -l dir "$tmp/prodi-$uid"
    mkdir -p $dir 2>/dev/null; and chmod 700 $dir 2>/dev/null
    echo $dir
end

# Assignment is unconditional so a value that already exists in a non-exported
# scope still reaches child processes.
function setup_xdg
    set -gx XDG_CONFIG_HOME (test -n "$XDG_CONFIG_HOME"; and echo $XDG_CONFIG_HOME; or echo "$HOME/.config")
    set -gx XDG_CACHE_HOME (test -n "$XDG_CACHE_HOME"; and echo $XDG_CACHE_HOME; or echo "$HOME/.cache")
    set -gx XDG_DATA_HOME (test -n "$XDG_DATA_HOME"; and echo $XDG_DATA_HOME; or echo "$HOME/.local/share")
    set -gx XDG_STATE_HOME (test -n "$XDG_STATE_HOME"; and echo $XDG_STATE_HOME; or echo "$HOME/.local/state")
    set -gx XDG_RUNTIME_DIR (test -n "$XDG_RUNTIME_DIR"; and echo $XDG_RUNTIME_DIR; or prodi_runtime_dir)
end

function prodi_die
    echo $argv >&2
    return 1
end

function prodi_has
    type -q $argv[1]
end

function find_prodi_lua
    for path in \
        "$XDG_DATA_HOME/hypr/prodi.lua" \
        "/usr/local/share/hypr/prodi.lua" \
        "/usr/share/hypr/prodi.lua"
        if test -f $path
            echo $path
            return 0
        end
    end
    return 1
end


function find_hyprland_bin
    for bin in Hyprland hyprland
        if prodi_has $bin
            command -v $bin
            return 0
        end
    end
    return 1
end

function hyprland_has_lua
    if not prodi_has readelf
        return 0
    end
    set _hyprbin (find_hyprland_bin); or return 1
    if readelf -d $_hyprbin ^/dev/null | string match -q "*NEEDED*lua*"
        return 0
    end
    return 1
end

# Mirrors the resolution order in pyutils/lua_env.py, so a runtime that is good
# enough to provision the environment is not rejected here.
function prodi_find_bin
    for candidate in $argv
        test -n "$candidate"; or continue
        if prodi_has $candidate
            echo $candidate
            return 0
        end
    end
    return 1
end

function prodi_find_lua
    prodi_find_bin $LUA lua lua5.5 lua5.4 lua5.3
end

function prodi_find_luarocks
    prodi_find_bin $LUAROCKS luarocks luarocks-5.5 luarocks-5.4 luarocks-5.3
end

function check_lua_runtime
    set -l missing
    prodi_find_lua >/dev/null; or set -a missing lua
    prodi_find_luarocks >/dev/null; or set -a missing luarocks
    if test (count $missing) -gt 0
        echo "Lua runtime incomplete, missing: $missing" >&2
        return 1
    end
end

function setup_lua_mode
    set -l cfg (find_prodi_lua)
    and set -gx HYPRLAND_CONFIG $cfg
    check_lua_runtime; or return 1
    hyprland_has_lua; or begin
        echo "Hyprland lacks Lua support" >&2
        return 1
    end
    set -gx PRODI_MODE "lua"
    set -gx PRODI_FEATURE_LUA 1
end

function setup_session
    set -gx XDG_CURRENT_DESKTOP (test -n "$XDG_CURRENT_DESKTOP"; and echo $XDG_CURRENT_DESKTOP; or echo "Prodi")
    set -gx XDG_SESSION_DESKTOP (test -n "$XDG_SESSION_DESKTOP"; and echo $XDG_SESSION_DESKTOP; or echo "Prodi")
    set -gx XDG_SESSION_TYPE (test -n "$XDG_SESSION_TYPE"; and echo $XDG_SESSION_TYPE; or echo "wayland")
end

function prodi_activate
    setup_xdg
    setup_session
    if setup_lua_mode
        :
    else
        prodi_die "No valid Prodi configuration found"
        return 1
    end
end

prodi_activate
