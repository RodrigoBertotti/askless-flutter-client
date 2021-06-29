import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:askless/askless.dart';
import 'package:random_string/random_string.dart';
import 'package:web_socket_channel/io.dart';
import 'package:askless/src/middleware/SendData.dart';
import 'package:askless/src/middleware/data/request/ClientConfirmReceiptCli.dart';
import 'package:askless/src/middleware/data/request/OperationRequestCli.dart';
import 'package:askless/src/middleware/data/request/ConfigureConnectionRequestCli.dart';
import 'package:askless/src/middleware/data/receivements/NewRealtimeData.dart';
import 'package:askless/src/middleware/data/receivements/RespondError.dart';
import 'package:askless/src/middleware/data/receivements/ResponseCli.dart';
import '../constants.dart';
import '../index.dart';
import '../constants.dart';
import '../index.dart';
import 'data/request/AbstractRequestCli.dart';
import 'data/receivements/ConfigureConnectionResponseCli.dart';
import 'receivements/ClientReceived.dart';

int get keepLastMessagesFromServerWithinMs => 10 * 60 * 1000;

class LastServerMessage{
  int messageReceivedAtSinceEpoch = DateTime.now().millisecondsSinceEpoch;

  final String serverId;

  LastServerMessage(this.serverId);

  bool get shouldBeRemoved => messageReceivedAtSinceEpoch + keepLastMessagesFromServerWithinMs < DateTime.now().millisecondsSinceEpoch;
}

class ClientListeningToRoute {
  final String route;
  final dynamic query;
  final String clientRequestId;
  StreamController<NewDataForListener> streamController;
  final String hash;
  String listenId;
  NewDataForListener lastReceivementFromServer;
  int counter = 1;

  ClientListeningToRoute(
      {@required this.route,
      @required this.query,
      @required this.streamController,
      @required this.clientRequestId,
      @required this.hash,
      @required this.listenId});
}

class Middleware {
  final String serverUrl;
  IOWebSocketChannel channel;
  int _lastPongFromServer;
  SendClientData sendClientData;
  ConnectionConfiguration connectionConfiguration = new ConnectionConfiguration();
  final List<LastServerMessage> lastMessagesFromServer = [];

  static String
      CLIENT_GENERATED_ID; // 1 por pessoa, dessa maneira a pessoa ainda pode obter a resposta caso desconectar e conectar novamente
  final List<ClientListeningToRoute> listeningTo = [];
  VoidCallback _disconnectAndClearOnDone = () {};

  Middleware(this.serverUrl) {
    sendClientData = new SendClientData(this);
  }

  Future<ResponseCli> runOperationInServer(
      AbstractRequestCli requestCli, bool neverTimeout) {
    return this
        .sendClientData
        .send(data: requestCli, neverTimeout: neverTimeout);
  }

  get lastPongFromServer {
    return _lastPongFromServer;
  }

  Future<ResponseCli> connect(
      {ownClientId, Map<String, dynamic> headers}) async {
    if (ownClientId == null) {
      if (CLIENT_GENERATED_ID == null) {
        CLIENT_GENERATED_ID =
            CLIENT_GENERATED_ID_PREFIX + randomAlphaNumeric(15);
        Internal.instance
            .logger(message: "New client generated id: " + CLIENT_GENERATED_ID);
      } else
        Internal.instance.logger(
            message:
                "Using the same client generated id: " + CLIENT_GENERATED_ID);
    }

    Internal.instance
        .notifyConnectionChanged(Connection.CONNECTION_IN_PROGRESS);

    if (Internal.instance.tasksStarted == false) {
      Internal.instance.tasksStarted = true;
      Internal.instance.sendMessageToServerAgainTask.start();
      Internal.instance.sendPingTask.start();
      Internal.instance.reconnectWhenDidNotReceivePongFromServerTask.start();
      Internal.instance.reconnectWhenOffline.start();
    }

    this.connectionConfiguration =
        new ConnectionConfiguration(); //restaurando isFromServer para false, pois quando se perde  é mantido o connectionConfiguration da conexão atual

    ResponseCli response;
    bool tryAgain;
    do {
      Internal.instance.logger(message: "middleware: connect");

      this.close();

      channel = IOWebSocketChannel.connect(serverUrl);

      channel.stream.listen((data) {
        _lastPongFromServer = DateTime.now().millisecondsSinceEpoch;

        ClientReceived.from(data).handle();

      }, onError: (err) {
        Internal.instance.logger(message: "middleware: channel.stream.listen onError", level: Level.error, additionalData: err.toString());
      }, onDone: () =>  _handleConnectionClosed(Duration(seconds: 2))
      );

      channel.stream.handleError((err) {
        Internal.instance.logger(message: "channel handleError", additionalData: err, level: Level.error);
      });

      response = await sendClientData.send(
          data: new ConfigureConnectionRequestCli(
              ownClientId != null ? ownClientId : CLIENT_GENERATED_ID,
              headers ?? new Map()));
      if (response.error != null) {
        Internal.instance.logger(
            message: "Data could not be sent, got an error",
            level: Level.error,
            additionalData:
              (response?.error?.code??'') + ' ' +
              (response?.error?.description??'') + '\n' +
              (response?.error?.stack??'')
        );
        Internal.instance.notifyConnectionChanged(Connection.DISCONNECTED,
            disconnectionReason:
                response.error.code == ReqErrorCode.TOKEN_INVALID
                    ? DisconnectionReason.TOKEN_INVALID
                    : null);
      }
      tryAgain = response.error?.code == ReqErrorCode.TIMEOUT;
      if(tryAgain){
        this.close();
        Internal.instance.middleware?.sendClientData?.removePendingRequests(whereRequestType: RequestType.CONFIGURE_CONNECTION);
      }
    } while (tryAgain);

    return response;
  }



  void disconnectAndClear({VoidCallback onDone}) {
    if (onDone != null) this._disconnectAndClearOnDone = onDone;
    Internal.instance.logger(message: 'disconnectAndClear');

    Internal.instance.notifyConnectionChanged(Connection.DISCONNECTED);

    this.close();
    sendClientData.clear();
    listeningTo.forEach((s) => s.streamController?.close());
    listeningTo.clear();
    connectionConfiguration = new ConnectionConfiguration();
  }

  void close() {
    Internal.instance.logger(message: 'close');

    if (channel != null) channel.sink.close();

    _lastPongFromServer = null;
    channel = null;
  }

  Listening listen({@required ListenCli listenCli}) {
    Internal.instance.logger(message: 'listen');

    String listenId;

    final VoidCallback notifyMotherStreamThatChildStreamIsNotListeningAnymore =
        () {
      Internal.instance.logger(
          message: "notifyMotherStreamThatChildStreamIsNotListeningAnymore");
      this.stopListening(listenId: listenId);
    };
    final alreadyListening = listeningTo
        .firstWhere((listenId) => listenId.hash == listenCli.hash, orElse: () => null);
    if (alreadyListening != null) {
      listenId = alreadyListening.listenId;
      Internal.instance.logger(message: 'alreadyListening');
      Future.delayed(Duration(milliseconds: 500), () {
        try {
          alreadyListening.counter++;
          if (alreadyListening.lastReceivementFromServer != null)
            alreadyListening.streamController
                .add(alreadyListening.lastReceivementFromServer);
        } catch (e) {
          if (!e.toString().contains('Bad state: Cannot add new events after calling close')) {
            throw e;
          }else{
            Internal.instance.logger(message: e.toString(), level: Level.debug);
          }
        }
      });
      return Listening(
          alreadyListening.streamController.stream,
          alreadyListening.clientRequestId,
          listenId,
          notifyMotherStreamThatChildStreamIsNotListeningAnymore);
    } else {
      //New
      assert(listenCli.clientRequestId != null);

      listenId = LISTEN_PREFIX +
          listenCli.clientRequestId.substring(REQUEST_PREFIX.length);
      final streamController = new StreamController<NewDataForListener>.broadcast(); // ignore: close_sinks
      final listen = new ClientListeningToRoute(
          route: listenCli.route,
          query: listenCli.query,
          streamController: streamController,
          clientRequestId: listenCli.clientRequestId,
          hash: listenCli.hash,
          listenId: listenId);

      listenCli.listenId = listen.listenId;
      listeningTo.add(listen);
      this.runOperationInServer(listenCli, null).then((response) {
        if (response.error != null) {
          streamController.sink.addError(response.error);
          Internal.instance.logger(
              message: 'could not listen',
              additionalData: response.error.stack,
              level: Level.error);
        } else {
          Internal.instance.logger(message: 'now is listening to '+listenId+'!');
        }
      });
      streamController.onCancel = () {
        Internal.instance.logger(
            message: "listen onCancel listen = " +
                (listen.listenId != null ? listen.listenId : 'null') +
                " hasListener: " +
                streamController.hasListener.toString());
        if (streamController.hasListener == false)
          this.stopListening(listenId: listen.listenId);
      };

      return new Listening(streamController.stream, listen.clientRequestId,
          listenId, notifyMotherStreamThatChildStreamIsNotListeningAnymore
      );
    }
  }


  void stopListening({@required String listenId}) {
    Internal.instance.logger(
        message:
            "stopListening started " + (listenId != null ? listenId : 'null'));
    final sub = listeningTo.firstWhere((s) => s.listenId == listenId,
        orElse: () => null);
    if (sub != null) {
      sub.counter--;
      if (sub.counter == 0) {
        //print('closing!!!!');
        sub.streamController.close();
        listeningTo.remove(sub);
      }
    }
  }



  void _handleConnectionClosed(Duration delay) {
    Internal.instance.logger(message: "channel.stream.listen onDone");

    Future.delayed(delay, () {
      this._disconnectAndClearOnDone();
      this._disconnectAndClearOnDone = () {};

      if (Internal.instance.disconnectionReason != DisconnectionReason.TOKEN_INVALID &&
          Internal.instance.disconnectionReason != DisconnectionReason.DISCONNECTED_BY_CLIENT &&
          Internal.instance.disconnectionReason != DisconnectionReason.VERSION_CODE_NOT_SUPPORTED &&
          Internal.instance.disconnectionReason != DisconnectionReason.WRONG_PROJECT_NAME
      ) {
        if (Internal.instance.disconnectionReason == null) {
          Internal.instance.disconnectionReason = DisconnectionReason.UNDEFINED;
        }

        if(AsklessClient.instance.connection == Connection.DISCONNECTED){
          AsklessClient.instance.reconnect();
        }
      }
    });
  }
}