import 'dart:io';

import 'package:flutter/material.dart';
import 'download_data.dart';
import 'package:provider/provider.dart';


class PicturePage extends StatefulWidget {
  const PicturePage({super.key});

  @override
  _PicturePageState createState() => _PicturePageState();
}

class _PicturePageState extends State<PicturePage> {

  @override
  Widget build(BuildContext context) {
    DownloadHistories histories = Provider.of<DownloadHistories>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Image Viewer'),
      ),
      body: PageView.builder(
        itemCount: histories.length(),
        itemBuilder: (context, index) {
          return Center(
            child: Image.file(
              File('${histories.getByIndex(index)?.fileDir}/${histories.getByIndex(index)?.fileName}'),
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}