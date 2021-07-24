



import 'dart:async';

import 'package:askless/askless.dart';
import 'package:askless/src/constants.dart';
import 'package:askless/src/dependency_injection/index.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/ws_channel/FakeIOWsChannel.dart';
import 'package:askless/src/tasks/SendMessageToServerAgainTask.dart';
import 'package:test/test.dart';
import 'package:collection/collection.dart';


void main (){

  group('send_message_to_server_again_task', (){

    setUpAll(() async {
      configureDependencies('test'); //First of all, to avoid problems with configureDependencies('prod');
      noTasks = true;
      FakeIOWsChannel.configure(simulateServerConfirmReceiptParam: true, simulateServerSendConnectionConfigurationAsResponseOfConnectionRequestParam: true,);
      AsklessClient.instance.init(serverUrl: 'wss://example.com/app');
      await AsklessClient.instance.connect();
    });

    tearDown(() async {
      Internal.instance.reset();
      FakeIOWsChannel.reset();
      FakeIOWsChannel.configure(simulateServerConfirmReceiptParam: true, simulateServerSendConnectionConfigurationAsResponseOfConnectionRequestParam: true,);
      AsklessClient.instance.init(serverUrl: 'wss://example.com/app');
      await AsklessClient.instance.connect();
    });

    test('should send data again by using SendMessageToServerAgainTask', () async {
      int sendingDataCounter = 0;
      final completer = new Completer<int>();

      FakeIOWsChannel.configure(
        simulateServerConfirmReceiptParam: false, //<--
        simulateServerResponseWithOutputParam: (request, outputCallback) {
          if(request.requestType != RequestType.CREATE){
            outputCallback('');
            return;
          }

          print('client tried to send data: '+(request as CreateCli).route+'  '+request.clientRequestId + '  '+ request.requestType.toString());

          if(request.route == '/abc'){
            sendingDataCounter++;
            if(sendingDataCounter > 1){
              completer.complete(sendingDataCounter);
            }else{
              new SendMessageToServerAgainTask().run();
            }
          }
        },
      );

      expect(AsklessClient.instance.connection, equals(Connection.CONNECTED_WITH_SUCCESS));

      expect(Internal.instance.middleware?.sendClientData.sendMessagesToServerAgain, isNotNull);

      AsklessClient.instance.create(route: '/abc', body: {});

      expect((await completer.future), equals(2));
    });

    test('serverReceived should be false, because the server sent the response', () async {

      FakeIOWsChannel.configure(
        simulateServerConfirmReceiptParam: true,
        simulateServerResponseWithOutputParam: (request, outputCallback) {
          outputCallback('');
        },
      );

      await AsklessClient.instance.update(route: '/abc', body: {});

      final pending = Internal.instance.middleware!
          .sendClientData
          .testGetPendingRequestsList
          .firstWhereOrNull((element) => !element.serverReceived);

      expect(pending, isNull);
    });

  });


}