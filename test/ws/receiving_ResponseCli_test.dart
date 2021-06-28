


import 'dart:async';
import 'dart:convert';

import 'package:askless/askless.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/SendData.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:test/test.dart';

void main(){


  test('ResponseCli should remove item from _pendingRequestsList and call the onResponse callback', () async {

    Internal.instance.middleware = new Middleware('test');

    final listenCli1 = new ListenCli(route: '/abcd1', query: {});
    final listenCli2 = new ListenCli(route: '/abcd2', query: {});
    final listenCli3 = new ListenCli(route: '/abcd3', query: {});

    Completer completer = new Completer();

    Internal.instance.middleware.sendClientData.testAddPendingRequests(newTestRequest(listenCli3, (_){}));
    Internal.instance.middleware.sendClientData.testAddPendingRequests(newTestRequest(listenCli2, (_){}));
    Internal.instance.middleware.sendClientData.testAddPendingRequests(newTestRequest(listenCli1, (response){
      expect(Internal.instance.middleware.sendClientData.testGetPendingRequestsList.length, equals(2));
      completer.complete();
    }));

    ClientReceived.from(jsonEncode(
        {
          'serverId': '#123',
          '_class_type_response': '_',
          'clientRequestId': listenCli1.clientRequestId,
          'output': {
            'foo': 'boo'
          },
          'error': null,
        }
    )).handle();

    await completer.future;
  });

}