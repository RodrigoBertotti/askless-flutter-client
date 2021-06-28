import 'package:askless/src/constants.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import 'package:askless/src/middleware/receivements/ClientReceivedConfigureConnectionResponse.dart';
import 'package:test/test.dart';

ConnectionConfiguration get getNewConnectionConfiguration {
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

void main() {
  Internal.instance.middleware = new Middleware('test');

  test('checkIfIsNeededToStopConnectionFromBeingEstablished should fail because of lessThanOrEqual', () {
    Internal.instance.middleware.connectionConfiguration = getNewConnectionConfiguration;
    Internal.instance.middleware.connectionConfiguration.clientVersionCodeSupported.lessThanOrEqual--;

    String error;
    try{
      new ClientReceivedConfigureConnectionResponse({}).checkIfIsNeededToStopConnectionFromBeingEstablished(
          Internal.instance.middleware.connectionConfiguration
      );
    }catch(e){
      error = e.toString();
    }
    expect(error, contains('Check if you server and client are updated!'));
  });


  test('checkIfIsNeededToStopConnectionFromBeingEstablished should fail because of moreThanOrEqual', () {
    Internal.instance.middleware.connectionConfiguration = getNewConnectionConfiguration;
    Internal.instance.middleware.connectionConfiguration.clientVersionCodeSupported.moreThanOrEqual++;

    String error;
    try{
      new ClientReceivedConfigureConnectionResponse({}).checkIfIsNeededToStopConnectionFromBeingEstablished(
          Internal.instance.middleware.connectionConfiguration
      );
    }catch(e){
      error = e.toString();
    }
    expect(error, contains('Check if you server and client are updated!'));
  });

  test('checkIfIsNeededToStopConnectionFromBeingEstablished should work without error', () {
    Internal.instance.middleware.connectionConfiguration = getNewConnectionConfiguration;

    String error;
    try{
      new ClientReceivedConfigureConnectionResponse({}).checkIfIsNeededToStopConnectionFromBeingEstablished(
          Internal.instance.middleware.connectionConfiguration
      );
    }catch(e){
      error = e.toString();
    }
    expect(error, isNull);
  });


}