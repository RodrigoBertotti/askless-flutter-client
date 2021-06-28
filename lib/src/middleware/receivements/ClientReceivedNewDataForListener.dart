

import 'package:askless/askless.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';

class ClientReceivedNewDataForListener extends ClientReceived{


  ClientReceivedNewDataForListener(messageMap)
      : super(messageMap, true);


  @override
  void implementation() {
    final message = NewDataForListener.fromMap(messageMap);

    final sub = Internal.instance.middleware.listeningTo.firstWhere((s) => s.listenId == message.listenId, orElse: () => null);
    if (sub != null) {
      sub.streamController?.add(message);
      sub.lastReceivementFromServer = message;
    }
  }


}