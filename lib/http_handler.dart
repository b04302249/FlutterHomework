
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:async';
import 'package:mutex/mutex.dart';

import 'download_history.dart';


class DownloadArgs {
  final SendPort sendPort;
  final String downloadUrl;
  final String destPath;
  final String fileName;
  final int startBytes;
  final int endBytes;

  DownloadArgs(this.sendPort, this.downloadUrl, this.destPath, this.fileName, this.startBytes,
      this.endBytes);
}


class HttpHandler{

  int downloadedBytes = 0;
  int totalBytes = 0;

  // final TEST_URL = 'https://www.africau.edu/images/default/sample.pdf';
  final TEST_URL = 'https://research.nhm.org/pdfs/10840/10840.pdf';
  // final TEST_URL = 'https://www.sampledocs.in/DownloadFiles/SampleFile?filename=sampledocs-100mb-pdf-file&ext=pdf';
  // final TEST_URL = 'https://drive.google.com/uc?id=1uQY0Mey2N8Xa_lCI6YFAb1_nFfrcsKpZ&export=download' ;
  Isolate? _downloadIsolate;
  SendPort? _toDownloadPort;

  // HttpHandler(this.histories);


  Future<bool> downloadFile(DownloadHistory history,
      void Function(double val) updateFunc, void Function() finishFunc) async {
    // get the information of totalBytes
    if (totalBytes == 0){
      final response = await http.head(Uri.parse(history.sourceUrl));
      String contentLen = '';
      if (response.headers['content-length'] != null) {
        contentLen = response.headers['content-length'].toString();
      }
      try{
        totalBytes = int.parse(contentLen);
      } catch(e){
        print("content-length is not a number!!");
      }
    }


    // create isolate and port
    final toMainPort = ReceivePort();
    final destDir = await getApplicationDocumentsDirectory();
    _downloadIsolate = await Isolate.spawn(downloadRangeFile,
        DownloadArgs(
            toMainPort.sendPort, history.sourceUrl, destDir.path, history.fileName, downloadedBytes,
            totalBytes));

    // deal with communication between download iso and main iso
    toMainPort.listen( (message) {
      // handshake, build connection
      if (message is SendPort){
        _toDownloadPort = message;
      } else if (message is String){
        if (message == 'completed') {
          completeDownload(history.fileName);
          history.status = DownloadStatus.completed;
          finishFunc();
          toMainPort.close();
          print("Download task completed!!");
        } else if (message.substring(0, 5) == 'pause'){
          // remember the progress current download, start from current progress next time
          downloadedBytes = int.parse(message.substring(6));
          print("pause request from download iso, downloadedBytes: $downloadedBytes");
        }
      } else if (message is double){
        updateFunc(message);
      }
    });

    if (history.status == DownloadStatus.completed){
      return true;
    }else{
      return false;
    }
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
    RandomAccessFile file = await openFile(args.startBytes, args.destPath, args.fileName);
    toDownloadPort.listen((message){
      if (message == 'pause'){
        args.sendPort.send('pause:$accomplishedBytes');
        file.close();
        toDownloadPort.close();
        Isolate.current.kill(priority: Isolate.immediate);
      }
    });
    int test_val = 0;
    int count = 0;
    Mutex m = Mutex();
    // accept chunks from response, don't have to close file, file will close once it finish
    response.stream.listen((List<int> chunk) async {
      // await file.writeAsBytes(chunk, mode: FileMode.append, flush: true);
      //file.writeAsBytesSync(chunk, mode: FileMode.append);
      // await m.protect(() async {
      //   // critical section
      //   await file.writeFrom(chunk, 0, chunk.length);
      //   test_val = await test_funct(test_val);
      // });
      count += 1;
      file.writeFromSync(chunk, 0, chunk.length);
      accomplishedBytes += chunk.length;
      args.sendPort.send(accomplishedBytes/args.endBytes);
    }, onDone: () {
      // send complete message to main iso, close resource
      file.close();
      print("count: $count, test_val: $test_val");
      toDownloadPort.close();
      args.sendPort.send('completed');
      Isolate.current.kill(priority: Isolate.immediate);
    });
  }

  Future<int> test_funct(int val) async {
    val += 1;
    Future.delayed(Duration(seconds: 1));
    return val;
  }

  void newDownload(DownloadHistories histories, String fileName, String sourceUrl,
      void Function(double val) updateFunc, void Function() finishFunc) async {
    downloadedBytes = 0;
    totalBytes = 0;
    String fileType = fileName.substring(fileName.lastIndexOf('.'));
    DownloadHistory history = DownloadHistory(fileType, fileName, sourceUrl, DownloadStatus.downloading);
    histories.addHistory(history);
    // downloadFile(history, updateFunc, finishFunc);
    if(await downloadFile(history, updateFunc, finishFunc)){
      histories.changeStatusWithName(history.fileName, DownloadStatus.completed);
    }
  }

  void pauseDownload(DownloadHistories histories, String fileName) {
    DownloadHistory? history = histories.getByName(fileName);
    if (history == null){
      print("FileName: $fileName does not have any record, please press Start to create a new download!");
      return;
    }
    history.status = DownloadStatus.pause;
    histories.changeStatus(history);

    if (_toDownloadPort == null){
      print("_toDownloadPort is null");
      print("current instance(pauseDownload): ${hashCode}");
    }

    if (_toDownloadPort != null) {
      _toDownloadPort!.send('pause');
    }
  }

  void resumeDownload(DownloadHistories histories, String fileName, String sourceUrl,
      void Function(double val) updateFunc, void Function() finishFunc) async {
    DownloadHistory? history = histories.getByName(fileName);
    if (history == null){
      print("FileName: $fileName does not have any record, please press Start to create a new download!");
      return;
    }
    history.status = DownloadStatus.downloading;
    histories.changeStatus(history);
    if(await downloadFile(history, updateFunc, finishFunc)){
      histories.changeStatusWithName(history.fileName, DownloadStatus.completed);
    }
  }

  void cancelDownload(DownloadHistories histories, String fileName) async{
    DownloadHistory? history = histories.getByName(fileName);
    if (history == null){
      print("FileName: $fileName does not have any record, please press Start to create a new download!");
      return;
    }
    history.status = DownloadStatus.cancel;
    histories.changeStatus(history);
    final destDir = await getApplicationDocumentsDirectory();
    File f = File('${destDir.path}/$fileName');
    deleteFile(f);
    downloadedBytes = 0;
    totalBytes = 0;
  }

  void completeDownload(String fileName) {
    // do some finish process
    downloadedBytes = 0;
    totalBytes = 0;
    // histories.changeStatusWithName(fileName, DownloadStatus.completed);
    _downloadIsolate?.kill(priority: Isolate.immediate);
  }

  Future<RandomAccessFile> openFile(int startPos, String path, String fileName) async {
    File f = File('$path/$fileName');
    if (startPos != 0) {
      return f.open(mode: FileMode.append);
    }

    // open a brand new file
    deleteFile(f);
    await f.create();
    return f.open(mode: FileMode.write);
    // return f;
  }

  void deleteFile(File f) async {
    if (await f.exists()){
      await f.delete();
    }
  }
}