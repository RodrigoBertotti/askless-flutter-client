import 'package:askless/askless.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';

import '../../constants.dart';

class ClientReceivedConfigureConnectionResponse extends ClientReceived{

  ClientReceivedConfigureConnectionResponse(messageMap) : super(messageMap,true);


  @override
  void implementation() {
    final serverConnectionReadyCli = ConfigureConnectionResponseCli.fromMap(messageMap);
    Internal.instance.middleware.sendClientData.notifyServerResponse(serverConnectionReadyCli);
    connectionReady(serverConnectionReadyCli.connectionConfiguration, serverConnectionReadyCli.error);
  }

  void connectionReady(ConnectionConfiguration connectionConfiguration, RespondError error) {
    Internal.instance.logger(message: 'connectionReady');
    assert(connectionConfiguration!=null);

    Internal.instance.middleware.connectionConfiguration = connectionConfiguration;

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
    if ((connectionConfiguration.clientVersionCodeSupported.moreThanOrEqual !=
        null &&
        CLIENT_LIBRARY_VERSION_CODE <
            connectionConfiguration
                .clientVersionCodeSupported.moreThanOrEqual) ||
        (connectionConfiguration.clientVersionCodeSupported.lessThanOrEqual !=
            null &&
            CLIENT_LIBRARY_VERSION_CODE >
                connectionConfiguration
                    .clientVersionCodeSupported.lessThanOrEqual)) {
      Internal.instance.middleware.disconnectAndClear();
      Internal.instance.disconnectionReason = DisconnectionReason.VERSION_CODE_NOT_SUPPORTED;
      throw "Check if you server and client are updated! Your Askless version on server is ${connectionConfiguration.serverVersion}. Your Askless client version is ${CLIENT_LIBRARY_VERSION_NAME}";
    }

    if (AsklessClient.instance.projectName != null &&
        connectionConfiguration.projectName != null &&
        AsklessClient.instance.projectName !=
            connectionConfiguration.projectName) {
      Internal.instance.middleware.disconnectAndClear();
      Internal.instance.disconnectionReason = DisconnectionReason.WRONG_PROJECT_NAME;
      throw "Looks like you are not running the right server (" +
          connectionConfiguration.projectName +
          ") to your Flutter Client project (" +
          AsklessClient.instance.projectName +
          ")";
    }
  }

}