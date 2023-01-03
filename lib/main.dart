import 'dart:convert';
import 'dart:io';

import 'package:droid_top/utils/parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        // primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class TopProcess {
  String name;
  double cpu;
  double memory;
  TopProcess({required this.cpu, required this.name, required this.memory});
}

class _MyHomePageState extends State<MyHomePage> {
  String _outText = "";
  bool _isRunning = true;
  List<TopProcess> topProcesses = [];

  @override
  void initState() {
    super.initState();

    runTop();
    // test();
  }

  test() async {
    final runningAppProcesses =
        await channel.invokeMethod("getRunningAppProcesses");
    print("runningAppProcesses:" + runningAppProcesses.toString());
  }

  Process? process;

  runTop() async {
    process?.kill();
    // if (process == null) {
    process = await Process.start('su', []);
    process?.stdout.transform(utf8.decoder).forEach((element) {
      print("=====================================================");
      print(element);
      if (!element.contains("Tasks")) {
        return;
      }
      setState(() {
        topProcesses.clear();
      });
      // print(parseTopOutput(element));
      String outText = "";
      element.split("\n").forEach((e) {
        try {
          String name = "", user = "";
          double memory = 0, cpu = 0;
          if (e.startsWith(RegExp(r'[0-9]')) && !e.contains("cpu")) {
            name = e.substring(nameStart).trim();
            user = e.substring(pidEnd, userEnd).trim();
            if (!user.startsWith("u0_") || name == "su") {
              return;
            }
            memory = double.parse(e.substring(memoryStart, memoryEnd));
            cpu = double.parse(e.substring(cpuStart, cpuEnd));
            setState(() {
              topProcesses
                  .add(TopProcess(name: name, cpu: cpu, memory: memory));
            });
          }
        } catch (error) {}
      });
    });
    // }

    // final code = await process.exitCode;
    // print("code=" + code.toString());
    process?.stdin.writeln('COLUMNS=512 ROWS=1512 top -d 5 -m 1000');
    // process.stdin.writeln('ps -Ao %cpu,%mem,user,comm');
  }

  final channel = MethodChannel("app.droid_top");
  final imageMemory = {};

  _onRefresh() async {
    await runTop();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: () async {
                if (_isRunning) {
                  process?.kill();
                  final exitCode = await process?.exitCode;
                  if (exitCode != null && exitCode < 0) {
                    setState(() {
                      _isRunning = false;
                    });
                  }
                } else {
                  setState(() {
                    _isRunning = true;
                  });
                  _onRefresh();
                }
              },
              icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 16))
        ],
      ),
      body: RefreshIndicator(
        child: ListView.builder(
          itemCount: topProcesses.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const ListTile(
                leading: Text("icon"),
                title: Text("process name"),
                trailing: Text("CPU%"),
              );
            }
            final topProcess = topProcesses[index - 1];
            return ListTile(
              leading: SizedBox(
                width: 80,
                height: 80,
                child: imageMemory[topProcess.name] == null
                    ? FutureBuilder(
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Container();
                          }
                          imageMemory[topProcess.name] = snapshot.data;
                          return Image.memory(snapshot.data);
                        },
                        future: channel
                            .invokeMethod("getApplicationIcon", topProcess.name)
                            .catchError(() => null),
                      )
                    : Image.memory(imageMemory[topProcess.name]),
              ),
              title: Text(topProcess.name.isEmpty ? "N/A" : topProcess.name),
              subtitle: Text(topProcess.name),
              trailing: Text(topProcess.cpu.toString()),
            );
          },
        ),
        onRefresh: () async {
          await _onRefresh();
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     runTop();
      //   },
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
