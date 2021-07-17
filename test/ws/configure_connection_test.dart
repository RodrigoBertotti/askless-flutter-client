import 'dart:async';
import 'dart:convert';
import 'package:askless/askless.dart';
import 'package:askless/src/dependency_injection/index.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:askless/src/middleware/receivements/ClientReceivedConfigureConnectionResponse.dart';
import 'package:askless/src/middleware/ws_channel/AbstractIOWsChannel.dart';
import 'package:askless/src/middleware/ws_channel/FakeIOWsChannel.dart';
import 'package:askless/src/tasks/SendMessageToServerAgainTask.dart';
import 'package:test/test.dart';

import '../index.dart';

void main(){




  group('configure connection ',(){

    setUpAll((){
      configureDependencies('test'); //First of all, to avoid problems with configureDependencies('prod');
      // Internal.instance.middleware = new Middleware('test');
      AsklessClient.instance.init(serverUrl: 'wss://example.com/app');
    });

    tearDown((){
      Internal.instance.reset();
      FakeIOWsChannel.reset();
      AsklessClient.instance.init(serverUrl: 'wss://example.com/app');
    });

    test('askless connection status must be DISCONNECTED', (){
      expect(AsklessClient.instance.connection, equals(Connection.DISCONNECTED));
    });

    test('when receiving ConfigureConnectionResponseCli, Askless must be connected, ', (){
      FakeIOWsChannel.configure(serverResponseToConfigureConnectionRequestCli: (request){
        ClientReceived.from(configureConnectionResponseMap()).handle();
      });
      AsklessClient.instance.connect();
      expect(AsklessClient.instance.connection, equals(Connection.CONNECTED_WITH_SUCCESS));
      AsklessClient.instance.disconnect();
      expect(AsklessClient.instance.connection, equals(Connection.DISCONNECTED));
    });

    test('right after connect, askless connection status must be CONNECTION_IN_PROGRESS', (){
      AsklessClient.instance.connect();
      expect(AsklessClient.instance.connection, equals(Connection.CONNECTION_IN_PROGRESS));
      AsklessClient.instance.disconnect();
      expect(AsklessClient.instance.connection, equals(Connection.DISCONNECTED));
    });

    test('confirm to the server right after client receives data', () {
      final completerWithServerId = new Completer<String>();
      FakeIOWsChannel.configure(serverResponseToClientConfirmReceiptCli: (request){
        expect(request.serverId, equals('serverId#123'));
        completerWithServerId.complete(request.serverId);
      });
      AsklessClient.instance.connect();
      ClientReceived.from(configureConnectionResponseMap()).handle();

      expect(completerWithServerId.future, completion('serverId#123'));
    });

    // test('configure getIt AbstractIOWsChannel', (){
    //   expect(getIt.get<AbstractIOWsChannel>(param1: 'wss://example.com').serverUrl, equals('wss://example.com'));
    // });
    //
    // test('', (){
    //   fakeIOSChannel(serverResponseToConfigureConnectionRequestCli: (_){
    //
    //   });
    //   assert(fakeIOSChannel().serverResponseToConfigureConnectionRequestCli != null);
    //
    // });
  });

}