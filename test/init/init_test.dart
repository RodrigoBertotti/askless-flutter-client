

import 'dart:async';

import 'package:askless/askless.dart';
import 'package:askless/src/index.dart';
import 'package:test/test.dart';

void main(){
  test('init', (){
    String? _message;
    final logger = new Logger(customLogger: (String message, Level level, {additionalData}){
      _message = message;
    });
    final serverUrl = 'ws://example.com/test';
    final projectName = 'Example';
    AsklessClient.instance.init(
      serverUrl: serverUrl,
      projectName: projectName,
      logger: logger
    );

    expect(AsklessClient.instance.serverUrl, equals(serverUrl));
    expect(AsklessClient.instance.projectName, equals(projectName));
    Internal.instance.logger(message: '123');
    expect(_message, equals('123'));
  });

}