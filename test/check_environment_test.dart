import 'package:askless/src/constants.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import 'package:askless/src/middleware/receivements/ClientReceivedConfigureConnectionResponse.dart';
import 'package:test/test.dart';

import 'index.dart';



void main() {
  Internal.instance.middleware = new Middleware('test');

  test('checkIfIsNeededToStopConnectionFromBeingEstablished should fail because of lessThanOrEqual', () {
    Internal.instance.middleware!.connectionConfiguration = getNewConnectionConfiguration();
    Internal.instance.middleware!.connectionConfiguration.clientVersionCodeSupported.lessThanOrEqual = Internal.instance.middleware!.connectionConfiguration.clientVersionCodeSupported.lessThanOrEqual! - 1;


    String? error;
    try{
      new ClientReceivedConfigureConnectionResponse(getConfigureConnectionResponseCliMap()).checkIfIsNeededToStopConnectionFromBeingEstablished(
          Internal.instance.middleware!.connectionConfiguration
      );
    }catch(e){
      error = e.toString();
    }
    expect(error, contains('Check if you server and client are updated!'));
  });

  test('checkIfIsNeededToStopConnectionFromBeingEstablished should fail because of moreThanOrEqual', () {
    Internal.instance.middleware!.connectionConfiguration = getNewConnectionConfiguration();
    Internal.instance.middleware!.connectionConfiguration.clientVersionCodeSupported.moreThanOrEqual = Internal.instance.middleware!.connectionConfiguration.clientVersionCodeSupported.moreThanOrEqual! + 1;

    String? error;
    try{
      new ClientReceivedConfigureConnectionResponse(getConfigureConnectionResponseCliMap()).checkIfIsNeededToStopConnectionFromBeingEstablished(
          Internal.instance.middleware!.connectionConfiguration
      );
    }catch(e){
      error = e.toString();
    }
    expect(error, contains('Check if you server and client are updated!'));
  });

  test('checkIfIsNeededToStopConnectionFromBeingEstablished should work without error', () {
    Internal.instance.middleware!.connectionConfiguration = getNewConnectionConfiguration();

    String? error;
    try{
      new ClientReceivedConfigureConnectionResponse(getConfigureConnectionResponseCliMap()).checkIfIsNeededToStopConnectionFromBeingEstablished(
          Internal.instance.middleware!.connectionConfiguration
      );
    }catch(e){
      error = e.toString();
    }
    expect(error, isNull);
  });


}