import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:askless/askless.dart';

import 'TrackingApp.dart';

final String ipv4Address = '192.168.2.7';
final serverUrl = 'ws://'+ipv4Address+':3000';

void main() {
  AsklessClient.instance.init(
      serverUrl: serverUrl,
      projectName: 'tracking-ts'
  );
  AsklessClient.instance.connect();
  runApp(TrackingApp());
}

