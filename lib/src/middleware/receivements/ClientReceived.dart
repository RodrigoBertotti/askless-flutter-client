import 'dart:convert';

import 'package:askless/askless.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import 'package:askless/src/middleware/index.dart';
import 'package:askless/src/middleware/data/receivements/AbstractServerData.dart';
import 'package:askless/src/middleware/data/receivements/ServerConfirmReceiptCli.dart';
import 'package:askless/src/middleware/data/request/ClientConfirmReceiptCli.dart';
import 'package:askless/src/middleware/receivements/ClientReceivedConfigureConnectionResponse.dart';
import 'package:askless/src/middleware/receivements/ClientReceivedIgnore.dart';
import 'package:askless/src/middleware/receivements/ClientReceivedResponse.dart';
import 'package:askless/src/middleware/receivements/ClientReceivedServerConfirmReceipt.dart';
import 'ClientReceivedNewDataForListener.dart';



abstract class ClientReceived{
  final bool confirmToServerThatDataHasBeenReceived;
  final dynamic messageMap;

  ClientReceived(this.messageMap, this.confirmToServerThatDataHasBeenReceived){
    assert(messageMap!=null);
    assert(!(messageMap is String));
  }

  static int get startCheckingLastMessagesFromServerAfterSize => 100;

  factory ClientReceived.from(String data){
    if(data == 'pong' || data == 'welcome')
      return new ClientReceivedIgnore();

    final messageMap = jsonDecode(data);
    if(messageMap[AbstractServerData.srvServerId]==null)
      throw 'Unknown: '+messageMap;

    if(messageMap[ConfigureConnectionResponseCli.typeResponse]!=null)
      return new ClientReceivedConfigureConnectionResponse(messageMap);
    if(messageMap[ServerConfirmReceiptCli.typeResponse]!=null)
      return new ClientReceivedServerConfirmReceipt(messageMap);
    if(messageMap[NewDataForListener.type]!=null)
      return new ClientReceivedNewDataForListener(messageMap);
    if(messageMap[ResponseCli.type]!=null)
      return new ClientReceivedResponse(messageMap);

    throw "TODO: "+messageMap;
  }

  void implementation();
  
  void handle() async {
    final serverId = messageMap[AbstractServerData.srvServerId];

    if(!this.confirmToServerThatDataHasBeenReceived){
      this.implementation();
      return;
    }

    confirmReceiptToServer(serverId);

    final dataAlreadySentByServerBefore = Internal.instance.middleware.lastMessagesFromServer.firstWhere((m) => m.serverId == serverId, orElse: () => null);
    if(dataAlreadySentByServerBefore != null){
      Internal.instance.logger(message: "handle, data already received: " + serverId);
      dataAlreadySentByServerBefore.messageReceivedAtSinceEpoch = DateTime.now().millisecondsSinceEpoch;
      return;
    }

    Internal.instance.middleware.lastMessagesFromServer.add(new LastServerMessage(serverId));

    this.checkCleanOldMessagesFromServer();

    this.implementation();
  }

  void checkCleanOldMessagesFromServer({int removeCount:10}) {
    if(Internal.instance.middleware.lastMessagesFromServer.length > startCheckingLastMessagesFromServerAfterSize){
      Internal.instance.logger(message: "Start of removing old messages received from server... (total: "+(Internal.instance.middleware.lastMessagesFromServer.length.toString())+")");
      final List<LastServerMessage> remove = [];
      for(int i=Internal.instance.middleware.lastMessagesFromServer.length-1; i >= 0 && remove.length < removeCount; i--){
        final messageReceivedFromServer = Internal.instance.middleware.lastMessagesFromServer[i];
        if(messageReceivedFromServer.shouldBeRemoved) //keep received message for 10 minutes
          remove.add(messageReceivedFromServer);
      }
      remove.forEach((element) => Internal.instance.middleware.lastMessagesFromServer.remove(element));
      Internal.instance.logger(message: "...end of removing old messages received from server (removed: "+(remove.length.toString())+")");
    }
  }

  void confirmReceiptToServer(String serverId) {
    Internal.instance.logger(message: "confirmReceiptToServer " + serverId);

    if(Internal.instance.middleware.ws==null){
      Internal.instance.logger(message: "ws==null", level: Level.error);
    }
    Internal.instance.middleware.sinkAdd(jsonEncode(new ClientConfirmReceiptCli(serverId).toMap()));
  }
}



class LastServerMessage{
  int messageReceivedAtSinceEpoch = DateTime.now().millisecondsSinceEpoch;

  final String serverId;

  LastServerMessage(this.serverId);

  bool get shouldBeRemoved => messageReceivedAtSinceEpoch + keepLastMessagesFromServerWithinMs < DateTime.now().millisecondsSinceEpoch;
}