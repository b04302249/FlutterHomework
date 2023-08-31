
import 'package:flutter/material.dart';
import 'package:homework/download_data.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'history_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DownloadHistories()),
        ChangeNotifierProvider(create: (context) => CurrentDownloadTarget()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        // "/": (context) => MyHomePage(title: "Http downloader"),
        "/history": (context) => const HistoryPage(),
      },
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'HTTP downloader'),
    );
  }
}
