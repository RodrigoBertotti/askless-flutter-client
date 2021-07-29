import 'dart:async';
import 'package:askless/askless.dart';
import 'package:askless/src/constants.dart';
import 'package:askless/src/index.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class ListeningHandler {
  final List<ClientListeningToRoute> listeningTo = [];

  Listening listen({required ListenCli listenCli}) {
    logger(message: 'listen');

    final alreadyListening = listeningTo.firstWhereOrNull((listenId) => listenId.hash == listenCli.hash);
    if (alreadyListening != null) {
      return _getAlreadyListening(alreadyListening);
    } else {
      return _getNewListening(listenCli);
    }
  }

  VoidCallback _getCallbackNotifyMotherStreamThatChildStreamIsNotListeningAnymore (String listenId) => () {
    logger(
        message: "notifyMotherStreamThatChildStreamIsNotListeningAnymore");
    this._stopListening(listenId: listenId);
  };


  void _stopListening({required String listenId}) {
    logger(
        message:
        "stopListening started " + listenId);
    final sub = listeningTo.firstWhereOrNull((s) => s.listenId == listenId);
    if (sub != null) {
      sub.counter--;
      if (sub.counter == 0) {
        //print('closing!!!!');
        sub.streamController.close();
        listeningTo.remove(sub);
      }
    }
  }

  Listening _getAlreadyListening(ClientListeningToRoute alreadyListening) {
    logger(message: 'alreadyListening');
    final _func = () {
      try {
        alreadyListening.counter++;
        if (alreadyListening.lastReceivementFromServer != null) {
          alreadyListening.streamController.add(
              alreadyListening.lastReceivementFromServer!);
        }
      } catch (e) {
        if (!e.toString().contains('Bad state: Cannot add new events after calling close')) {
          throw e;
        }else{
          logger(message: e.toString(), level: Level.debug);
        }
      }
    };

    if(environment == 'test'){
      _func();
    } else {
      Future.delayed(Duration(milliseconds: 500), _func);
    }

    return Listening(
        alreadyListening.streamController.stream,
        alreadyListening.clientRequestId,
        alreadyListening.listenId,
        _getCallbackNotifyMotherStreamThatChildStreamIsNotListeningAnymore(alreadyListening.listenId)
    );
  }

  Listening _getNewListening(ListenCli listenCli) {
    final String listenId = LISTEN_PREFIX + listenCli.clientRequestId.substring(REQUEST_PREFIX.length);
    final streamController = new StreamController<NewDataForListener>.broadcast(); // ignore: close_sinks
    final listen = new ClientListeningToRoute(
        route: listenCli.route,
        query: listenCli.query,
        streamController: streamController,
        clientRequestId: listenCli.clientRequestId,
        hash: listenCli.hash,
        listenId: listenId,
    );

    listenCli.listenId = listen.listenId;
    listeningTo.add(listen);
    Internal.instance.middleware!.runOperationInServer(listenCli).then((response) {
      if (response.error != null) {
        streamController.sink.addError(response.error!);
        logger(
            message: 'could not listen',
            additionalData: response.error!.stack,
            level: Level.error
        );
      } else {
        logger(message: 'now is listening to '+listenId+'!');
      }
    });
    streamController.onCancel = () {
      logger(
          message: "listen onCancel listen = " +
              listen.listenId +
              " hasListener: " +
              streamController.hasListener.toString());
      if (streamController.hasListener == false)
        this._stopListening(listenId: listen.listenId);
    };

    return new Listening(
      streamController.stream,
      listen.clientRequestId,
      listenId,
      _getCallbackNotifyMotherStreamThatChildStreamIsNotListeningAnymore(listenId),
    );
  }
  
}


class ClientListeningToRoute {
  final String route;
  final dynamic query;
  final String clientRequestId;
  StreamController<NewDataForListener> streamController;
  final String hash;
  String listenId;
  NewDataForListener? lastReceivementFromServer;
  int counter = 1;

  ClientListeningToRoute(
      {required this.route,
        required this.query,
        required this.streamController,
        required this.clientRequestId,
        required this.hash,
        required this.listenId
      }
  );
}