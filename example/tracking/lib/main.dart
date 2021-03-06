import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:askless/askless.dart';

import 'TrackingApp.dart';

final serverUrl = 'ws://192.168.2.4:3000';

void main() {
  AsklessClient.instance.init(
    serverUrl: serverUrl,
    projectName: 'tracking-ts',
  );
  AsklessClient.instance.connect();
  runApp(TrackingApp());
}

