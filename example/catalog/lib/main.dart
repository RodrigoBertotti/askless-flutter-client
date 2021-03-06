import 'package:askless/askless.dart';
import 'package:flutter/material.dart';
import 'CatalogMainPage.dart';


final String ipv4Address = '192.168.2.1';
final serverUrl = 'ws://'+ipv4Address+':3000';


void main() {
  runApp(CatalogApp());
}

const isProduction = false;

class CatalogApp extends StatelessWidget {

  CatalogApp() {

    //IMPORTANT: DO NOT DO THIS IN PRODUCTION:
    final _debugCustomLogger = (String message, Level level, {additionalData}) {
      final PREFIX = "> CatalogApp ["
          +level.toString().toUpperCase().substring(6)
          +"]: ";
      print(PREFIX+message);
      if(additionalData!=null)
        print(additionalData.toString());
    };

    AsklessClient.instance.init(
        serverUrl: serverUrl,
        logger: Logger(
            customLogger: isProduction ? null : _debugCustomLogger // DO NOT DO SHOW ASKLESS LOGS ON THE CONSOLE ON A PRODUCTION ENVIRONMENT
        ),
        projectName: 'catalog'
    );
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
