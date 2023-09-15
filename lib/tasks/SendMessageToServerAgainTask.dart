import '../../../../../injection_container.dart';
import '../domain/services/requests_service.dart';
import '../index.dart';
import '../middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import 'TimedTask.dart';

class SendMessageToServerAgainTask extends TimedTask{

  SendMessageToServerAgainTask() : super('SendMessageToServerAgainTask', ConnectionConfiguration().intervalInMsClientSendSameMessage);

  @override
  void run() {
    if (AsklessClient.instance.connection.status == ConnectionStatus.connected) {
      getIt.get<RequestsService>().sendMessagesToServerAgain(super.intervalInMs);
    }
  }

}
