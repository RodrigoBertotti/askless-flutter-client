import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import 'package:askless/src/tasks/TimedTask.dart';

class SendMessageToServerAgainTask extends TimedTask{
  Connection _connection = Connection.DISCONNECTED;
  OnConnectionChange? _onConnectionChange;

  SendMessageToServerAgainTask() : super('SendMessageToServerAgainTask', new ConnectionConfiguration().intervalInSecondsClientSendSameMessage){
    Future.delayed(Duration(seconds: 3), (){
      _connection = AsklessClient.instance.connection;
      AsklessClient.instance.addOnConnectionChange(_onConnectionChange = (connection) {
        _connection = connection;
        //changeInterval(Askless.instance.middleware.connectionConfiguration.intervalInSecondsClientRequest);
      });
    });
  }


  @override
  void run() {
    if (_connection==Connection.CONNECTED_WITH_SUCCESS) //TODO: analisar no lado web! será que não é melhor deixar _connection==Connection.CONNECTED_WITH_SUCCESS??? Mudar isso deu problema parece
      Internal.instance.middleware?.sendClientData.sendMessagesToServerAgain();
  }

}
