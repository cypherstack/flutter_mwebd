import 'dart:io';
import 'util.dart';

Future<void> windows(String outputDirPath) async {
  String wslPath(String windowsPath) {
    final drive = windowsPath[0].toLowerCase();
    final path = windowsPath.substring(2).replaceAll(r"\", "/");
    return "/mnt/$drive$path";
  }

  final dllPath = "$outputDirPath\\libmwebd.dll";
  final defPath = "$outputDirPath\\libmwebd.def";
  final libPath = "$outputDirPath\\libmwebd.lib";

  // 1. Build DLL and header with Go inside WSL
  await runAsync("wsl", [
    "bash",
    "-l",
    "-c",
    "GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc "
        "go build -o ${wslPath(outputDirPath)}/libmwebd.dll -buildmode=c-shared .",
  ]);

  // 2. Copy the generated header file out of WSL if needed
  await runAsync("wsl", [
    "cp",
    "${wslPath(outputDirPath)}/libmwebd.h",
    "${wslPath(outputDirPath)}/../../libmwebd.h",
  ]);

  // 3. Generate .def file from DLL exports using dumpbin (Windows command)
  // dumpbin output goes to a temp file, then you parse exported names to create .def

  // Run dumpbin to get exports
  final dumpbinResult = await Process.run("dumpbin", ["/exports", dllPath]);

  if (dumpbinResult.exitCode != 0) {
    throw Exception("dumpbin failed to read exports from libmwebd.dll");
  }

  final exportsText = dumpbinResult.stdout as String;

  // Extract exported function names for .def
  final exportNames = <String>[];
  final lines = exportsText.split("\n");
  bool exportsSection = false;
  for (final line in lines) {
    if (line.contains("ordinal hint")) {
      exportsSection = true;
      continue;
    }
    if (!exportsSection) continue;
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith("Summary")) break;

    // line format: ordinal hint RVA name
    final parts = trimmed.split(RegExp(r"\s+"));
    if (parts.length >= 4) {
      final name = parts[3];
      if (name != "_cgo_dummy_export") {
        // skip dummy export if any
        exportNames.add(name);
      }
    }
  }

  // Write .def file content
  final defFileContent = StringBuffer();
  defFileContent.writeln("LIBRARY libmwebd.dll");
  defFileContent.writeln("EXPORTS");
  for (final name in exportNames) {
    defFileContent.writeln(name);
  }

  final defFile = File(defPath);
  await defFile.writeAsString(defFileContent.toString());

  // 4. Run lib.exe to generate .lib import library
  final libResult = await Process.run("lib.exe", [
    "/def:$defPath",
    "/out:$libPath",
    "/machine:x64",
  ]);

  if (libResult.exitCode != 0) {
    throw Exception("lib.exe failed to create import library");
  }
}
