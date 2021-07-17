


import 'dart:convert';

import 'package:askless/askless.dart';
import 'package:askless/src/constants.dart';
import 'package:askless/src/dependency_injection/index.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';
import 'package:askless/src/middleware/data/request/ClientConfirmReceiptCli.dart';
import 'package:askless/src/middleware/data/request/ConfigureConnectionRequestCli.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/ws_channel/AbstractIOWsChannel.dart';
import 'package:askless/src/middleware/ws_channel/FakeIOWsChannel.dart';
import 'package:test/scaffolding.dart';



ConnectionConfiguration getNewConnectionConfiguration() {
  return new ConnectionConfiguration(
    clientVersionCodeSupported: new ClientVersionCodeSupported(
      lessThanOrEqual: CLIENT_LIBRARY_VERSION_CODE,
      moreThanOrEqual: CLIENT_LIBRARY_VERSION_CODE,
    ),
    projectName: 'unit tests',
    serverVersion: '...',
    disconnectClientAfterSecondsWithoutClientPing: 10,
    intervalInSecondsClientPing: 10,
    intervalInSecondsClientSendSameMessage: 10,
    intervalInSecondsServerSendSameMessage: 10,
    isFromServer: true,
    reconnectClientAfterSecondsWithoutServerPong: 10,
    requestTimeoutInSeconds: 10,
  );
}

Map<String,dynamic> getConfigureConnectionResponseCliMap({int? lessThanOrEqual, int? moreThanOrEqual}){
  return {
    'intervalInSecondsServerSendSameMessage': 1,
    'intervalInSecondsClientSendSameMessage': 1,
    'intervalInSecondsClientPing': '1',
    'reconnectClientAfterSecondsWithoutServerPong': 1,
    'isFromServer': true,
    'serverVersion': '1.1.1',
    'clientVersionCodeSupported': {
      'lessThanOrEqual': lessThanOrEqual,
      'moreThanOrEqual': moreThanOrEqual,
    },
    'projectName': null,
    'requestTimeoutInSeconds': 1,
    'disconnectClientAfterSecondsWithoutClientPing': 1,
  };
}

configureConnectionResponseMap () => jsonEncode(
    {
      'clientRequestId': 'clientRequestIdConfigureConnectionResponseMap',
      'serverId': 'serverId#123',
      '_class_type_configureconnection': '_',
      'output': {
        'intervalInSecondsServerSendSameMessage': 11,
        'intervalInSecondsClientSendSameMessage': 22,
        'intervalInSecondsClientPing': 33,
        'reconnectClientAfterSecondsWithoutServerPong': 44,
        'isFromServer': true,
        'serverVersion': "1.0.0",
        'clientVersionCodeSupported': {
          'lessThanOrEqual': 1000,
          'moreThanOrEqual': 1,
        },
        'projectName': 'project',
        'requestTimeoutInSeconds': 55,
        'disconnectClientAfterSecondsWithoutClientPing': 66,
      }
    }
);
