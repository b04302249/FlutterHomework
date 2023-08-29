
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:async';

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


  Future<DownloadHistory> downloadFile(DownloadHistory history,
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
        print("set up _toDownloadPort: ${_toDownloadPort.hashCode}");
        print("current isolate(setup): ${Isolate.current.hashCode}");
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

    return history;
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
    File file = await openFile(args.startBytes, args.destPath, args.fileName);
    toDownloadPort.listen((message){
      if (message == 'pause'){
        args.sendPort.send('pause:$accomplishedBytes');
        print("closing toDownloadPort: ${toDownloadPort.sendPort.hashCode}");
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
      print("closing toDownloadPort: ${toDownloadPort.sendPort.hashCode}");
      args.sendPort.send('completed');
      Isolate.current.kill(priority: Isolate.immediate);
    });
  }

  void newDownload(DownloadHistories histories, String fileName, String sourceUrl,
      void Function(double val) updateFunc, void Function() finishFunc) async {
    downloadedBytes = 0;
    totalBytes = 0;
    String fileType = fileName.substring(fileName.lastIndexOf('.'));
    DownloadHistory history = DownloadHistory(fileType, fileName, sourceUrl, DownloadStatus.downloading);
    histories.addHistory(history);
    histories.changeStatus(await downloadFile(history, updateFunc, finishFunc));
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
      print("current isolate(pauseDownload): ${Isolate.current.hashCode}");
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
    histories.changeStatus(await downloadFile(history, updateFunc, finishFunc));
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

  Future<File> openFile(int startPos, String path, String fileName) async {
    if (startPos != 0) {
      return File('$path/$fileName');
    }

    // open a brand new file
    File f = File('$path/$fileName');
    deleteFile(f);
    await f.create();
    return f;
  }

  void deleteFile(File f) async {
    if (await f.exists()){
      await f.delete();
    }
  }
}