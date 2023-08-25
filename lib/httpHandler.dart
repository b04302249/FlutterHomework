
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'dart:typed_data';
import 'main.dart';


class DownloadArgs{
  final SendPort sendPort;
  final String downloadUrl;
  final String destPath;
  final int startBytes;
  final int endBytes;

  DownloadArgs(this.sendPort, this.downloadUrl, this.destPath, this.startBytes, this.endBytes);
}


class HttpHandler{

  int downloadedBytes = 0;
  int totalBytes = 0;
  final String fileName = 'sample.pdf';
  // final TEST_URL = 'https://www.africau.edu/images/default/sample.pdf';
  final TEST_URL = 'https://research.nhm.org/pdfs/10840/10840.pdf';
  // final TEST_URL = 'https://www.sampledocs.in/DownloadFiles/SampleFile?filename=sampledocs-100mb-pdf-file&ext=pdf';
  // final TEST_URL = 'https://drive.google.com/uc?id=1uQY0Mey2N8Xa_lCI6YFAb1_nFfrcsKpZ&export=download' ;
  Isolate? _downloadIsolate;
  SendPort? _toDownloadPort;





  Future<void> downloadFile(String fileURL, void Function(double val) updateFunc) async{

    // get the information of totalBytes
    if (totalBytes == 0){
      final response = await http.head(Uri.parse(fileURL));
      String contentLen = '';
      if (response.headers['content-length'] != null)
        contentLen = response.headers['content-length'].toString();
      try{
        totalBytes = int.parse(contentLen);
      } catch(e){
        print("content-length is not a number!!");
      }
    }


    // create isolate and port
    final _toMainPort = ReceivePort();
    final destDir = await getApplicationDocumentsDirectory();
    _downloadIsolate = await Isolate.spawn(downloadRangeFile,
        DownloadArgs(_toMainPort.sendPort, fileURL, destDir.path, downloadedBytes, totalBytes));


    // deal with communication between download iso and main iso
    _toMainPort!.listen( (message) {
      // handshake, build connection
      if (message is SendPort){
        _toDownloadPort = message;
      } else if (message is String){
        if (message == 'completed'){
          completeDownload();
          _toMainPort.close();
          print("Download task completed!!");
        } else if (message.substring(0,5) == 'pause'){
          // remember the progress current download, start from current progress next time
          downloadedBytes = int.parse(message.substring(6));
          print("pause request from download iso, downloadedBytes: ${downloadedBytes}");
        }
      } else if (message is double){
        updateFunc(message);
      }

    });


  }



  void downloadRangeFile(DownloadArgs args) async {

    // create port, send the port back to main iso
    final toDownloadPort = ReceivePort();
    args.sendPort.send(toDownloadPort.sendPort);

    // arguments
    int accomplishedBytes = args.startBytes;

    // download task
    final request = http.Request('Get', Uri.parse(args.downloadUrl));
    final rangeHeaderValue = 'bytes=${args.startBytes}-${args.endBytes}';
    request.headers['Range'] = rangeHeaderValue;
    final response = await request.send();
    print("get response, status code: ${response.statusCode}");


    // listen message from main to download, pause if necessary
    File file = await openFile(args.startBytes, args.destPath);
    toDownloadPort!.listen((message){
      if (message == 'pause'){
        args.sendPort.send('pause:${accomplishedBytes}');
        toDownloadPort.close();
        Isolate.current.kill(priority: Isolate.immediate);
      }
    });

    // accept chunks from response, don't have to close file, file will close once it finish
    response.stream.listen((List<int> chunk) {
      // await file.writeAsBytes(chunk, mode: FileMode.append, flush: true);
      file.writeAsBytesSync(chunk, mode: FileMode.append);
      accomplishedBytes += chunk.length;
      args.sendPort.send(accomplishedBytes/args.endBytes);
    }, onDone: () {
      // send complete message to main iso, close resource
      toDownloadPort.close();
      args.sendPort!.send('completed');
      Isolate.current.kill(priority: Isolate.immediate);
    });


  }


  Future<File> openFile(int startPos, String path) async {
    if (startPos != 0)
      return File('${path}/${fileName}');

    // open a brand new file
    File f = File('${path}/${fileName}');
    deleteFile(f);
    await f.create();
    return f;
  }

  void deleteFile(File f) async {
    if (await f.exists()){
      await f.delete();
    }
  }

  void cancelDownload(void Function(double val) updateFunc) async{
    final destDir = await getApplicationDocumentsDirectory();
    File f = File('${destDir.path}/${fileName}');
    deleteFile(f);
    downloadedBytes = 0;
    totalBytes = 0;
    updateFunc(0);
  }

  void newDownload(String fileURL, void Function(double val) updateFunc) async {
    downloadedBytes = 0;
    totalBytes = 0;
    downloadFile(TEST_URL, updateFunc);
  }

  void resumeDownload(String fileURL, void Function(double val) updateFunc) async {
    downloadFile(TEST_URL, updateFunc);
  }


  void pauseDownload(){
    if (_toDownloadPort != null){
      _toDownloadPort!.send('pause');
    }
  }

  void completeDownload(){
    // do some finish process
    downloadedBytes = 0;
    totalBytes = 0;
    _downloadIsolate?.kill(priority: Isolate.immediate);
  }

}