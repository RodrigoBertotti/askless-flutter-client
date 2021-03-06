import 'package:flutter/material.dart';
import 'package:askless/askless.dart';

import 'SignInPage.dart';

final String ipv4Address = '192.168.2.1';
final serverUrl = 'ws://'+ipv4Address+':3000';

void main() {
  runApp(ChatApp());
}

const isProduction = false;

class ChatApp extends StatelessWidget {

  ChatApp(){
    AsklessClient.instance.init(
        serverUrl: serverUrl,
        logger: Logger(
            useDefaultLogger: !isProduction // DO NOT DO SHOW ASKLESS LOGS ON THE CONSOLE ON A PRODUCTION ENVIRONMENT
        ),
        projectName: 'chat-js'
    );
    AsklessClient.instance.connect();
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Chat',
      debugShowCheckedModeBanner: false,
      home: SignInPage(),
    );
  }
}

