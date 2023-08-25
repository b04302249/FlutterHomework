import 'package:flutter/material.dart';
import 'httpHandler.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'HTTP downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  // Fields in a Widget subclass are always marked "final".
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // variable
  int _counter = 0;
  double _progress = 0;
  TextEditingController urlController = TextEditingController();
  final HttpHandler handler = HttpHandler();
  String responseData = '';


  void _updateProgress(double val){
    setState(() {
      _progress = val;
    });
  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    return Scaffold(
      appBar: AppBar(

        backgroundColor: Colors.green,
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
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
            ElevatedButton(
                onPressed: (){
                  handler.newDownload(urlController.text, _updateProgress);
                }, 
                child:const Text('Start'),
            ),
            LinearProgressIndicator(
              // value between 0~1
              value: _progress,
              color: Colors.blue,
            ),
            ElevatedButton(
              onPressed: (){
                handler.pauseDownload();
              },
              child:const Text('Pause'),
            ),
            ElevatedButton(
              onPressed: (){
                handler.resumeDownload(urlController.text, _updateProgress);
              },
              child:const Text('Resume'),
            ),
            ElevatedButton(
              onPressed: (){
                handler.cancelDownload(_updateProgress);
              },
              child:const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
