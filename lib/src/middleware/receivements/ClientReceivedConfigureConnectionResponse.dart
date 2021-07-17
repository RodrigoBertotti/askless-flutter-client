import 'package:askless/askless.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';

import '../../constants.dart';
import 'package:collection/collection.dart';

class ClientReceivedConfigureConnectionResponse extends ClientReceived{

  ClientReceivedConfigureConnectionResponse(messageMap) : super(messageMap,true);


  @override
  void implementation() {
    final serverConnectionReadyCli = ConfigureConnectionResponseCli.fromMap(messageMap);
    Internal.instance.middleware!.sendClientData.notifyServerResponse(serverConnectionReadyCli);
    connectionReady(serverConnectionReadyCli.connectionConfiguration);
  }

  void connectionReady(ConnectionConfiguration connectionConfiguration) {
    Internal.instance.logger(message: 'connectionReady');

    Internal.instance.middleware!.connectionConfiguration = connectionConfiguration;

    checkIfIsNeededToStopConnectionFromBeingEstablished(connectionConfiguration);

    Internal.instance.sendPingTask
        .changeInterval(connectionConfiguration.intervalInSecondsClientPing);
    Internal.instance.reconnectWhenDidNotReceivePongFromServerTask
        .changeInterval(connectionConfiguration
        .reconnectClientAfterSecondsWithoutServerPong);

    Internal.instance.notifyConnectionChanged(Connection.CONNECTED_WITH_SUCCESS);

    Future.delayed(Duration(seconds: 1), (){
      Internal.instance.sendMessageToServerAgainTask.changeInterval(
          connectionConfiguration.intervalInSecondsClientSendSameMessage
      );
    });
  }


  checkIfIsNeededToStopConnectionFromBeingEstablished(ConnectionConfiguration connectionConfiguration) {
    if (connectionConfiguration.incompatibleVersion) {
      Internal.instance.middleware!.disconnectAndClear();
      Internal.instance.disconnectionReason = DisconnectionReason.VERSION_CODE_NOT_SUPPORTED;
      throw "Check if you server and client are updated! Your Askless version on server is ${connectionConfiguration.serverVersion}. Your Askless client version is ${CLIENT_LIBRARY_VERSION_NAME}";
    }

    if (connectionConfiguration.differentProjectName) {
      Internal.instance.middleware!.disconnectAndClear();
      Internal.instance.disconnectionReason = DisconnectionReason.WRONG_PROJECT_NAME;
      throw "Looks like you are not running the right server (" +
          (connectionConfiguration.projectName ?? 'null') +
          ") to your Flutter Client project (" +
          (AsklessClient.instance.projectName ?? 'null') +
          ")";
    }
  }

}