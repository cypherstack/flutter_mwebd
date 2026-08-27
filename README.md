# flutter_mwebd

A Flutter package for [mwebd-wrapper](https://github.com/Cyrix126/mwebd-wrapper).

## Requirements

Install Go 1.24.1 or newer and Git. Flutter builds the pinned Go source through
Native Assets for Android, iOS, Linux, and macOS.

## Windows

- Windows uses a separately packaged `mwebd.exe` process, not Dart FFI.
- `MwebdServer` can hold its configuration on Windows, but its lifecycle
  methods are unsupported. The application owns executable extraction,
  validation, startup, and shutdown.

## Supported targets

- Android: arm, arm64, x86, and x64
- iOS device: arm64
- iOS simulator: arm64 and x64
- Linux: x64
- macOS: arm64 and x64
