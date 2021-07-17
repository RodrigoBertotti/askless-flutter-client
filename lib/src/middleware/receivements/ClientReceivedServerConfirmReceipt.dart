

import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/receivements/ServerConfirmReceiptCli.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';

class ClientReceivedServerConfirmReceipt extends ClientReceived{

  ClientReceivedServerConfirmReceipt(messageMap) : super(messageMap, false);

  @override
  void implementation() {
    final serverConfirmReceiptCli = ServerConfirmReceiptCli.fromMap(messageMap);
    Internal.instance.middleware!.sendClientData.setAsReceivedPendingMessageThatServerShouldReceive(serverConfirmReceiptCli.clientRequestId);
  }

}