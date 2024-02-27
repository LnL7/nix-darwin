#define _GNU_SOURCE
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdnoreturn.h>
#include <sys/errno.h>
// #include <sys/types.h>
// #include <sys/stat.h>
// #include <sys/xattr.h>
// #include <fcntl.h>
// #include <dirent.h>
// #include <errno.h>
// #include <sys/prctl.h>
// #include <limits.h>
// #include <stdint.h>
// #include <syscall.h>
// #include <byteswap.h>

// imported from glibc
// #include "unsecvars.h"

#ifndef SOURCE_PROG
#error SOURCE_PROG should be defined via preprocessor commandline
#endif

// aborts when false, printing the failed expression
#define ASSERT(expr) ((expr) ? (void) 0 : assert_failure(#expr))

extern char **environ;

// Wrapper debug variable name
static char *wrapper_debug = "WRAPPER_DEBUG";

static noreturn void assert_failure(const char *assertion) {
    fprintf(stderr, "Assertion `%s` in NixOS's wrapper.c failed.\n", assertion);
    fflush(stderr);
    abort();
}

// These are environment variable aliases for glibc tunables.
// This list shouldn't grow further, since this is a legacy mechanism.
// Any future tunables are expected to only be accessible through GLIBC_TUNABLES.
//
// They are not included in the glibc-provided UNSECURE_ENVVARS list,
// since any SUID executable ignores them. This wrapper also serves
// executables that are merely granted ambient capabilities, rather than
// being SUID, and hence don't run in secure mode. We'd like them to
// defend those in depth as well, so we clear these explicitly.
//
// Except for MALLOC_CHECK_ (which is marked SXID_ERASE), these are all
// marked SXID_IGNORE (ignored in secure mode), so even the glibc version
// of this wrapper would leave them intact.
#define UNSECURE_ENVVARS_TUNABLES \
    "MALLOC_CHECK_\0" \
    "MALLOC_TOP_PAD_\0" \
    "MALLOC_PERTURB_\0" \
    "MALLOC_MMAP_THRESHOLD_\0" \
    "MALLOC_TRIM_THRESHOLD_\0" \
    "MALLOC_MMAP_MAX_\0" \
    "MALLOC_ARENA_MAX\0" \
    "MALLOC_ARENA_TEST\0"

#define UNSECURE_ENVVARS \
  "GCONV_PATH\0"							      \
  "GETCONF_DIR\0"							      \
  "HOSTALIASES\0"							      \
  "LD_AUDIT\0"								      \
  "LD_DEBUG\0"								      \
  "LD_DEBUG_OUTPUT\0"							      \
  "LD_DYNAMIC_WEAK\0"							      \
  "LD_HWCAP_MASK\0"							      \
  "LD_LIBRARY_PATH\0"							      \
  "LD_ORIGIN_PATH\0"							      \
  "LD_PRELOAD\0"							      \
  "LD_PROFILE\0"							      \
  "LD_SHOW_AUXV\0"							      \
  "LD_USE_LOAD_BIAS\0"							      \
  "LOCALDOMAIN\0"							      \
  "LOCPATH\0"								      \
  "MALLOC_TRACE\0"							      \
  "NIS_PATH\0"								      \
  "NLSPATH\0"								      \
  "RESOLV_HOST_CONF\0"							      \
  "RES_OPTIONS\0"							      \
  "TMPDIR\0"								      \
  // GLIBC_TUNABLES_ENVVAR							      \

int main(int argc, char **argv) {
    ASSERT(argc >= 1);

    // argv[0] goes into a lot of places, to a far greater degree than other elements
    // of argv. glibc has had buffer overflows relating to argv[0], eg CVE-2023-6246.
    // Since we expect the wrappers to be invoked from either $PATH or /run/wrappers/bin,
    // there should be no reason to pass any particularly large values here, so we can
    // be strict for strictness' sake.
    ASSERT(strlen(argv[0]) < 512);

    int debug = getenv(wrapper_debug) != NULL;

    // Drop insecure environment variables explicitly
    //
    // glibc does this automatically in SUID binaries, but we'd like to cover this:
    //
    //  a) before it gets to glibc
    //  b) in binaries that are only granted ambient capabilities by the wrapper,
    //     but don't run with an altered effective UID/GID, nor directly gain
    //     capabilities themselves, and thus don't run in secure mode.
    //
    // We're using musl, which doesn't drop environment variables in secure mode,
    // and we'd also like glibc-specific variables to be covered.
    //
    // If we don't explicitly unset them, it's quite easy to just set LD_PRELOAD,
    // have it passed through to the wrapped program, and gain privileges.
    for (char *unsec = UNSECURE_ENVVARS_TUNABLES UNSECURE_ENVVARS; *unsec; unsec = strchr(unsec, 0) + 1) {
        if (debug) {
            fprintf(stderr, "unsetting %s\n", unsec);
        }
        unsetenv(unsec);
    }

    execve(SOURCE_PROG, argv, environ);
    
    fprintf(stderr, "%s: cannot run `%s': %s\n",
        argv[0], SOURCE_PROG, strerror(errno));

    return 1;
}
