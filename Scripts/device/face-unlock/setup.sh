#!/usr/bin/env bash
# Prodi9al Hyprland Config — Device Features: howdy face unlock
# Installs the OpenCV soname compat symlinks + OPENCV_LOG_LEVEL wrapper so
# howdy-next face unlock stays working (and quiet) after opencv updates.
#
# Idempotent: safe to re-run. Requires sudo for the privileged parts.
#
# Supported models: HP EliteBook (tested on 830 G7). Other laptops may need
# different webcam/video devices — see README.md.

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPTS_DIR/face-unlock"

COMPARE=/usr/lib/howdy/howdy-compare
REAL=/usr/lib/howdy/howdy-compare.real
WRAP_SRC="$SRC/wrap.c"
WRAP_BIN=/usr/local/lib/howdy-nosuppress/howdy-compare
FIX_SCRIPT=/usr/local/bin/howdy-fix.sh
SERVICE=/etc/systemd/system/howdy-fix.service
TIMER=/etc/systemd/system/howdy-fix.timer

if [ ! -x "$COMPARE" ]; then
  echo "==> howdy-next not installed (no $COMPARE). Skipping face-unlock setup."
  echo "    Install it first:  sudo pacman -S howdy-next"
  exit 0
fi

echo "==> Setting up howdy face unlock"

# 1. Compile the ELF wrapper
echo "    [1/5] compiling wrapper"
mkdir -p "$(dirname "$WRAP_BIN")"
gcc -O2 -o "$WRAP_BIN" "$WRAP_SRC"
chown root:root "$WRAP_BIN"
chmod 755 "$WRAP_BIN"

# 2. Back up the original howdy-next binary (only if not already)
if [ ! -e "$REAL" ]; then
  sudo cp -a "$COMPARE" "$REAL"
  sudo chown root:root "$REAL"
  sudo chmod 755 "$REAL"
fi

# 3. Install maintenance script + systemd units
echo "    [2/5] installing maintenance script"
sudo cp "$SRC/howdy-fix.sh" "$FIX_SCRIPT"
sudo chown root:root "$FIX_SCRIPT"
sudo chmod 755 "$FIX_SCRIPT"

echo "    [3/5] installing systemd service + timer"
sudo cp "$SRC/howdy-fix.service" "$SERVICE"
sudo cp "$SRC/howdy-fix.timer" "$TIMER"
sudo systemctl daemon-reload
sudo systemctl enable --now howdy-fix.timer

# 4. Apply the fix right now (idempotent)
echo "    [4/5] applying fix"
sudo "$FIX_SCRIPT"

# 5. Verify
echo "    [5/5] verifying"
if cmp -s "$COMPARE" "$WRAP_BIN"; then
  echo "       wrapper active on $COMPARE"
else
  echo "       WARNING: wrapper not active on $COMPARE" >&2
  exit 1
fi

echo ""
echo "==> Face unlock ready. Verify with:  sudo true"
echo "    Maintenance:  sudo /usr/local/bin/howdy-fix.sh"
echo "    Logs:         journalctl -u howdy-fix.service"