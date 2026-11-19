# Device-Specific Features

Per-machine tweaks that are not part of the generic dotfiles. These are kept
here so they survive across reinstalls and can be reapplied with one command.

## Face unlock (howdy-next)

`face-unlock/` — HP EliteBook face unlock for `sudo`/`hyprlock`.

Applies two fixes that survive `opencv`/`howdy-next` upgrades:

1. **OpenCV soname compat symlinks** — `libopencv_*.so.500` → `.so.501`
2. **Compiled ELF wrapper** that sets `OPENCV_LOG_LEVEL=SILENT` inside the
   `pam_howdy`-spawned process (a shell-script wrapper fails privilege checks).

The wrapper is re-installed by a persistent systemd timer on boot, so the
fix holds even if the machine was off when the timer was due.

```bash
sudo bash face-unlock/setup.sh
```

See `face-unlock/README.md` for details.

## Adding a device feature

1. Create a subdirectory under `Scripts/device/`.
2. Write an idempotent `setup.sh` (use `sudo` only for privileged steps).
3. Add a `README.md` describing the device, the problem, and verification.
4. Add a pointer below.

## Supported devices

| Device | Feature | Script |
|--------|---------|--------|
| HP EliteBook (830 G7) | howdy face unlock | `face-unlock/setup.sh` |