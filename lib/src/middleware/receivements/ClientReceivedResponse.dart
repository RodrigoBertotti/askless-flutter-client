


import 'package:askless/askless.dart';
import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';

class ClientReceivedResponse extends ClientReceived{

  ClientReceivedResponse(messageMap) : super(messageMap, true);

  @override
  void implementation() {
    final responseCli = ResponseCli.fromMap(messageMap);
    Internal.instance.middleware.sendClientData.notifyServerResponse(responseCli);
  }


}