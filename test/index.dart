import 'package:askless/src/constants.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';



ConnectionConfiguration getNewConnectionConfiguration() {
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

Map<String,dynamic> getConfigureConnectionResponseCliMap({int? lessThanOrEqual, int? moreThanOrEqual}){
  return {
    'intervalInSecondsServerSendSameMessage': 1,
    'intervalInSecondsClientSendSameMessage': 1,
    'intervalInSecondsClientPing': '1',
    'reconnectClientAfterSecondsWithoutServerPong': 1,
    'isFromServer': true,
    'serverVersion': '1.1.1',
    'clientVersionCodeSupported': {
      'lessThanOrEqual': lessThanOrEqual,
      'moreThanOrEqual': moreThanOrEqual,
    },
    'projectName': null,
    'requestTimeoutInSeconds': 1,
    'disconnectClientAfterSecondsWithoutClientPing': 1,
  };
}




// void testClientReceivingDataFromServer(Map<String,dynamic> map, String suffix){
//   assert(map['serverId'] != null);
//
//   test('confirm to the server right after client receives data on '+suffix, () {
//     final completerWithServerId = new Completer<String>();
//     FakeIOWsChannel.configure(clientIsSendingClientConfirmReceiptCli: (request){
//       expect(request.serverId, equals(map[AbstractServerData.srvServerId]));
//       completerWithServerId.complete(request.serverId);
//     });
//     await AsklessClient.instance.connect();
//
//     ClientReceived.from(map).handle(); //simulate server sending data
//
//     expect(completerWithServerId.future, completion(map[AbstractServerData.srvServerId]));
//   });
// }

Map<String,dynamic> simulateResponseReceivedFromServer({String clientRequestId:'clientRequestId123'}) => {
  'serverId': '#123',
  '_class_type_response': '_',
  'clientRequestId': clientRequestId,
  'output': {
    'foo': 'boo'
  },
  'error': null,
};