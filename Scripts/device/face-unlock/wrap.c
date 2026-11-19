#include <unistd.h>
#include <stdlib.h>

/* howdy-nosuppress wrapper.
 *
 * howdy-next's howdy-compare is dynamically linked against OpenCV, which
 * prints ONNX fallback warnings to stderr on every auth attempt. pam_howdy
 * runs this binary via posix_spawn, so the env var must be set *inside* the
 * process. A shell-script wrapper does NOT work: pam_howdy refuses to exec a
 * non-ELF file with elevated privileges.
 *
 * This compiled ELF sets OPENCV_LOG_LEVEL=SILENT and execs the real binary.
 */
int main(int argc, char **argv) {
    setenv("OPENCV_LOG_LEVEL", "SILENT", 1);
    (void)argc;
    execv("/usr/lib/howdy/howdy-compare.real", argv);
    return 127;
}