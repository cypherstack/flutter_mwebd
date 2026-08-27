import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

const _repository = 'https://github.com/cypherstack/mwebd-wrapper';
const _commit = '68c02c2eef1e226efebd48ecf91f23320941984e';
const _assetName = 'src/flutter_mwebd_bindings_generated.dart';

Future<void> main(List<String> arguments) async {
  await build(arguments, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final config = input.config.code;
    if (config.targetOS == OS.windows) return;

    _validateTarget(config);

    final go = await _findExecutable('go');
    output.dependencies.add(Uri.file(go));

    final sourceDirectory = Directory.fromUri(
      input.outputDirectory.resolve('mwebd-wrapper/'),
    );
    await _checkoutSource(sourceDirectory);

    final library = input.outputDirectory.resolve(
      _libraryName(config.targetOS),
    );
    if (config.targetOS == OS.iOS) {
      await _buildIOS(go, sourceDirectory, library, config);
    } else {
      await _buildShared(go, sourceDirectory, library, config);
    }

    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: _assetName,
        file: library,
        linkMode: DynamicLoadingBundled(),
      ),
    );
  });
}

Future<void> _checkoutSource(Directory directory) async {
  if (!directory.existsSync()) {
    await _run('git', ['clone', _repository, directory.path]);
  }
  await _run('git', [
    'checkout',
    '--detach',
    _commit,
  ], workingDirectory: directory.path);
}

Future<void> _buildShared(
  String go,
  Directory sourceDirectory,
  Uri library,
  CodeConfig config,
) async {
  final compiler = config.cCompiler?.compiler.toFilePath();
  if (config.targetOS == OS.android && compiler == null) {
    throw StateError('An Android C compiler is required.');
  }

  final environment = <String, String>{
    'CGO_ENABLED': '1',
    'GOARCH': _goArchitecture(config.targetArchitecture),
    'GOOS': _goOS(config.targetOS),
    if (config.targetArchitecture == Architecture.arm) 'GOARM': '7',
    if (compiler != null) 'CC': compiler,
  };

  if (config.targetOS == OS.android) {
    final target =
        '${_androidArchitecture(config.targetArchitecture)}'
        '${config.android.targetNdkApi}';
    environment['CGO_CFLAGS'] = '--target=$target';
    environment['CGO_LDFLAGS'] = '--target=$target';
  } else if (config.targetOS == OS.macOS) {
    final sdk = await _sdkPath('macosx');
    final target =
        '${_appleArchitecture(config.targetArchitecture)}-apple-macos'
        '${config.macOS.targetVersion}.0';
    environment['CGO_CFLAGS'] = '-target $target -isysroot "$sdk"';
    environment['CGO_LDFLAGS'] =
        '-target $target -isysroot "$sdk" '
        '-Wl,-headerpad_max_install_names';
  }

  await _run(
    go,
    ['build', '-buildmode=c-shared', '-o', library.toFilePath(), '.'],
    workingDirectory: sourceDirectory.path,
    environment: environment,
  );
}

Future<void> _buildIOS(
  String go,
  Directory sourceDirectory,
  Uri library,
  CodeConfig config,
) async {
  final sdkName = config.iOS.targetSdk.type;
  final sdk = await _sdkPath(sdkName);
  final target =
      '${_appleArchitecture(config.targetArchitecture)}-apple-ios'
      '${config.iOS.targetVersion}'
      '${config.iOS.targetSdk == IOSSdk.iPhoneSimulator ? '-simulator' : ''}';
  final compiler = config.cCompiler?.compiler.toFilePath();
  if (compiler == null) {
    throw StateError('An Apple C compiler is required to build for iOS.');
  }

  final archive = library.resolve('libmwebd.a');
  final flags = '-target $target -isysroot "$sdk"';
  await _run(
    go,
    ['build', '-buildmode=c-archive', '-o', archive.toFilePath(), '.'],
    workingDirectory: sourceDirectory.path,
    environment: {
      'CC': compiler,
      'CGO_CFLAGS': flags,
      'CGO_ENABLED': '1',
      'CGO_LDFLAGS': flags,
      'GOARCH': _goArchitecture(config.targetArchitecture),
      'GOOS': 'ios',
    },
  );

  await _run(compiler, [
    '-dynamiclib',
    '-target',
    target,
    '-isysroot',
    sdk,
    '-Wl,-headerpad_max_install_names',
    '-Wl,-all_load',
    archive.toFilePath(),
    '-o',
    library.toFilePath(),
    '-framework',
    'CoreFoundation',
    '-framework',
    'Security',
    '-lresolv',
  ]);
}

void _validateTarget(CodeConfig config) {
  final architecture = config.targetArchitecture;
  final supported = switch (config.targetOS) {
    OS.android => const [
      Architecture.arm,
      Architecture.arm64,
      Architecture.ia32,
      Architecture.x64,
    ].contains(architecture),
    OS.iOS =>
      architecture == Architecture.arm64 ||
          config.iOS.targetSdk == IOSSdk.iPhoneSimulator &&
              architecture == Architecture.x64,
    OS.linux => architecture == Architecture.x64,
    OS.macOS =>
      architecture == Architecture.arm64 || architecture == Architecture.x64,
    _ => false,
  };
  if (!supported) {
    throw UnsupportedError(
      'flutter_mwebd does not support ${config.targetOS} $architecture.',
    );
  }
}

String _libraryName(OS os) => switch (os) {
  OS.android || OS.linux => 'libmwebd.so',
  OS.iOS || OS.macOS => 'libmwebd.dylib',
  _ => throw UnsupportedError('Unsupported target OS: $os'),
};

String _goOS(OS os) => switch (os) {
  OS.android => 'android',
  OS.linux => 'linux',
  OS.macOS => 'darwin',
  _ => throw UnsupportedError('Unsupported target OS: $os'),
};

String _goArchitecture(Architecture architecture) => switch (architecture) {
  Architecture.arm => 'arm',
  Architecture.arm64 => 'arm64',
  Architecture.ia32 => '386',
  Architecture.x64 => 'amd64',
  _ => throw UnsupportedError('Unsupported architecture: $architecture'),
};

String _appleArchitecture(Architecture architecture) => switch (architecture) {
  Architecture.arm64 => 'arm64',
  Architecture.x64 => 'x86_64',
  _ => throw UnsupportedError('Unsupported Apple architecture: $architecture'),
};

String _androidArchitecture(
  Architecture architecture,
) => switch (architecture) {
  Architecture.arm => 'armv7a-linux-androideabi',
  Architecture.arm64 => 'aarch64-linux-android',
  Architecture.ia32 => 'i686-linux-android',
  Architecture.x64 => 'x86_64-linux-android',
  _ =>
    throw UnsupportedError('Unsupported Android architecture: $architecture'),
};

Future<String> _sdkPath(String sdk) async {
  return (await _capture('xcrun', ['--sdk', sdk, '--show-sdk-path'])).trim();
}

Future<String> _findExecutable(String executable) async {
  final command = Platform.isWindows ? 'where' : 'which';
  final result = await _capture(command, [executable]);
  return result.split(RegExp(r'[\r\n]+')).first;
}

Future<String> _capture(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      result.stderr.toString(),
      result.exitCode,
    );
  }
  return result.stdout.toString();
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException(executable, arguments, '', exitCode);
  }
}
