import 'dart:io';

/// extremely basic logger
void l(Object? o) {
  // Print to console
  // ignore: avoid_print
  print(o);
}

/// run a system process
Future<void> runAsync(
  String command,
  List<String> arguments, {
  Map<String, String>? environment,
  bool runInShell = false,
}) async {
  final process = await Process.start(
    command,
    arguments,
    environment: environment,
    runInShell: runInShell,
  );

  process.stdout.transform(SystemEncoding().decoder).listen((e) => l(e));
  process.stderr.transform(SystemEncoding().decoder).listen((e) => l(e));

  // Wait for the process to complete
  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    l("$command exited with code $exitCode");
    exit(exitCode);
  }
}

String getAndroidClangPath({
  required String ndkPath,
  required String abi,
  required int platformVersion,
}) {
  final base = "$ndkPath/toolchains/llvm/prebuilt/linux-x86_64/bin";

  final triple = switch (abi) {
    "arm64-v8a" => "aarch64-linux-android",
    "armeabi-v7a" => "armv7a-linux-androideabi",
    "x86" => "i686-linux-android",
    "x86_64" => "x86_64-linux-android",
    _ => throw ArgumentError("Unsupported ABI: $abi"),
  };

  return "$base/$triple$platformVersion-clang";
}
