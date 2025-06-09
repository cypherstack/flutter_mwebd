import 'package:path/path.dart' as path;

import 'util.dart';

Future<void> linux(String outputDirPath) async {
  await runAsync(
    "go",
    [
      "build",
      "-o",
      path.join(outputDirPath, "libmwebd.so"),
      "-buildmode=c-shared",
      ".",
    ],
    environment: {"CGO_ENABLED": "1"},
  );
}
