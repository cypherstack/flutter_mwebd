import 'dart:io';

import 'util.dart';

Future<void> ios(
  Directory outputDir,
  Directory repoDir,
  String toolsPath,
) async {
  if (!Platform.isMacOS) {
    throw Exception("IOS binaries require MacOS for building");
  }

  // await buildGoArchiveForIOS(
  //   isSim: true,
  //   outputName: "libmwebd_arm64_sim",
  //   goArch: "arm64",
  //   toolsPath: toolsPath,
  // );
  // await createFramework(
  //   inputLib: "${repoDir.path}/libmwebd_arm64_sim.a",
  //   arch: "arm64", // arm64 or amd64
  //   sdkName: "iphonesimulator", // "iphoneos" or "iphonesimulator"
  //   header: join(repoDir.path, "libmwebd_arm64_sim.h"),
  //   outputDir: outputDir.parent.path,
  //   frameworkName: "flutter_mwebd",
  // );

  await buildGoArchiveForIOS(
    isSim: false,
    outputName: "libmwebd_arm64",
    goArch: "arm64",
    toolsPath: toolsPath,
  );
  await createFramework(
    inputLib: "${repoDir.path}/libmwebd_arm64.a",
    arch: "arm64",
    sdkName: "iphoneos", // "iphoneos" or "iphonesimulator"
    header: join(repoDir.path, "libmwebd_arm64.h"),
    outputDir: outputDir.parent.path,
    frameworkName: "flutter_mwebd",
  );
}

Future<void> createFramework({
  required String inputLib,
  required String arch,
  required String sdkName,
  required String header,
  required String outputDir,
  required String frameworkName,
}) async {
  final tmp = Directory("tmp_dylib_build");
  if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  tmp.createSync(recursive: true);

  final tmpDir = Directory(join(tmp.path, arch))..createSync(recursive: true);

  Future<void> buildDylib(
    String arch,
    String inputA,
    String sdk,
    Directory outDir,
  ) async {
    final dylibPath = join(outDir.path, frameworkName);
    await runAsync("clang", [
      "-dynamiclib",
      "-arch",
      arch,
      "-isysroot",
      sdk,
      "-Wl,-all_load",
      inputA,
      "-o",
      dylibPath,
      "-install_name",
      "@rpath/$frameworkName.framework/$frameworkName",
      "-framework",
      "CoreFoundation",
      "-framework",
      "Security",
      "-lresolv",
    ]);
  }

  l("Building dylib for arch $arch...");
  final sdkPath = await _sdkPath(sdkName);
  await buildDylib(arch, inputLib, sdkPath, tmpDir);

  final outFramework = Directory(join(outputDir, "$frameworkName.framework"));
  if (outFramework.existsSync()) outFramework.deleteSync(recursive: true);
  outFramework.createSync(recursive: true);

  // Copy dylib binary
  final dylibOut = join(outFramework.path, frameworkName);
  File(join(tmpDir.path, frameworkName)).copySync(dylibOut);

  l("Adding headers...");
  final headersDir = Directory(join(outFramework.path, "Headers"))
    ..createSync();
  File(header).copySync(join(headersDir.path, "$frameworkName.h"));

  l("Writing Info.plist...");
  File(
    join(outFramework.path, "Info.plist"),
  ).writeAsStringSync(_iosPlist(frameworkName));

  l("Framework created at: ${outFramework.path}");
}

Future<void> buildGoArchiveForIOS({
  String goArch = "arm64",
  required bool isSim,
  required String outputName,
  int minVersion = 16,
  required String toolsPath,
  bool dylib = false,
}) async {
  final output = "$outputName.${dylib ? "dylib" : "a"}";
  final sdk = isSim ? "iphonesimulator" : "iphoneos";

  // Resolve arch
  final cArch = switch (goArch) {
    "arm64" => "arm64",
    "amd64" => "x86_64",
    _ => throw UnsupportedError("Unsupported GOARCH: $goArch"),
  };

  // target triple
  final target =
      !isSim
          ? "$cArch-apple-ios$minVersion"
          : "$cArch-apple-ios$minVersion-simulator";

  // find clang
  final clang = join(toolsPath, "ios_clang_wrapper.sh");

  final sdkPath = await _sdkPath(sdk);

  // environment vars for go
  final env = Map<String, String>.from(Platform.environment);
  env["GOOS"] = "ios";
  env["GOARCH"] = goArch;
  env["CGO_ENABLED"] = "1";
  env["SDK"] = sdk;
  env["SDK_PATH"] = sdkPath;
  env["TARGET"] = target;
  env["CGO_CFLAGS"] = "-fembed-bitcode";
  env["CGO_LDFLAGS"] = '-target $target -syslibroot "$sdkPath"';
  env["CC"] = clang;

  // go build
  await runAsync(
    "go",
    [
      "build",
      if (!dylib) "-buildmode=c-archive",
      if (dylib) "-buildmode=c-shared",
      "-o",
      output,
    ],
    environment: env,
    runInShell: true,
  );

  l("Built $output successfully.");
}

Future<String> _sdkPath(String sdk) async {
  final result = await Process.run('xcrun', ['--sdk', sdk, '--show-sdk-path']);
  if (result.exitCode != 0) {
    throw Exception('Failed to get SDK path: ${result.stderr}');
  }
  return result.stdout.toString().trim();
}

String _iosPlist(String frameworkName) => '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>BuildMachineOSBuild</key>
        <string>23E224</string>
        <key>CFBundleDevelopmentRegion</key>
        <string>en</string>
        <key>CFBundleExecutable</key>
        <string>$frameworkName</string>
        <key>CFBundleIdentifier</key>
        <string>com.cypherstack.$frameworkName</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundleName</key>
        <string>$frameworkName</string>
        <key>CFBundlePackageType</key>
        <string>FMWK</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0</string>
        <key>CFBundleSupportedPlatforms</key>
        <array>
            <string>iPhoneOS</string>
        </array>
        <key>CFBundleVersion</key>
        <string>1.0.0</string>
        <key>MinimumOSVersion</key>
        <string>16.0</string>
        <key>UIDeviceFamily</key>
        <array>
            <integer>1</integer>
        </array>
        <key>UIRequiredDeviceCapabilities</key>
        <array>
            <string>arm64</string>
        </array>
    </dict>
</plist>
''';
