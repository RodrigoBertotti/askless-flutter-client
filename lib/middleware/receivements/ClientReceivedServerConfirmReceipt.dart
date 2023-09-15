import '../../../../../../injection_container.dart';
import '../../domain/services/requests_service.dart';
import '../data/receivements/ServerConfirmReceiptCli.dart';
import 'ClientReceived.dart';

class ClientReceivedServerConfirmReceipt extends ClientReceived{

  ClientReceivedServerConfirmReceipt(messageMap) : super(messageMap, false);

  @override
  void implementation() {
    final serverConfirmReceiptCli = ServerConfirmReceiptCli.fromMap(messageMap);
    getIt.get<RequestsService>().setAsReceivedPendingMessageThatServerShouldReceive(
        serverConfirmReceiptCli.clientRequestId
    );
  }

}