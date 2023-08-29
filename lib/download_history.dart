import 'dart:collection';

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
  String sourceUrl;
  DownloadStatus status;

  DownloadHistory(this.fileType, this.fileName, this.sourceUrl, this.status);
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