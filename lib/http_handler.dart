

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:async';

import 'download_data.dart';


class DownloadArgs {
  final SendPort sendPort;
  final String downloadUrl;
  final String destDir;
  final String fileName;
  final int startBytes;
  final int endBytes;

  DownloadArgs(this.sendPort, this.downloadUrl, this.destDir, this.fileName, this.startBytes,
      this.endBytes);
}


class HttpHandler{

  SendPort? _toDownloadPort;

  Future<bool> downloadFile(DownloadHistory history, CurrentDownloadTarget target) async {
    // get the information of totalBytes
    if (target.totalBytes == 0){
      final response = await http.head(Uri.parse(history.sourceUrl));
      String contentLen = '';
      if (response.headers['content-length'] != null) {
        contentLen = response.headers['content-length'].toString();
      }
      try{
        target.setTotalBytes(int.parse(contentLen));
      } catch(e){
        print("content-length is not a number!!");
      }
    }


    // create isolate and port
    final toMainPort = ReceivePort("toMainPort");
    Isolate.spawn(downloadRangeFile, DownloadArgs(
        toMainPort.sendPort,
        history.sourceUrl,
        history.fileDir,
        history.fileName,
        target.downloadedBytes,
        target.totalBytes)
    );

    // deal with communication between download iso and main iso
    toMainPort.listen( (message) {
      // handshake, build connection
      if (message is SendPort){
        _toDownloadPort = message;
      } else if (message is String){
        if (message == 'completed') {
          history.status = DownloadStatus.completed;
          target.reset();
          toMainPort.close();
          print("Download task completed!!");
        } else if (message.substring(0, 5) == 'pause'){
          // remember the progress current download, start from current progress next time
          target.setDownloadedBytes(int.parse(message.substring(6)));
          _toDownloadPort = null;
          toMainPort.close();
        }
      } else if (message is double){
        target.setProgress(message);
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
    print("accomplishedBytes: $accomplishedBytes");

    // download task
    final request = http.Request('Get', Uri.parse(args.downloadUrl));
    final rangeHeaderValue = 'bytes=${args.startBytes}-${args.endBytes}';
    request.headers['Range'] = rangeHeaderValue;
    final response = await request.send();
    print("get response, status code: ${response.statusCode}");


    // listen message from main to download, pause if necessary
    RandomAccessFile file = await openFile(args.startBytes, args.destDir, args.fileName);
    toDownloadPort.listen((message){
      if (message == 'pause') {
        args.sendPort.send('pause:$accomplishedBytes');
        cleanUp(iso: Isolate.current, receivePort: toDownloadPort, randomAccessFile: file);
      }else if (message == 'cancel'){
        cleanUp(iso: Isolate.current, receivePort: toDownloadPort, randomAccessFile: file);
        deleteFile(args.destDir, args.fileName);
      }
    });


    response.stream.listen((List<int> chunk) async {
      // await file.writeFrom(chunk, 0, chunk.length);
      file.writeFromSync(chunk, 0, chunk.length);
      accomplishedBytes += chunk.length;
      args.sendPort.send(accomplishedBytes/args.endBytes);
    }, onDone: () async {
      // send complete message to main iso, close resource
      args.sendPort.send('completed');
      cleanUp(iso: Isolate.current, receivePort: toDownloadPort, randomAccessFile: file);
    });
  }


  void newDownload(DownloadHistories histories, CurrentDownloadTarget target) async {
    if (target.totalBytes != 0 || target.downloadedBytes != 0){
      print("It looks like there already exist a download task! File name: ${target.fileName}");
    }
    String fileType = target.fileName.substring(target.fileName.lastIndexOf('.')+1);
    final destDir = await getApplicationDocumentsDirectory();
    DownloadHistory history = DownloadHistory(
        fileType,
        target.fileName,
        destDir.path,
        target.sourceUrl,
        DownloadStatus.downloading);
    histories.addHistory(history); // map, will not duplicate with same name
    // downloadFile(history, updateFunc, finishFunc);
    if(await downloadFile(history, target)){
      histories.changeStatusWithName(history.fileName, DownloadStatus.completed);
    }
  }

  void pauseDownload(DownloadHistories histories, String fileName) {
    DownloadHistory? history = histories.getByName(fileName);
    if (history == null){
      print("FileName: $fileName does not have any record, please press Start to create a new download!");
      return;
    }

    if (_toDownloadPort != null) {
      _toDownloadPort!.send('pause');
    }
    history.status = DownloadStatus.pause;
    histories.changeStatus(history);
  }

  void resumeDownload(DownloadHistories histories, CurrentDownloadTarget target) async {
    DownloadHistory? history = histories.getByName(target.fileName);
    if (history == null){
      print("FileName: ${target.fileName} does not have any record, please press Start to create a new download!");
      return;
    }
    history.status = DownloadStatus.downloading;
    histories.changeStatus(history);
    if(await downloadFile(history, target)){
      histories.changeStatusWithName(history.fileName, DownloadStatus.completed);
    }
  }

  /// ************************
  /// if the download isolate is still running, directly killing it will cause memory leak
  /// we need to pause download which will clean up the memory of download isolate
  ///***************************
  void cancelDownload(DownloadHistories histories, String fileName) async {
    DownloadHistory? history = histories.getByName(fileName);
    if (history == null){
      print("FileName: $fileName does not have any record, please press Start to create a new download!");
      return;
    }
    if (_toDownloadPort != null){
      // download iso executing, ask download iso to clean up
      _toDownloadPort!.send('cancel');
    }else{
      // no download iso executing, directly delete the file
      deleteFile(history.fileDir, fileName);
    }
    history.status = DownloadStatus.cancel;
    histories.changeStatus(history);
  }

  void cleanUp({Isolate? iso, ReceivePort? receivePort, RandomAccessFile? randomAccessFile}){
    if (randomAccessFile != null){
      randomAccessFile.close();
    }
    if (receivePort != null){
      receivePort.close();
    }
    if (iso != null){
      iso.kill(priority: Isolate.immediate);
    }
  }


  Future<RandomAccessFile> openFile(int startPos, String path, String fileName) async {
    File f = File('$path/$fileName');
    if (startPos != 0) {
      return f.open(mode: FileMode.append);
    }

    // open a brand new file
    await deleteFile(path, fileName, file: f);
    await f.create();
    return f.open(mode: FileMode.write);
    // return f;
  }

  Future<void> deleteFile(String path, String fileName, {File? file}) async {
    if (file != null && await file.exists()) {
      await file.delete();
      return;
    } else {
      File f = File('$path/$fileName');
      if (await f.exists()) {
        await f.delete();
      }
    }
  }
}