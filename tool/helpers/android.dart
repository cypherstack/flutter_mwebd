import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'util.dart';

Future<void> android(String outputDirPath, ArgResults argResults) async {
  final abi = path.basename(outputDirPath);
  final ndk = argResults.option("android_ndk")!;
  final platform = argResults.option("android_platform")!;

  final cc = getAndroidClangPath(
    ndkPath: ndk,
    abi: abi,
    platformVersion: int.parse(platform.split("-").last),
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
      path.join(outputDirPath, "libmwebd.so"),
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
