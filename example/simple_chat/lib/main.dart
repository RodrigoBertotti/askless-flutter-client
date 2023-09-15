import 'package:flutter/material.dart';
import 'package:askless/index.dart';
import 'signin_page.dart';


const serverUrl = ''; // TODO: <-- replace with your nodejs backend URL here like:
// const serverUrl = 'ws://192.168.0.8:3000';

void main() {
  assert(serverUrl.isNotEmpty, "replace \"serverUrl\" with your nodejs backend URL like: 'ws://192.168.0.8:3000'");

  AsklessClient.instance.start(
      serverUrl: serverUrl,
      debugLogs: !isProduction, // DO NOT DO SHOW ASKLESS LOGS ON THE CONSOLE ON A PRODUCTION ENVIRONMENT
  );

  runApp(const ChatApp());
}

const isProduction = false;

class ChatApp extends StatelessWidget {

  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat',
      debugShowCheckedModeBanner: false,
      home: SignInPage(),
    );
  }
}

