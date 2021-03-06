import 'package:askless/src/index.dart';
import 'package:askless/src/middleware/data/response/ConfigureConnectionResponseCli.dart';
import 'package:askless/src/tasks/TimedTask.dart';

class SendMessageToServerAgainTask extends TimedTask{
  Connection _connection = Connection.DISCONNECTED;
  OnConnectionChange onConnectionChange;

  SendMessageToServerAgainTask() : super('SendMessageToServerAgainTask', new ConnectionConfiguration().intervalInSecondsClientSendSameMessage){
    Future.delayed(Duration(seconds: 3), (){
      _connection = AsklessClient.instance.connection;
      AsklessClient.instance.addOnConnectionChange(onConnectionChange = (connection) {
        _connection = connection;
        //changeInterval(Askless.instance.middleware.connectionConfiguration.intervalInSecondsClientRequest);
      });
    });
  }


  @override
  void run() {
    if (_connection==Connection.CONNECTED_WITH_SUCCESS) //TODO: mudar para _connection!=Connection.DISCONNECTED ?
      Internal.instance.middleware?.sendClientData?.sendMessagesToServerAgain();
  }

}
