# flutter_mwebd

A Flutter package for [mwebd-wrapper](https://github.com/Cyrix126/mwebd-wrapper).

## Requirements

Install Flutter 3.44.9 or newer, Go 1.24.1 or newer, and Git. Flutter builds the
pinned Go source through Native Assets for Android, iOS, Linux, and macOS.

The build hook is written against `package:hooks` 2.x, which needs the 1.x hook
runner that Flutter first shipped in 3.41. The floor is pinned to the current
3.44 stable patch rather than 3.41.0 because Flutter only hotfixes its latest
stable patch, and two 3.44 hotfixes affect building this package: 3.44.6 fixes
a crash building a Linux asset bundle with native assets and no native app build
directory, and 3.44.8 fixes a lipo verification failure building macOS and iOS
under the Xcode 27 toolchain.

## Windows

- Windows uses a separately packaged `mwebd.exe` process, not Dart FFI.
- `MwebdServer` can hold its configuration on Windows, but its lifecycle
  methods are unsupported. The application owns executable extraction,
  validation, startup, and shutdown.

## Supported targets

- Android: arm, arm64, x86, and x64
- iOS device: arm64
- iOS simulator: arm64 and x64
- Linux: arm64 and x64 (host-native builds only)
- macOS: arm64 and x64
