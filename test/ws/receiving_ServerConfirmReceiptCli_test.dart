import 'dart:convert';

import 'package:askless/askless.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/SendData.dart';
import 'package:askless/src/middleware/data/request/ConfigureConnectionRequestCli.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:askless/src/middleware/receivements/ClientReceivedServerConfirmReceipt.dart';
import 'package:test/test.dart';




void main(){
  Internal.instance.middleware = new Middleware('test');


  test('receiving ServerConfirmReceiptCli: pendingRequests should be set as serverReceived:true', (){
      final listenCli1 = new ListenCli(route: '/abcd1', query: {});
      final listenCli2 = new ListenCli(route: '/abcd2', query: {});

      Internal.instance.middleware!.sendClientData.testAddPendingRequests(newTestRequest(listenCli1, (_){}));
      Internal.instance.middleware!.sendClientData.testAddPendingRequests(newTestRequest(listenCli2, (_){}));

      ClientReceived.from(jsonEncode(
          {
            'serverId': '#123',
            '_class_type_serverconfirmreceipt': '_',
            'clientRequestId': listenCli1.clientRequestId,
            'output': null,
            'error': null,
          }
      )).handle();

      expect(Internal.instance.middleware!.sendClientData.testGetPendingRequestsList[0].serverReceived, equals(true));
      expect(Internal.instance.middleware!.sendClientData.testGetPendingRequestsList[1].serverReceived, equals(false));
  });
}