import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'download_history.dart';
import 'icon_helper.dart';
import 'side_bar.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {


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
          return GridTile(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  IconHelper.getIconForExtension(histories.getByIndex(index)!.fileType),
                  size: 50.0,
                  color: Colors.yellow,
                ),
                const SizedBox(height: 8), // Add spacing between icon and text
                Text(
                  histories.getByIndex(index)!.fileName, // Replace with the text you want to show
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "(${histories.getByIndex(index)!.status.name})", // Replace with the text you want to show
                  style: const TextStyle(fontSize: 8),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
