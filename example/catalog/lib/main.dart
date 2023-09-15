import 'package:flutter/material.dart';
import 'package:askless/index.dart';
import 'catalog_main_page.dart';


final serverUrl = ''; // TODO: <-- replace with your nodejs backend URL here like:
// const serverUrl = 'ws://192.168.0.8:3000';

void main() {
  assert(serverUrl.isNotEmpty, "replace \"serverUrl\" with your nodejs backend URL like: 'ws://192.168.0.8:3000'");
  AsklessClient.instance.start(
    serverUrl: serverUrl,
    debugLogs: false,
  );
  runApp(const CatalogApp());
}

class CatalogApp extends StatelessWidget {
  const CatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catalog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
      ),
      home: CatalogMainPage(),
    );
  }
}
