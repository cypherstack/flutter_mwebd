import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'exceptions.dart';
import 'flutter_mwebd_bindings_generated.dart';
import 'status.dart';

const String _libName = "flutter_mwebd";

/// The dynamic library in which the symbols for [MwebdClientBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open("$_libName.framework/$_libName");
  }
  if (Platform.isAndroid) {
    // just android things
    return DynamicLibrary.open("libmwebd.so");
  }
  if (Platform.isLinux) {
    return DynamicLibrary.open("libmwebd.so");
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open("libmwebd.dll");
  }
  throw UnsupportedError("Unknown platform: ${Platform.operatingSystem}");
}();

/// The bindings to the native functions in [_dylib].
final FlutterMwebdBindings _bindings = FlutterMwebdBindings(_dylib);

class MwebdServer {
  final String chain;
  final String dataDir;
  final String peer;
  final String proxy;

  final int serverPort;

  MwebdServer({
    required this.chain,
    required this.dataDir,
    required this.peer,
    required this.proxy,
    required this.serverPort,
  });

  int? _serverId;

  bool _isRunning = false;

  bool get wasCreated => _serverId != null;

  bool get isRunning => _isRunning;

  Future<void> createServer() async {
    if (_serverId != null) {
      throw MwebdServerAlreadyCreatedException();
    }

    // check dir exists or ffi will panic and crash
    if (!Directory(dataDir).existsSync()) {
      throw MwebdServerDataDirDoesNotExistException();
    }

    final chainPtr = chain.toNativeUtf8().cast<Char>();
    final dataDirPtr = dataDir.toNativeUtf8().cast<Char>();
    final peerPtr = peer.toNativeUtf8().cast<Char>();
    final proxyPtr = proxy.toNativeUtf8().cast<Char>();

    try {
      final result = await Isolate.run(() {
        return _bindings.CreateServer(chainPtr, dataDirPtr, peerPtr, proxyPtr);
      });

      _serverId = result;
    } finally {
      malloc.free(chainPtr);
      malloc.free(dataDirPtr);
      malloc.free(peerPtr);
      malloc.free(proxyPtr);
    }
  }

  Future<void> startServer() async {
    if (_serverId == null) {
      throw MwebdServerNotCreatedException();
    }
    if (isRunning) {
      throw MwebdServerAlreadyRunningException();
    }

    unawaited(
      Isolate.run(() {
        _bindings.StartServer(_serverId!, serverPort);
      }),
    );

    // TODO: keep? adjust delay? remove?
    await Future.delayed(const Duration(seconds: 4));

    _isRunning = true;

    return;
  }

  Future<void> stopServer() async {
    if (!isRunning) {
      throw MwebdServerNotRunningException();
    }
    if (_serverId == null) {
      throw MwebdServerNotCreatedException();
    }

    await Isolate.run(() {
      return _bindings.StopServer(_serverId!);
    });

    _serverId = null;
    _isRunning = false;
  }

  Future<Status> getStatus() async {
    if (!wasCreated) {
      throw MwebdServerNotCreatedException();
    }

    return await Isolate.run(() {
      final response = calloc<StatusResponse>();

      try {
        _bindings.Status(_serverId!, response);

        final status = Status(
          blockHeaderHeight: response.ref.block_header_height,
          mwebHeaderHeight: response.ref.mweb_header_height,
          mwebUtxosHeight: response.ref.mweb_utxos_height,
          blockTime: response.ref.block_time,
        );

        return status;
      } finally {
        calloc.free(response);
      }
    });
  }
}
