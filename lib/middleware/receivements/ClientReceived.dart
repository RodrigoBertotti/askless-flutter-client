import 'dart:convert';
import '../../../../../../injection_container.dart';
import '../../data/models/internal_response_model.dart';
import '../../domain/utils/logger.dart';
import '../data/receivements/NewDataForListener.dart';
import '../data/receivements/ServerConfirmReceiptCli.dart';
import '../data/receivements/StopListeningEvent.dart';
import '../data/request/ClientConfirmReceiptCli.dart';
import '../ws_channel/AbstractIOWsChannel.dart';
import 'ClientReceivedIgnore.dart';
import 'ClientReceivedNewDataForListener.dart';
import 'package:collection/collection.dart';

import 'ClientReceivedResponse.dart';
import 'ClientReceivedServerConfirmReceipt.dart';
import 'ClientReceivedStopListeningEvent.dart';


const int _keepLastMessagesFromServerWithinMs = 10 * 60 * 1000;

abstract class ClientReceived{
  final bool confirmToServerThatDataHasBeenReceived;
  final Map<String, dynamic> messageMap;
  final List<LastServerMessage> lastMessagesFromServer = [];

  ClientReceived(this.messageMap, this.confirmToServerThatDataHasBeenReceived);

  static int get startCheckingLastMessagesFromServerAfterSize => 100;

  factory ClientReceived.from(data){
    if(data == 'pong' || data == 'welcome') {
      return ClientReceivedIgnore();
    }

    final Map<String,dynamic> messageMap = data is String ? jsonDecode(data) : data;
    if(messageMap["serverId"]==null) {
      throw 'Unknown: ${Map.from(messageMap)}';
    }
    if(messageMap[ServerConfirmReceiptCli.typeResponse]!=null) {
      return ClientReceivedServerConfirmReceipt(messageMap);
    }
    if(messageMap[NewDataForListener.type]!=null) {
      return ClientReceivedNewDataForListener(messageMap);
    }
    if(messageMap[InternalAsklessResponseModel.type]!=null) {
      return ClientReceivedResponse(messageMap);
    }
    if(messageMap[StopListeningEventEvent.type]!=null) {
      return ClientReceivedStopListeningEvent(messageMap);
    }

    throw "TODO: $messageMap";
  }

  void implementation();
  
  void handle() async {
    final serverId = messageMap["serverId"];

    if(!confirmToServerThatDataHasBeenReceived){
      implementation();
      return;
    }

    confirmReceiptToServer(serverId);

    final LastServerMessage? dataAlreadySentByServerBefore = lastMessagesFromServer.firstWhereOrNull((m) => m.serverId == serverId);
    if(dataAlreadySentByServerBefore != null){
      logger("handle, data already received: $serverId");
      dataAlreadySentByServerBefore.messageReceivedAtSinceEpoch = DateTime.now().millisecondsSinceEpoch;
      return;
    }

    lastMessagesFromServer.add(LastServerMessage(serverId));

    checkCleanOldMessagesFromServer();

    implementation();
  }

  void checkCleanOldMessagesFromServer({int removeCount = 10}) {
    if(lastMessagesFromServer.length > startCheckingLastMessagesFromServerAfterSize){
      logger("Start of removing old messages received from server... (total: ${lastMessagesFromServer.length})");
      final List<LastServerMessage> remove = [];
      for(int i=lastMessagesFromServer.length-1; i >= 0 && remove.length < removeCount; i--){
        final messageReceivedFromServer = lastMessagesFromServer[i];
        if(messageReceivedFromServer.shouldBeRemoved) {
          remove.add(messageReceivedFromServer);
        }
      }
      for (final LastServerMessage element in remove) {
        lastMessagesFromServer.remove(element);
      }
      logger("...end of removing old messages received from server (removed: ${remove.length})");
    }
  }

  void confirmReceiptToServer(String serverId) {
    logger("confirmReceiptToServer $serverId");

    getIt.get<AbstractIOWsChannel>().sinkAdd(map: ClientConfirmReceiptCli(serverId));
  }
}



class LastServerMessage{
  int messageReceivedAtSinceEpoch = DateTime.now().millisecondsSinceEpoch;

  final String serverId;

  LastServerMessage(this.serverId);

  bool get shouldBeRemoved => messageReceivedAtSinceEpoch + _keepLastMessagesFromServerWithinMs < DateTime.now().millisecondsSinceEpoch;
}