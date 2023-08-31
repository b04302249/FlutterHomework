import 'dart:async';

import 'package:flutter/material.dart';
import 'http_handler.dart';
import 'package:provider/provider.dart';
import 'download_data.dart';
import 'side_bar.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // Fields in a Widget subclass are always marked "final".
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver{
  // variable
  double _progress = 0;
  TextEditingController urlController = TextEditingController();
  TextEditingController fileNameController = TextEditingController();
  String lastSourceUrl = '';
  String lastFileName = '';
  final HttpHandler handler = HttpHandler();
  final TEST_URL1 = 'https://research.nhm.org/pdfs/10840/10840.pdf';
  final TEST_URL2 = "https://miro.medium.com/v2/resize:fit:720/format:webp/1*XEgA1TTwXa5AvAdw40GFow.png";
  // final TEST_URL = 'https://www.sampledocs.in/DownloadFiles/SampleFile?filename=sampledocs-100mb-pdf-file&ext=pdf';


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {

  }

  void _updateProgress(double val) {
    setState(() {
      _progress = val;
    });
  }

  void _updateCurrentProcess(CurrentDownloadTarget target){
    target.changeFileName("sample.pdf");
    target.changeSourceUrl(TEST_URL1);
  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.

    DownloadHistories histories = Provider.of<DownloadHistories>(context);
    CurrentDownloadTarget target = Provider.of<CurrentDownloadTarget>(context);

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
                _updateCurrentProcess(target);
                handler.newDownload(histories, target, _updateProgress,);
              },
              child: const Text('Start'),
            ),
            ElevatedButton(
              onPressed: () {
                handler.pauseDownload(histories, target.getFileName());
              },
              child: const Text('Pause'),
            ),
            ElevatedButton(
              onPressed: () {
                handler.resumeDownload(histories, target, _updateProgress,);
              },
              child: const Text('Resume'),
            ),
            ElevatedButton(
              onPressed: () {
                handler.cancelDownload(histories, target.getFileName());
                target.reset();
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



