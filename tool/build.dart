import 'dart:io';

import 'helpers/android.dart';
import 'helpers/ios.dart';
import 'helpers/linux.dart';
import 'helpers/macos.dart';
import 'helpers/util.dart';
import 'helpers/windows.dart';

const kRepoUrl = "https://github.com/Cyrix126/mwebd-wrapper";
const kCommit = "7685af456b0ed6d0aac723d1db28d19e050879af";

void main(List<String> args) async {
  try {
    final Map<String, String> options = {};

    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg.startsWith('--') || arg.startsWith('-')) {
        final key = arg.replaceFirst(RegExp(r'^--?'), '');
        final next = i + 1 < args.length ? args[i + 1] : null;

        if (next != null && !next.startsWith('-')) {
          options[key] = next;
          i++;
        } else {
          options[key] = '';
        }
      }
    }

    final platform = options['p'] ?? options['platform'];
    final outputDirPath = options['o'] ?? options['output-dir'];
    final buildDirPath = options['b'] ?? options['build-dir'];
    final outputDir = Directory(outputDirPath!);
    if (!outputDir.existsSync()) {
      await outputDir.create(recursive: true);
    }

    final buildDir = Directory(buildDirPath!);

    if (!buildDir.existsSync()) {
      await buildDir.create(recursive: true);
    }
    Directory.current = buildDir;

    // clone and checkout
    final repoDir = Directory(join(Directory.current.path, "mwebd-wrapper"));
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
        final ndk = options['n'] ?? options['android_ndk'];
        final androidPlatform = options['a'] ?? options['android_platform'];

        return await android(outputDir.path, ndk!, androidPlatform!);
      case "ios":
        final toolsPath = join(Directory.current.path, "tool");
        return await ios(outputDir, repoDir, toolsPath);
    }
  } catch (e, s) {
    l("$e\n$s");
    exit(1);
  }
}
