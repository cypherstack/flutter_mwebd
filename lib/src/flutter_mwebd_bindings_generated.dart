// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

/// Bindings for `src/flutter_mwebd.h`.
///
/// Regenerate bindings with `dart run ffigen --config ffigen.yaml`.
///
class FlutterMwebdBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
  _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  FlutterMwebdBindings(ffi.DynamicLibrary dynamicLibrary)
    : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  FlutterMwebdBindings.fromLookup(
    ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName) lookup,
  ) : _lookup = lookup;

  int CreateServer(
    ffi.Pointer<ffi.Char> chain,
    ffi.Pointer<ffi.Char> dataDir,
    ffi.Pointer<ffi.Char> peer,
    ffi.Pointer<ffi.Char> proxy,
  ) {
    return _CreateServer(chain, dataDir, peer, proxy);
  }

  late final _CreateServerPtr = _lookup<
    ffi.NativeFunction<
      ffi.UintPtr Function(
        ffi.Pointer<ffi.Char>,
        ffi.Pointer<ffi.Char>,
        ffi.Pointer<ffi.Char>,
        ffi.Pointer<ffi.Char>,
      )
    >
  >('CreateServer');
  late final _CreateServer =
      _CreateServerPtr.asFunction<
        int Function(
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
          ffi.Pointer<ffi.Char>,
        )
      >();

  int StartServer(int id, int port) {
    return _StartServer(id, port);
  }

  late final _StartServerPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.UintPtr, ffi.Int)>>(
        'StartServer',
      );
  late final _StartServer =
      _StartServerPtr.asFunction<int Function(int, int)>();

  void StopServer(int id) {
    return _StopServer(id);
  }

  late final _StopServerPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.UintPtr)>>('StopServer');
  late final _StopServer = _StopServerPtr.asFunction<void Function(int)>();

  void Status(int id, ffi.Pointer<StatusResponse> out) {
    return _Status(id, out);
  }

  late final _StatusPtr = _lookup<
    ffi.NativeFunction<
      ffi.Void Function(ffi.UintPtr, ffi.Pointer<StatusResponse>)
    >
  >('Status');
  late final _Status =
      _StatusPtr.asFunction<void Function(int, ffi.Pointer<StatusResponse>)>();
}

final class StatusResponse extends ffi.Struct {
  @ffi.Int32()
  external int block_header_height;

  @ffi.Int32()
  external int mweb_header_height;

  @ffi.Int32()
  external int mweb_utxos_height;

  @ffi.Uint32()
  external int block_time;
}
