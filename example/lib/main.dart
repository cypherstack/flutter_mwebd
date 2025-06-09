import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_mwebd/flutter_mwebd.dart' as flutter_mwebd;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final chainController = TextEditingController();
  final dataDirController = TextEditingController();
  final peerController = TextEditingController();
  final proxyController = TextEditingController();
  final portController = TextEditingController();

  flutter_mwebd.MwebdServer? client;

  @override
  void dispose() {
    chainController.dispose();
    dataDirController.dispose();
    peerController.dispose();
    proxyController.dispose();
    portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const spacerSmall = SizedBox(height: 16);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mwebd server example')),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                spacerSmall,

                if (client == null)
                  Column(
                    children: [
                      TextField(
                        controller: chainController,
                        decoration: InputDecoration(
                          labelText: "Chain",
                          hintText: "mainnet",
                        ),
                      ),
                      spacerSmall,
                      TextField(
                        controller: dataDirController,
                        decoration: InputDecoration(
                          labelText: "Data directory",
                        ),
                      ),
                      spacerSmall,
                      TextField(
                        controller: peerController,
                        decoration: InputDecoration(labelText: "Peer"),
                      ),
                      spacerSmall,
                      TextField(
                        controller: proxyController,
                        decoration: InputDecoration(labelText: "Proxy"),
                      ),
                      spacerSmall,
                      TextField(
                        controller: portController,
                        keyboardType: TextInputType.numberWithOptions(),
                        decoration: InputDecoration(labelText: "Port"),
                      ),
                      spacerSmall,
                      spacerSmall,
                      spacerSmall,
                      TextButton(
                        onPressed: () async {
                          try {
                            if (Platform.isAndroid ||
                                Platform.isIOS ||
                                Platform.isMacOS) {
                              final appDir =
                                  await getApplicationSupportDirectory();
                              dataDirController.text =
                                  "${appDir.path}/${dataDirController.text}";
                            }

                            final client = flutter_mwebd.MwebdServer(
                              chain: chainController.text,
                              dataDir: dataDirController.text,
                              peer: peerController.text,
                              proxy: proxyController.text,
                              serverPort: int.parse(portController.text),
                            );

                            print("Creating server...");
                            await client.createServer();
                            print("server created");

                            setState(() {
                              this.client = client;
                            });
                          } catch (e, s) {
                            print("$e\n$s");
                          }
                        },
                        child: Text("Create server"),
                      ),
                    ],
                  ),

                if (client != null)
                  Column(
                    children: [
                      TextButton(
                        onPressed: () async {
                          try {
                            final status = await client!.getStatus();
                            print(status);
                          } catch (e, s) {
                            print("$e\n$s");
                          }
                        },
                        child: Text("Server status"),
                      ),
                      spacerSmall,
                      TextButton(
                        onPressed: () async {
                          try {
                            print("Starting server..");
                            await client!.startServer();
                            print("Server started");
                          } catch (e, s) {
                            print("$e\n$s");
                          }
                        },
                        child: Text("Start server"),
                      ),
                      spacerSmall,
                      TextButton(
                        onPressed: () async {
                          try {
                            print("Stopping server...");
                            await client!.stopServer();
                            print("Server stopped");
                            setState(() {
                              client = null;
                            });
                          } catch (e, s) {
                            print("$e\n$s");
                          }
                        },
                        child: Text("Stop server"),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
