#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

// Check 64-bit platforms
#if defined(_WIN64) || \
    defined(__x86_64__) || defined(__x86_64) || defined(__amd64__) || defined(__amd64) || \
    defined(__aarch64__) || defined(_M_X64) || defined(_M_AMD64) || \
    defined(__powerpc64__) || defined(__ppc64__) || defined(__LP64__) || defined(_LP64)
#include "libmwebd.h"
#elif defined(_WIN32) || \
      defined(__i386__) || defined(__i386) || defined(__i686__) || defined(_M_IX86) || \
      defined(__arm__) || defined(__thumb__) || defined(_M_ARM) || \
      defined(__powerpc__) || defined(__ppc__) || defined(__ILP32__)
#include "libmwebd_32.h"
#else
#error "Unknown architecture, cannot determine 32-bit or 64-bit"
#endif

FFI_PLUGIN_EXPORT uintptr_t CreateServer(char* chain, char* dataDir, char* peer, char* proxy);
FFI_PLUGIN_EXPORT int StartServer(uintptr_t id, int port);
FFI_PLUGIN_EXPORT void StopServer(uintptr_t id);
FFI_PLUGIN_EXPORT void Status(uintptr_t id, StatusResponse* out);
