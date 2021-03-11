import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/Middleware.dart';
import 'package:askless/src/middleware/data/response/AbstractServerData.dart';
import 'package:askless/src/middleware/data/response/NewRealtimeData.dart';
import 'package:askless/src/middleware/data/response/ResponseCli.dart';
import 'package:askless/src/middleware/data/response/ConfigureConnectionResponseCli.dart';

import 'data/response/ServerConfirmReceiptCli.dart';


class LastServerMessage{
  int messageReceivedAtSinceEpoch = DateTime.now().microsecondsSinceEpoch;

  final String serverId;

  LastServerMessage(this.serverId);
}

class HandleReceive{
  final Middleware middleware;
  final lastMessagesFromServer = [];

  HandleReceive(this.middleware);

  void handle(messageMap) {
    if(messageMap[AbstractServerData.srvServerId]==null){
      throw 'Unknown: '+messageMap;
    }

    if(messageMap[ServerConfirmReceiptCli.typeResponse]!=null){
      final serverConfirmReceiptCli = ServerConfirmReceiptCli.fromMap(messageMap);
      middleware.sendClientData.setAsReceivedPendingMessageThatServerShouldReceive(serverConfirmReceiptCli.clientRequestId);
      return;
    }

    final serverId = messageMap[AbstractServerData.srvServerId];
    middleware.confirmReceiptToServer(serverId);

    final dataAlreadySentByServerBefore = lastMessagesFromServer.firstWhere((m) => m.serverId == serverId, orElse: () => null);
    if(dataAlreadySentByServerBefore != null){
      Internal.instance.logger(message: "handle, data already received: " + serverId);
      dataAlreadySentByServerBefore.messageReceivedAtSinceEpoch = DateTime.now().millisecondsSinceEpoch;
      return;
    }

    lastMessagesFromServer.add(new LastServerMessage(serverId));

    final NOW = DateTime.now().millisecondsSinceEpoch;
    if(lastMessagesFromServer.length > 100){
      Internal.instance.logger(message: "Start of removing old messages received from server... (total: "+(lastMessagesFromServer.length.toString())+")");
      final List<LastServerMessage> remove = [];
      for(int i=lastMessagesFromServer.length-1; i >= 0 && remove.length < 10; i--){
        final messageReceivedFromServer = lastMessagesFromServer[i];
        if(messageReceivedFromServer.messageReceivedAtSinceEpoch + 10 * 60 * 1000 < NOW) //keep received message for 10 minutes
          remove.add(messageReceivedFromServer);
      }
      remove.forEach((element) => lastMessagesFromServer.remove(element));
      Internal.instance.logger(message: "...end of removing old messages received from server (removed: "+(remove.length.toString())+")");
    }

    if(messageMap[NewDataForListener.type]!=null) {
      final listen = NewDataForListener.fromMap(messageMap);
      middleware.onNewData(listen);
    }
    else if(messageMap[ConfigureConnectionResponseCli.typeResponse]!=null) {
      final serverConnectionReadyCli = ConfigureConnectionResponseCli.fromMap(messageMap);
      middleware.sendClientData.notifyServerResponse(serverConnectionReadyCli);
      middleware.connectionReady(serverConnectionReadyCli.connectionConfiguration, serverConnectionReadyCli.error);
    }
    else if(messageMap[ResponseCli.type]!=null){
      final responseCli = ResponseCli.fromMap(messageMap);
      middleware.sendClientData.notifyServerResponse(responseCli);
    }
    else{
      throw messageMap;
    }
  }




}
