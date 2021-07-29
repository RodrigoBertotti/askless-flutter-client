import 'dart:async';
import 'package:askless/src/dependency_injection/index.dart';
import 'package:askless/src/middleware/ListeningHandler.dart';
import 'package:askless/src/middleware/data/Mappable.dart';
import 'package:askless/src/middleware/ws_channel/AbstractIOWsChannel.dart';
import 'package:flutter/widgets.dart';
import 'package:askless/askless.dart';
import 'package:random_string/random_string.dart';
import 'package:askless/src/middleware/SendData.dart';
import 'package:askless/src/middleware/data/request/ConfigureConnectionRequestCli.dart';
import 'package:askless/src/middleware/data/receivements/RespondError.dart';
import 'package:askless/src/middleware/data/receivements/ResponseCli.dart';
import '../constants.dart';
import '../index.dart';
import 'data/request/AbstractRequestCli.dart';
import 'data/receivements/ConfigureConnectionResponseCli.dart';
import 'receivements/ClientReceived.dart';

int get keepLastMessagesFromServerWithinMs => 10 * 60 * 1000;


class Middleware with ListeningHandler {
  final String serverUrl;
  late final SendClientData sendClientData;
  ConnectionConfiguration connectionConfiguration = new ConnectionConfiguration();
  final List<LastServerMessage> lastMessagesFromServer = [];
  static String ? _clientGeneratedId; // 1 por pessoa, dessa maneira a pessoa ainda pode obter a resposta caso desconectar e conectar novamente
  VoidCallback? disconnectAndClearOnDone;
  AbstractIOWsChannel ? ws;

  Middleware(this.serverUrl) {
    sendClientData = new SendClientData(this);
  }

  void sinkAdd({Mappable? map, String? data}) => ws?.sinkAdd(map:map, data:data);

  Future<ResponseCli> runOperationInServer(AbstractRequestCli requestCli, [bool ? neverTimeout]) {
    return this
        .sendClientData
        .runOperationInServer(data: requestCli, neverTimeout: neverTimeout);
  }

  Future<ResponseCli> performConnection(
      {ownClientId, Map<String, dynamic> ? headers}) async {
    
    this._handleClientGeneratedId(ownClientId);

    Internal.instance.notifyConnectionChanged(Connection.CONNECTION_IN_PROGRESS);

    this._checkStartTasks();

    this.connectionConfiguration = new ConnectionConfiguration(); //restaurando isFromServer para false, pois quando se perde  é mantido o connectionConfiguration da conexão atual

    ResponseCli response;
    bool tryAgain;
    do {
      logger(message: "middleware: connect");

      ws?.close();
      ws = getIt.get<AbstractIOWsChannel>(param1: serverUrl)..start();

      response = await sendClientData.runOperationInServer(
          data: new ConfigureConnectionRequestCli(
              ownClientId != null ? ownClientId : _clientGeneratedId,
              headers ?? new Map()
          )
      );
      if (response.error != null) {
        logger(
            message: "Data could not be sent, got an error",
            level: Level.error,
            additionalData:
              (response.error?.code??'') + ' ' +
              (response.error?.description??'') + '\n' +
              (response.error?.stack??'')
        );
        Internal.instance.notifyConnectionChanged(Connection.DISCONNECTED,
            disconnectionReason:
                response.error!.code == ReqErrorCode.TOKEN_INVALID
                    ? DisconnectionReason.TOKEN_INVALID
                    : null);
      }
      tryAgain = response.error?.code == ReqErrorCode.TIMEOUT;
      if(tryAgain){
        ws?.close();
        ws = null;
        Internal.instance.middleware?.sendClientData.removePendingRequests(whereRequestType: RequestType.CONFIGURE_CONNECTION);
      }
    } while (tryAgain);

    return response;
  }


  void _checkStartTasks() {
    if (Internal.instance.tasksStarted == false) {
      Internal.instance.tasksStarted = true;
      Internal.instance.sendMessageToServerAgainTask.start();
      Internal.instance.sendPingTask.start();
      Internal.instance.reconnectWhenDidNotReceivePongFromServerTask.start();
      Internal.instance.reconnectWhenOffline.start();
    }
  }

  void _handleClientGeneratedId(dynamic ownClientId) {
    if (ownClientId == null) {
      if (_clientGeneratedId == null) {
        _clientGeneratedId = CLIENT_GENERATED_ID_PREFIX + randomAlphaNumeric(15);
        logger(message: "New client generated id: " + _clientGeneratedId!);
      } else {
        logger(
            message: "Using the same client generated id: " +
                _clientGeneratedId!);
      }
    }
  }

  void disconnectAndClear({VoidCallback ? onDone}) {
    if (onDone != null)
      this.disconnectAndClearOnDone = onDone;
    logger(message: 'disconnectAndClear');

    Internal.instance.notifyConnectionChanged(Connection.DISCONNECTED);

    ws?.close();
    ws = null;
    sendClientData.clear();
    listeningTo.forEach((s) => s.streamController.close());
    listeningTo.clear();
    connectionConfiguration = new ConnectionConfiguration();
  }

}