import 'dart:io';

/// extremely basic logger
void l(Object? o) {
  // Print to console
  // ignore: avoid_print
  print(o);
}

/// run a system process
Future<void> runAsync(
  String command,
  List<String> arguments, {
  Map<String, String>? environment,
}) async {
  final process = await Process.start(
    command,
    arguments,
    environment: environment,
  );

  process.stdout.transform(SystemEncoding().decoder).listen((e) => l(e));
  process.stderr.transform(SystemEncoding().decoder).listen((e) => l(e));

  // Wait for the process to complete
  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    l("$command exited with code $exitCode");
    exit(exitCode);
  }
}
