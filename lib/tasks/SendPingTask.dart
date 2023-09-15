import '../../../../../injection_container.dart';
import '../domain/services/authenticate_service.dart';
import '../middleware/ListeningHandler.dart';
import '../middleware/data/connection/PingPong.dart';
import '../middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import '../middleware/ws_channel/AbstractIOWsChannel.dart';
import 'TimedTask.dart';


class SendPingTask extends TimedTask{

  SendPingTask() : super('SendPingTask', ConnectionConfiguration().intervalInMsClientPing);

  // não está autenticado ainda parece

  @override
  void run() {
    List<ListeningTo> listeningTo = [];
    if (!getIt.get<AuthenticateService>().shouldBeAuthenticated || getIt.get<AuthenticateService>().authStatus == AuthStatus.authenticated) {
      getIt.get<ListeningHandler>().listeningTo.where((element) => element.ready).forEach((listen) {
        listeningTo.add(
            ListeningTo(
              listenId: listen.listenId,
              route: listen.route,
              params: listen.params,
              clientRequestId: listen.clientRequestId!,
            )
        );
      });
    }
    getIt.get<AbstractIOWsChannel>().sinkAdd(map: PingPong(listeningToRoutes: listeningTo));
  }

}
