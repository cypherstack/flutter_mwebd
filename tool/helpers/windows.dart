import 'util.dart';

Future<void> windows(String outputDirPath) async {
  await runAsync(
    "go",
    [
      "build",
      "-o",
      join(outputDirPath, "libmwebd.dll"),
      "-buildmode=c-shared",
      ".",
    ],
    environment: {"CGO_ENABLED": "1"},
  );
}
