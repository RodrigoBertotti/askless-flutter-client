import 'package:flutter/material.dart';
import 'package:askless/index.dart';
import 'random_numbers_app.dart';

const serverUrl = ''; // TODO: <-- replace with your nodejs backend URL here like:
// const serverUrl = 'ws://192.168.0.8:3000';

void main() {
  assert(serverUrl.isNotEmpty, "replace \"serverUrl\" with your nodejs backend URL like: 'ws://192.168.0.8:3000'");
  AsklessClient.instance.start(serverUrl: serverUrl, debugLogs: false);
  runApp(const RandomNumbersApp());
}

