import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'helpers/android.dart';
import 'helpers/ios.dart';
import 'helpers/linux.dart';
import 'helpers/macos.dart';
import 'helpers/util.dart';
import 'helpers/windows.dart';

const kRepoUrl = "https://github.com/Cyrix126/mwebd-wrapper";
const kCommit = "20130a3f3e79ee82676aa98d85ac1997452a2d80";

void main(List<String> args) async {
  try {
    ArgParser parser =
        ArgParser()
          ..addOption(
            "platform",
            abbr: "p",
            allowed: ["android", "ios", "macos", "linux", "windows"],
            mandatory: true,
          )
          ..addOption("build-dir", abbr: "b", mandatory: true)
          ..addOption("output-dir", abbr: "o", mandatory: true)
          ..addOption("android_ndk", abbr: "n", mandatory: false)
          ..addOption("android_platform", abbr: "a", mandatory: false);
    final argResults = parser.parse(args);
    final platform = argResults.option("platform")!;
    final outputDirPath = argResults.option("output-dir")!;
    final outputDir = Directory(outputDirPath);
    if (!outputDir.existsSync()) {
      await outputDir.create(recursive: true);
    }

    // ios specific
    final toolsPath = path.join(Directory.current.path, "tool");

    final buildDir = Directory(argResults.option("build-dir")!);

    if (!buildDir.existsSync()) {
      await buildDir.create(recursive: true);
    }
    Directory.current = buildDir;

    // clone and checkout
    final repoDir = Directory(path.join(buildDir.path, "mwebd-wrapper"));
    if (!repoDir.existsSync()) {
      await runAsync("git", ["clone", kRepoUrl]);
    }
    Directory.current = repoDir;
    await runAsync("git", ["checkout", kCommit]);

    // platform specifics
    switch (platform) {
      case "macos":
        return await macos(outputDir.path);
      case "linux":
        return await linux(outputDir.path);
      case "windows":
        return await windows(outputDir.path);
      case "android":
        return await android(outputDir.path, argResults);
      case "ios":
        return await ios(outputDir, repoDir, toolsPath);
    }
  } catch (e, s) {
    l("$e\n$s");
    exit(1);
  }
}
