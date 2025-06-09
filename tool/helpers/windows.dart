import 'package:path/path.dart' as path;

import 'util.dart';

Future<void> windows(String outputDirPath) async {
  await runAsync(
    "go",
    [
      "build",
      "-o",
      path.join(outputDirPath, "libmwebd.dll"),
      "-buildmode=c-shared",
      ".",
    ],
    environment: {"CGO_ENABLED": "1"},
  );
}
