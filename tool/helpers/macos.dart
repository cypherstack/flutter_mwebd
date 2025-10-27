import 'dart:io';

import 'util.dart';

Future<void> macos(String outputDirPath) async {
  await runAsync(
    "go",
    [
      "build",
      "-o",
      join(outputDirPath, "libmwebd.dylib"),
      "-buildmode=c-shared",
      ".",
    ],
    environment: {"CGO_ENABLED": "1", "GOARCH": "arm64"},
  );
  await createMacosFramework(
    frameworkName: "flutter_mwebd",
    pathToDylib: join(outputDirPath, "libmwebd.dylib"),
    targetDirFrameworks: outputDirPath,
  );
  await runAsync("xcodebuild", [
    "-create-xcframework",
    "-framework",
    join(outputDirPath, "flutter_mwebd.framework"),
    "-output",
    join(outputDirPath, "flutter_mwebd.xcframework"),
  ]);

  l("Completed libmwebd xcframework for macos!");
}

Future<void> createMacosFramework({
  required String frameworkName,
  required String pathToDylib,
  required String targetDirFrameworks,
}) async {
  // Create the framework directory
  final frameworkDir = Directory(
    "$targetDirFrameworks"
    "${Platform.pathSeparator}$frameworkName.framework",
  );
  await frameworkDir.create(recursive: true);

  final resourcesDir = Directory(
    "${frameworkDir.path}"
    "${Platform.pathSeparator}Versions"
    "${Platform.pathSeparator}A"
    "${Platform.pathSeparator}Resources",
  );
  await resourcesDir.create(recursive: true);
  final versionADir = resourcesDir.parent;

  // Change directory to the framework directory and run commands
  final temp = Directory.current;
  Directory.current = versionADir;
  await runAsync("lipo", [
    "-create",
    pathToDylib,
    "-output",
    "${versionADir.path}"
        "${Platform.pathSeparator}$frameworkName",
  ]);
  await runAsync("install_name_tool", [
    "-id",
    "@rpath"
        "${Platform.pathSeparator}$frameworkName.framework"
        "${Platform.pathSeparator}Versions"
        "${Platform.pathSeparator}A"
        "${Platform.pathSeparator}$frameworkName",
    "${versionADir.path}"
        "${Platform.pathSeparator}$frameworkName",
  ]);
  Directory.current = temp;

  // Create Info.plist file
  final plistFile = File(
    "${resourcesDir.path}"
    "${Platform.pathSeparator}Info.plist",
  );
  await plistFile.writeAsString(_macPlist(frameworkName));

  Directory.current = frameworkDir;

  await Link(frameworkName).create(
    "Versions"
    "${Platform.pathSeparator}Current"
    "${Platform.pathSeparator}$frameworkName",
  );

  await Link("Resources").create(
    "Versions"
    "${Platform.pathSeparator}Current"
    "${Platform.pathSeparator}Resources",
  );

  Directory.current = versionADir.parent;
  await Link("Current").create("A", recursive: false);

  l("Framework $frameworkName created successfully in ${frameworkDir.path}");
}

String _macPlist(String frameworkName) => '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
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
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
</dict>
</plist>
''';
