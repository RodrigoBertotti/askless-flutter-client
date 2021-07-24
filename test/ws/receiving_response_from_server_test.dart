import 'dart:async';
import 'package:askless/askless.dart';
import 'package:askless/src/dependency_injection/index.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/SendData.dart';
import 'package:askless/src/middleware/data/receivements/AbstractServerData.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:askless/src/middleware/ws_channel/FakeIOWsChannel.dart';
import 'package:test/test.dart';

Map<String,dynamic> _simulateMapReceivedFromServer({String clientRequestId:'clientRequestId123'}) => {
  'serverId': '#123',
  '_class_type_response': '_',
  'clientRequestId': clientRequestId,
  'output': {
    'foo': 'boo'
  },
  'error': null,
};

void main(){

  group('receiving_response_from_server_test', (){

    setUpAll((){
      configureDependencies('test'); //First of all, to avoid problems with configureDependencies('prod');
      AsklessClient.instance.init(serverUrl: 'wss://example.com/app');
      FakeIOWsChannel.configure(simulateServerConfirmReceiptParam: true,);
    });

    tearDown((){
      Internal.instance.reset();
      FakeIOWsChannel.reset();
      AsklessClient.instance.init(serverUrl: 'wss://example.com/app');
      FakeIOWsChannel.configure(simulateServerConfirmReceiptParam: true,);
    });


    test('ResponseCli should remove item from _pendingRequestsList and call the onResponse callback', () async {

      Internal.instance.middleware = new Middleware('test');

      final listenCli1 = new ListenCli(route: '/abcd1', query: {});
      final listenCli2 = new ListenCli(route: '/abcd2', query: {});
      final listenCli3 = new ListenCli(route: '/abcd3', query: {});

      Completer completer = new Completer();

      Internal.instance.middleware!.sendClientData.testAddPendingRequests(newTestRequest(listenCli3, (_){}));
      Internal.instance.middleware!.sendClientData.testAddPendingRequests(newTestRequest(listenCli2, (_){}));
      Internal.instance.middleware!.sendClientData.testAddPendingRequests(newTestRequest(listenCli1, (response){
        expect(Internal.instance.middleware!.sendClientData.testGetPendingRequestsList.length, equals(2));
        completer.complete();
      }));

      ClientReceived.from(_simulateMapReceivedFromServer(clientRequestId: listenCli1.clientRequestId)).handle();

      await completer.future;
    });

    test('confirm to the server right after client receives data', () async  {
      final _serverSentMap = _simulateMapReceivedFromServer();
      final completerWithServerId = new Completer<String>();
      FakeIOWsChannel.configure(clientIsSendingClientConfirmReceiptCli: (request){
        expect(request.serverId, equals(_serverSentMap[AbstractServerData.srvServerId]));
        completerWithServerId.complete(request.serverId);
      });

      AsklessClient.instance.connect();

      ClientReceived.from(_serverSentMap).handle(); //simulate server sending data

      expect(completerWithServerId.future, completion(_serverSentMap[AbstractServerData.srvServerId]));

    });

  });


  // expect(Internal.instance.middleware!.sendClientData.testGetPendingRequestsList.length, equals(..));

}