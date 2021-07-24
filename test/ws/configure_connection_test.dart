import 'package:askless/askless.dart';
import 'package:askless/src/dependency_injection/index.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/ws_channel/FakeIOWsChannel.dart';
import 'package:test/test.dart';


_configure (){
  if(!dependenciesHasBeenConfigured)
    configureDependencies('test');
  Internal.instance.reset();
  FakeIOWsChannel.reset();
  FakeIOWsChannel.configure(simulateServerConfirmReceiptParam: true, simulateServerSendConnectionConfigurationAsResponseOfConnectionRequestParam: true,);
  AsklessClient.instance.init(serverUrl: 'wss://example.com/app');
}

void main(){

  group('configure_connection_test',(){

    setUpAll( _configure);
    tearDown(_configure);

    test('askless connection status must be DISCONNECTED', (){
      expect(AsklessClient.instance.connection, equals(Connection.DISCONNECTED));
    });

    test('when receiving ConfigureConnectionResponseCli, Askless must be connected, ', () async {
      await AsklessClient.instance.connect();
      expect(AsklessClient.instance.connection, equals(Connection.CONNECTED_WITH_SUCCESS));
      AsklessClient.instance.disconnect();
      expect(AsklessClient.instance.connection, equals(Connection.DISCONNECTED));
    });

    test('right after connect, askless connection status must be CONNECTION_IN_PROGRESS', () async {
      FakeIOWsChannel.configure(simulateServerSendConnectionConfigurationAsResponseOfConnectionRequestParam: false, );
      AsklessClient.instance.connect();
      expect(AsklessClient.instance.connection, equals(Connection.CONNECTION_IN_PROGRESS));
      AsklessClient.instance.disconnect();
      expect(AsklessClient.instance.connection, equals(Connection.DISCONNECTED));
    });
  });

}