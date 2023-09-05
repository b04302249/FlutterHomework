
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
  TextEditingController urlController = TextEditingController();
  TextEditingController fileNameController = TextEditingController();
  final HttpHandler handler = HttpHandler();
  final TEST_URL1 = 'https://research.nhm.org/pdfs/10840/10840.pdf';
  final TEST_URL2 = "https://miro.medium.com/v2/resize:fit:720/format:webp/1*XEgA1TTwXa5AvAdw40GFow.png";
  final TEST_URL3 = 'https://i.imgur.com/hw41l0p.jpg';
  final TEST_URL4 = 'https://img.4gamers.com.tw/news-image/9ac84565-1cb1-4c5b-a69b-ede4ae932e00.jpg';
  final TEST_URL5 = 'https://pbs.twimg.com/media/EcypQCEU8AAgGgk.jpg';


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DownloadHistories histories = Provider.of<DownloadHistories>(context, listen: false);
    CurrentDownloadTarget target = Provider.of<CurrentDownloadTarget>(context, listen: false);
    if (state == AppLifecycleState.paused) {
      handler.pauseDownload(histories, target.fileName);
      print("Sensor screen is close!!");
    }
    else if (state == AppLifecycleState.resumed){
      handler.resumeDownload(histories, target);
      print("Sensor screen is resumed");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _updateCurrentTarget(CurrentDownloadTarget target){
    // target.changeFileName("sample2.jpg");
    // target.changeSourceUrl(TEST_URL4);
    target.changeFileName(fileNameController.text);
    target.changeSourceUrl(urlController.text);
  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.

    DownloadHistories histories = Provider.of<DownloadHistories>(context);
    CurrentDownloadTarget target = Provider.of<CurrentDownloadTarget>(context);

    // set up initial value
    if (target.fileName != ""){
      fileNameController.text = target.fileName;
    }
    if (target.sourceUrl != ""){
      urlController.text = target.sourceUrl;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: const SideBar(),
      body: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
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
                if (target.totalBytes != 0 || target.downloadedBytes != 0){
                  print("It looks like there already exist a download task! "
                      "File name: ${target.fileName}");
                  return;
                }
                _updateCurrentTarget(target);
                if (target.fileName != "" && target.sourceUrl != "")
                  handler.newDownload(histories, target,);
              },
              child: const Text('Start'),
            ),
            ElevatedButton(
              onPressed: () {
                handler.pauseDownload(histories, target.fileName);
              },
              child: const Text('Pause'),
            ),
            ElevatedButton(
              onPressed: () {
                handler.resumeDownload(histories, target,);
              },
              child: const Text('Resume'),
            ),
            ElevatedButton(
              onPressed: () {
                handler.cancelDownload(histories, target.fileName);
                print("success cancel!");
                target.reset();
              },
              child: const Text('Cancel'),
            ),
            LinearProgressIndicator(
              // value between 0~1
              value: target.progress,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }


}



