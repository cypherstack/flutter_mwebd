import 'dart:io';

import 'util.dart';

Future<void> android(
  String outputDirPath,
  String ndk,
  String androidPlatform,
) async {
  final abi = outputDirPath.split(Platform.pathSeparator).last;

  final cc = getAndroidClangPath(
    ndkPath: ndk,
    abi: abi,
    platformVersion: int.parse(androidPlatform.split("-").last),
  );

  final arch = switch (abi) {
    "arm64-v8a" => "arm64",
    "armeabi-v7a" => "arm",
    "x86" => "386",
    "x86_64" => "amd64",
    _ => throw ArgumentError("Unsupported ABI: $abi"),
  };

  return await runAsync(
    "go",
    [
      "build",
      "-o",
      join(outputDirPath, "libmwebd.so"),
      "-buildmode=c-shared",
      ".",
    ],
    environment: {
      "CGO_ENABLED": "1",
      "CC": cc,
      "GOOS": "android",
      "GOARCH": arch,
      if (arch == "arm") "GOARM": "7",
    },
  );
}
