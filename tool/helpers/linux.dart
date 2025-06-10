import 'util.dart';

Future<void> linux(String outputDirPath) async {
  await runAsync(
    "go",
    [
      "build",
      "-o",
      join(outputDirPath, "libmwebd.so"),
      "-buildmode=c-shared",
      ".",
    ],
    environment: {"CGO_ENABLED": "1"},
  );
}
