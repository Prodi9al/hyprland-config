#!/bin/bash
# howdy-nosuppress: keeps howdy-next working after opencv updates
# 1. Recreates missing libopencv_*.so.500 compat symlinks from .so.501
# 2. Re-installs the OPENCV_LOG_LEVEL wrapper around howdy-compare
# Safe to run repeatedly.

set -u

COMPARE=/usr/lib/howdy/howdy-compare
REAL=/usr/lib/howdy/howdy-compare.real
WRAP_BIN=/usr/local/lib/howdy-nosuppress/howdy-compare

# --- 1. OpenCV soname compat symlinks ---
for lib in /usr/lib/libopencv_*.so.501; do
  [ -e "$lib" ] || continue
  name=$(basename "$lib" .so.501)
  [ ! -e "/usr/lib/${name}.so.500" ] && ln -sf "$lib" "/usr/lib/${name}.so.500"
done

ldconfig

# --- 2. Re-install wrapper if an upgrade replaced it ---
# The wrapper is a small ELF; if COMPARE is not our wrapper (e.g. pacman
# updated howdy-next), re-apply it. We detect "not our wrapper" by checking
# whether REAL exists and COMPARE differs from our stored wrapper binary.
if [ -x "$WRAP_BIN" ]; then
  if [ ! -e "$REAL" ]; then
    # No backup yet: the current COMPARE is the original package binary
    cp -a "$COMPARE" "$REAL"
  elif ! cmp -s "$COMPARE" "$WRAP_BIN"; then
    # COMPARE is not our wrapper (upgrade restored original); ensure REAL
    # holds the current original, then re-install wrapper
    if ! cmp -s "$COMPARE" "$REAL"; then
      cp -a "$COMPARE" "$REAL"
    fi
  fi
  # (Re)install wrapper only if COMPARE isn't already identical to it
  if ! cmp -s "$COMPARE" "$WRAP_BIN"; then
    cp -a "$WRAP_BIN" "$COMPARE"
    chown root:root "$COMPARE"
    chmod 755 "$COMPARE"
  fi
fi

exit 0