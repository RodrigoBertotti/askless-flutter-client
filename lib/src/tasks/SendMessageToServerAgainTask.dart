import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import 'package:askless/src/tasks/TimedTask.dart';

class SendMessageToServerAgainTask extends TimedTask{

  SendMessageToServerAgainTask() : super('SendMessageToServerAgainTask', new ConnectionConfiguration().intervalInSecondsClientSendSameMessage);

  @override
  void run() {
    if (AsklessClient.instance.connection == Connection.CONNECTED_WITH_SUCCESS) //TODO: analisar no lado web! será que não é melhor deixar _connection==Connection.CONNECTED_WITH_SUCCESS??? Mudar isso deu problema parece
      Internal.instance.middleware?.sendClientData.sendMessagesToServerAgain();
  }

}
