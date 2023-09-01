import 'dart:collection';
import 'dart:core';

import 'package:flutter/cupertino.dart';


enum DownloadStatus{
  downloading,
  completed,
  pause,
  cancel,
}


class DownloadHistory {
  String fileType;
  String fileName;
  // not include file name
  String fileDir;
  String sourceUrl;
  DownloadStatus status;

  DownloadHistory(this.fileType, this.fileName, this.fileDir, this.sourceUrl, this.status);
}

class DownloadHistories extends ChangeNotifier {

  final histories = HashMap<String, DownloadHistory>();

  void addHistory(DownloadHistory history) {
    histories[history.fileName] = history;
    notifyListeners();
  }

  void changeStatusWithName(String name, DownloadStatus status){
    histories[name]!.status = status;
  }

  void changeStatus(DownloadHistory history){
    histories[history.fileName]!.status = history.status;
    notifyListeners();
  }

  int length() {
    return histories.length;
  }

  DownloadHistory? getByIndex(int index) {
    return histories[histories.keys.elementAt(index)];
  }

  DownloadHistory? getByName(String name){
    return histories[name];
  }

}

class CurrentDownloadTarget extends ChangeNotifier{
  String sourceUrl = "";
  String fileName = "";
  // downloadedBytes will only update when task pause or complete
  int downloadedBytes = 0;
  int totalBytes = 0;
  double progress = 0;

  void changeSourceUrl(String url){
    this.sourceUrl = url;
    notifyListeners();
  }

  void changeFileName(String name){
    this.fileName = name;
    notifyListeners();
  }

  void setDownloadedBytes(int val){
    this.downloadedBytes = val;
    notifyListeners();
  }

  void setTotalBytes(int val){
    this.totalBytes = val;
    notifyListeners();
  }

  void setProgress(double val){
    this.progress = val;
    notifyListeners();
  }

  void reset(){
    this.sourceUrl = "";
    this.fileName = "";
    this.downloadedBytes = 0;
    this.totalBytes = 0;
    this.progress = 0;
  }
}