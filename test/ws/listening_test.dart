import 'dart:async';
import 'package:askless/askless.dart';
import 'package:askless/src/dependency_injection/index.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/receivements/AbstractServerData.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:askless/src/middleware/ws_channel/FakeIOWsChannel.dart';
import 'package:test/test.dart';

void main() {

  group('listening_test', () {
    setUpAll(() async {
      configureDependencies('test'); //First of all, to avoid problems with configureDependencies('prod');
      noTasks = true;
      FakeIOWsChannel.configure();
      AsklessClient.instance.init(serverUrl: 'wss://example.com/app');
      FakeIOWsChannel.configure(simulateServerConfirmReceiptParam: true, simulateServerSendConnectionConfigurationAsResponseOfConnectionRequestParam: true);
      await AsklessClient.instance.connect();
    });

    tearDown(() async {
      Internal.instance.reset();
      FakeIOWsChannel.reset();
      FakeIOWsChannel.configure(simulateServerConfirmReceiptParam: true, simulateServerSendConnectionConfigurationAsResponseOfConnectionRequestParam: true);
      AsklessClient.instance.init(serverUrl: 'wss://example.com/app');
      await AsklessClient.instance.connect();
    });


    test('Client should ignore repeated listen data with the same serverId', () async {
      FakeIOWsChannel.configure(
        simulateServerConfirmReceiptParam: true,
        simulateServerResponseWithOutputParam: (request, outputCallback) {
          print('-------------- simulateServerResponseWithOutput_ ' +
              request.clientRequestId + '  ' + request.requestType.toString());
          outputCallback(null);
        },
      );
      print('sending listen request...');
      final listening = AsklessClient.instance.listen(route: '/abc', query: {});
      print('listen request sent: ' + listening.clientRequestId);
      List<int> results = [];

      Completer<List<int>> completer = new Completer();
      listening.stream.listen((element) {
        print('listen: ' + element.output.toString());
        results.add(element.output);
        if (results.length == 3) {
          completer.complete(results);
        }
      });
      _newListenData(listening.listenId, 1, 'serverId1'); //repeated
      _newListenData(listening.listenId, 2, 'serverId1'); //repeated
      _newListenData(listening.listenId, 3, 'serverId1'); //repeated
      _newListenData(listening.listenId, 4, 'serverId2');
      _newListenData(listening.listenId, 5, 'serverId3');


      expect((await completer.future).length, 3); //5 (total) - 2 (repeated)
      expect(results[0], equals(1));
      expect(results[1], equals(4));
      expect(results[2], equals(5));

      print('...listen data received');
      // }

      // assert(arrayWithDifferentDataLoop.length == 0);
    });

    test('identical listeners: several requests should be grouped together in the client side, so the server receives only one listen request', () async {

      FakeIOWsChannel.configure(
        simulateServerConfirmReceiptParam: true,
        simulateServerResponseWithOutputParam: (request, outputCallback) {
          print('-------------- simulateServerResponseWithOutput_ ' + request.clientRequestId + '  ' + request.requestType.toString());
          outputCallback(null);
        },
      );

      final listening1a = AsklessClient.instance.listen(route: '/abc', query: {'test': 231});
      final listening1b = AsklessClient.instance.listen(route: '/abc', query: {'test': 231});
      final listening1c = AsklessClient.instance.listen(route: '/abc', query: {'test': 231});
      final listening2a = AsklessClient.instance.listen(route: '/abc', query: {'test': 21});
      final listening2b = AsklessClient.instance.listen(route: '/abc', query: {'test': 21});
      final listening3a = AsklessClient.instance.listen(route: '/abcd', query: {'test': 231});
      final listening3b = AsklessClient.instance.listen(route: '/abcd', query: {'test': 231});

      expect(Internal.instance.middleware!.listeningTo.length, equals(3));

      expect(listening1a.listenId, equals(listening1b.listenId));
      expect(listening1b.listenId, equals(listening1c.listenId));
      expect(listening1c.listenId, isNot(equals(listening2a.listenId)));
      expect(listening1c.listenId, isNot(equals(listening3a.listenId)));
      expect(listening2a.listenId, equals(listening2b.listenId));
      expect(listening3a.listenId, equals(listening3b.listenId));
      expect(listening2b.listenId, isNot(equals(listening3a.listenId)));


      Completer<int> completer1b = new Completer();
      Completer<int> completer1c = new Completer();
      Completer<int> completer2c = new Completer();
      Completer<int> completer3b = new Completer();

      listening1b.stream.listen((element) {completer1b.complete(element.output);});
      listening1c.stream.listen((element) {completer1c.complete(element.output);});
      listening2b.stream.listen((element) {completer2c.complete(element.output);});
      listening3b.stream.listen((element) {completer3b.complete(element.output);});

      _newListenData(listening1a.listenId, 1, 'serverId1');
      _newListenData(listening2a.listenId, 2, 'serverId2');
      _newListenData(listening3a.listenId, 3, 'serverId3');

      expect(await completer1b.future, 1);
      expect(await completer1c.future, 1);
      expect(await completer2c.future, 2);
      expect(await completer3b.future, 3);
    });

    test('identical listeners: the client should stop listening from the server when it no longer needs', () async {

      FakeIOWsChannel.configure(
        simulateServerConfirmReceiptParam: true,
        simulateServerResponseWithOutputParam: (request, outputCallback) {
          print('-------------- simulateServerResponseWithOutput_ ' + request.clientRequestId + '  ' + request.requestType.toString());
          outputCallback(null);
        },
      );

      final listening1a = AsklessClient.instance.listen(route: '/abc', query: {'test': 'test'});
      final listening1b = AsklessClient.instance.listen(route: '/abc', query: {'test': 'test'});
      expect(listening1a.clientRequestId, equals(listening1b.clientRequestId));
      expect(Internal.instance.middleware!.listeningTo.length, equals(1));

      listening1a.close();
      _newListenData(listening1a.listenId, 1, 'serverId1');

      expect((await listening1b.stream.first).output, equals(1));

      listening1b.close();
      _newListenData(listening1a.listenId, 2, 'serverId1');
      try{
        expect((await listening1b.stream.first).output, equals(2));
      }catch(e){
        expect(e.toString(), contains('Bad state'));
      }

      expect(Internal.instance.middleware!.listeningTo.length, equals(0));

      final listening2a = AsklessClient.instance.listen(route: '/abc', query: {'test': 'test'});
      expect(listening2a.clientRequestId, isNot(equals(listening1a.clientRequestId)));
    });

  });

}

void _newListenData(String listenId, output, String serverId) {
  print('simulating server sending data in realtime, listenId:'+listenId);
  new ClientReceived.from({
    AbstractServerData.srvServerId: serverId,
    NewDataForListener.type: '_',
    'listenId': listenId,
    'output': output
  }).handle();
}