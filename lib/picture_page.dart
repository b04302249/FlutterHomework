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
            child: generatePageItem(histories.getByIndex(index)),
          );
        },
      ),
    );
  }


  @override
  void dispose() {
    super.dispose();
    ImageCache cache = PaintingBinding.instance!.imageCache;
    cache.clear();
  }

  Widget generatePageItem(DownloadHistory? history) {
    if (history == null){
      return const Icon(Icons.insert_drive_file, size: 80, color: Colors.yellow,);
    }
    switch (history.fileType) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        if (history.status != DownloadStatus.completed){
          return Icon(Icons.image, size: 80, color: Colors.yellow,);
        }
        File file = File('${history.fileDir}/${history.fileName}');
        return Image.file(file, fit: BoxFit.cover,);
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, size: 80, color: Colors.yellow,);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, size: 80, color: Colors.yellow,);
      case 'txt':
        return const Icon(Icons.text_fields, size: 80, color: Colors.yellow,);
      default:
        return const Icon(Icons.insert_drive_file, size: 80, color: Colors.yellow,);
    }
  }
}