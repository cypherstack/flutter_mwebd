import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'exceptions.dart';
import 'flutter_mwebd_bindings_generated.dart' as native;
import 'status.dart';

const _windowsMessage =
    'On Windows, launch the standalone mwebd.exe process instead of using '
    'MwebdServer lifecycle methods.';

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
    _ensureNativeLifecycleAvailable();
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
        return native.CreateServer(chainPtr, dataDirPtr, peerPtr, proxyPtr);
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
    _ensureNativeLifecycleAvailable();
    if (_serverId == null) {
      throw MwebdServerNotCreatedException();
    }
    if (isRunning) {
      throw MwebdServerAlreadyRunningException();
    }

    unawaited(
      Isolate.run(() {
        native.StartServer(_serverId!, serverPort);
      }),
    );

    await Future.delayed(const Duration(seconds: 4));

    _isRunning = true;

    return;
  }

  Future<void> stopServer() async {
    _ensureNativeLifecycleAvailable();
    if (!isRunning) {
      throw MwebdServerNotRunningException();
    }
    if (_serverId == null) {
      throw MwebdServerNotCreatedException();
    }

    await Isolate.run(() {
      return native.StopServer(_serverId!);
    });

    _serverId = null;
    _isRunning = false;
  }

  Future<Status> getStatus() async {
    _ensureNativeLifecycleAvailable();
    if (!wasCreated) {
      throw MwebdServerNotCreatedException();
    }

    return await Isolate.run(() {
      final response = calloc<native.StatusResponse>();

      try {
        native.Status(_serverId!, response);

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

  void _ensureNativeLifecycleAvailable() {
    if (Platform.isWindows) throw UnsupportedError(_windowsMessage);
  }
}
