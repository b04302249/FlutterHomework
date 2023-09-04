import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'download_data.dart';
import 'side_bar.dart';
import 'dart:io';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {


  @override
  void dispose() {
    super.dispose();
    ImageCache cache = PaintingBinding.instance.imageCache;
    cache.clear();
  }

  @override
  Widget build(BuildContext context) {
    DownloadHistories histories = Provider.of<DownloadHistories>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('GridView Example'),
      ),
      drawer: const SideBar(),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Number of columns in the grid
          crossAxisSpacing: 8, // Spacing between columns
          mainAxisSpacing: 8, // Spacing between rows
        ),
        itemCount: histories.length(),

        itemBuilder: (context, index) {
          return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/picture");
              },
              child: GridTile(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    generateGrid(histories.getByIndex(index)),
                    const SizedBox(height: 8), // Add spacing between icon and text
                    Text(
                      histories.getByIndex(index)!.fileName,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      "(${histories.getByIndex(index)!.status.name})",
                      style: const TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              )
          );
        },
      ),
    );
  }

  Widget generateGrid(DownloadHistory? history) {
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
        return SizedBox(width: 80, height: 80, child: Image.file(file, fit: BoxFit.fitHeight,),);
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


class HistoryPageConstants{
  static const int GRID_TILE_WIDTH = 50;
}
