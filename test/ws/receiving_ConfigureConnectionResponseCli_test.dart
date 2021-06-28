



import 'dart:convert';

import 'package:askless/askless.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:askless/src/middleware/receivements/ClientReceivedConfigureConnectionResponse.dart';
import 'package:askless/src/tasks/SendMessageToServerAgainTask.dart';
import 'package:test/test.dart';

void main(){
  Internal.instance.middleware = new Middleware('test');

  final getJson = () => jsonEncode(
      {
        'serverId': '#123',
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

  test('when receiving ConfigureConnectionResponseCli, Askless must be connected, ', (){
    ClientReceived.from(getJson()).handle();

    // expect(SendMessageToServerAgainTask().intervalInSeconds, 22);

    expect(AsklessClient.instance.connection, equals(Connection.CONNECTED_WITH_SUCCESS));
  });

}