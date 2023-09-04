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
  bool isScaling = false;

  void setScale(bool state){
    setState(() {
      isScaling = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    DownloadHistories histories = Provider.of<DownloadHistories>(context);
    TransformationController transform = TransformationController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Image Viewer'),
      ),
      body: InteractiveViewer(
        transformationController: transform,
        boundaryMargin: EdgeInsets.all(double.infinity),
        child: PageView.builder(
          itemCount: histories.length(),
          physics: isScaling ? NeverScrollableScrollPhysics():PageScrollPhysics(),
          itemBuilder: (context, index) {
            return Center(
              child: GestureDetector(
                onDoubleTapDown: (details) => handleDoubleTap(details, transform),
                onScaleStart: (_) {
                  setScale(true);
                },
                onScaleEnd: (_) {
                  setScale(false);
                },
                child: generatePageItem(histories.getByIndex(index)),
              ),
            );
          },
        ),
      ),
    );
  }

  void handleDoubleTap(TapDownDetails details, TransformationController transform){
    if (transform.value != Matrix4.identity()){
      transform.value = Matrix4.identity();
    }else{
      final position = details.localPosition;
      transform.value = Matrix4.identity()
        ..translate((-position.dx) * 1.5, (-position.dy) * 4)
        ..scale(2.0);
    }
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