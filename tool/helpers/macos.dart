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
    environment: {"CGO_ENABLED": "1"},
  );
  await createFramework(
    frameworkName: "flutter_mwebd",
    pathToDylib: join(outputDirPath, "libmwebd.dylib"),
    targetDirFrameworks: outputDirPath,
  );
}

Future<void> createFramework({
  required String frameworkName,
  required String pathToDylib,
  required String targetDirFrameworks,
}) async {
  // Create the framework directory
  final frameworkDir = Directory(
    join(targetDirFrameworks, "$frameworkName.framework"),
  );
  await frameworkDir.create(recursive: true);

  // Change directory to the framework directory and run commands
  final temp = Directory.current;
  Directory.current = frameworkDir;
  await runAsync("lipo", [
    "-create",
    pathToDylib,
    "-output",
    join(frameworkDir.path, frameworkName),
  ]);
  await runAsync("install_name_tool", [
    "-id",

    join("@rpath", "$frameworkName.framework", frameworkName),
    join(frameworkDir.path, frameworkName),
  ]);
  Directory.current = temp;

  // Create Info.plist file
  final plistFile = File(
    "${frameworkDir.path}"
    "${Platform.pathSeparator}Info.plist",
  );
  await plistFile.writeAsString(_macPlist(frameworkName));

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
