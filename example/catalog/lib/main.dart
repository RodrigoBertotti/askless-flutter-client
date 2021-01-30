import 'package:askless/askless.dart';
import 'package:flutter/material.dart';
import 'CatalogMainPage.dart';


final String ipv4Address = '192.168.2.6';
final serverUrl = 'ws://'+ipv4Address+':3000';


void main() {
  runApp(CatalogApp());
}


class CatalogApp extends StatelessWidget {

  CatalogApp() {
    final _customLogger = (String message, Level level, {additionalData}) {
      final PREFIX = "> CatalogApp ["
          +level.toString().toUpperCase().substring(6)
          +"]: ";
      print(PREFIX+message);
      if(additionalData!=null)
        print(additionalData.toString());
    };

    AsklessClient.instance.init(serverUrl: serverUrl, logger: Logger(useDefaultLogger: false, customLogger: _customLogger), projectName: 'catalog-javascript-client');
    AsklessClient.instance.connect();

  }

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
