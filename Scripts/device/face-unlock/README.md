# Face Unlock — howdy-next (HP EliteBook)

Face unlock for `sudo`/`hyprlock` via `howdy-next` on HP EliteBook laptops.

## Problem

Two issues on Arch Linux:

1. **OpenCV soname bump.** `howdy-next 3.4.2-4` links `libopencv_*.so.500`.
   Arch `opencv 5.1.0-3` ships `libopencv_*.so.501`, removing the old
   `.so.500` files. `howdy-compare` then fails with
   `libopencv_objdetect.so.500: cannot open shared object file`.

2. **ONNX warnings on every auth.** Arch's `opencv` is built with
   `WITH_ONNXRUNTIME=OFF`, so OpenCV prints a fallback warning to stderr on
   every `sudo true`. Cosmetic, but noisy.

## Fixes

### A. Soname compat symlinks

Create `.so.500` aliases pointing at the installed `.so.501` libraries:

```bash
sudo bash -c 'for lib in /usr/lib/libopencv_*.so.501; do \
  name=$(basename "$lib" .so.501); \
  ln -sf "$lib" "/usr/lib/${name}.so.500"; \
done && ldconfig'
```

### B. Silence the warnings (compiled ELF wrapper)

OpenCV honors `OPENCV_LOG_LEVEL`. `pam_howdy.so` runs `howdy-compare` via
`posix_spawn`, so the env var must be set **inside** that process. A shell
script wrapper does **not** work — `pam_howdy.so` refuses to exec a non-ELF
file with elevated privileges:

```
Failed to inspect Config file: /etc/howdy/config.ini (Permission denied);
process uid=1000 euid=1000 cannot inspect the restricted Howdy config path.
```

The solution is a tiny compiled ELF (`wrap.c`) that sets the env var and
execs the real binary:

```c
#include <unistd.h>
#include <stdlib.h>
int main(int argc, char **argv) {
    setenv("OPENCV_LOG_LEVEL", "SILENT", 1);
    (void)argc;
    execv("/usr/lib/howdy/howdy-compare.real", argv);
    return 127;
}
```

Install:

```bash
sudo bash Scripts/device/face-unlock/setup.sh
```

Result:

| Path | Purpose |
|------|---------|
| `/usr/lib/howdy/howdy-compare` | active wrapper (replaces package binary) |
| `/usr/lib/howdy/howdy-compare.real` | original howdy-next binary backup |
| `/usr/local/lib/howdy-nosuppress/howdy-compare` | compiled wrapper |
| `/usr/lib/libopencv_*.so.500` | compat symlinks → `.so.501` |
| `/usr/local/bin/howdy-fix.sh` | idempotent re-apply script |
| `howdy-fix.service` + `howdy-fix.timer` | persistent systemd timer |

## Persistence

An `opencv` or `howdy-next` update can remove the `.so.500` symlinks and/or
overwrite the wrapper. The systemd timer (`Persistent=true`, `OnBootSec=2min`,
`OnCalendar=daily`) re-applies the fix on the next boot even if the machine
was off at the scheduled time — this is why a plain cron job was rejected
(`cronie` does not replay missed runs).

```bash
sudo systemctl enable --now howdy-fix.timer
sudo systemctl status howdy-fix.timer
sudo /usr/local/bin/howdy-fix.sh
```

## Verify

```bash
sudo true                      # should print "Face matched user prodi9al",
                               # and no OpenCV warnings
cmp -s /usr/lib/howdy/howdy-compare \
        /usr/local/lib/howdy-nosuppress/howdy-compare && echo "wrapper active"
```

## Supported models

- **HP EliteBook** (tested: 830 G7). Intel UHD Graphics, internal webcam
  at `/dev/video0`.
- Other models: adjust `/dev/video*` in `/etc/howdy/config.ini` and the
  OpenCV symlinks as needed.

## Notes / caveats

- The ONNX fallback warning is harmless; the wrapper only removes terminal
  noise.
- A true fix (no wrapper) would require rebuilding `opencv` with
  `-DWITH_ONNXRUNTIME=ON` (~3.3 GB CUDA build deps, 20–40 min). Not worth
  it for a cosmetic warning.
- Do NOT make `/etc/howdy` or `config.ini` world-readable — that is a
  security downgrade.