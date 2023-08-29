import 'package:flutter/material.dart';
import 'http_handler.dart';
import 'package:provider/provider.dart';
import 'download_history.dart';
import 'side_bar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // Fields in a Widget subclass are always marked "final".
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // variable
  double _progress = 0;
  TextEditingController urlController = TextEditingController();
  TextEditingController fileNameController = TextEditingController();
  String lastSourceUrl = '';
  String lastFileName = '';

  void _updateProgress(double val) {
    setState(() {
      _progress = val;
    });
  }

  void _updateCurrentProcess(){
    setState(() {
      lastSourceUrl = urlController.text;
      lastFileName = fileNameController.text;
    });
  }

  void _finishCurrentProgress(){
    setState(() {
      lastSourceUrl = "";
      lastFileName = "";
    });
  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.

    DownloadHistories histories = Provider.of<DownloadHistories>(context);
    final HttpHandler handler = HttpHandler();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      drawer: const SideBar(),
      body: Container(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        margin: const EdgeInsets.all(20),
        child: Column(
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: urlController,
              decoration: const InputDecoration(hintText: "File URL"),
            ),
            TextField(
              controller: fileNameController,
              decoration: const InputDecoration(hintText: "File Name"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateCurrentProcess();
                handler.newDownload(histories, lastFileName, lastSourceUrl, _updateProgress,
                    _finishCurrentProgress);
              },
              child: const Text('Start'),
            ),
            ElevatedButton(
              onPressed: () {
                handler.pauseDownload(histories, lastFileName);
              },
              child: const Text('Pause'),
            ),
            ElevatedButton(
              onPressed: () {
                handler.resumeDownload(histories, lastFileName, lastSourceUrl, _updateProgress,
                    _finishCurrentProgress);
              },
              child: const Text('Resume'),
            ),
            ElevatedButton(
              onPressed: () {
                handler.cancelDownload(histories, lastFileName);
                _updateProgress(0);
              },
              child: const Text('Cancel'),
            ),
            LinearProgressIndicator(
              // value between 0~1
              value: _progress,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
