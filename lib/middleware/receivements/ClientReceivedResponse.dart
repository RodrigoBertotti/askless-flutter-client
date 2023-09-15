import '../../../../../../injection_container.dart';
import '../../data/models/internal_response_model.dart';
import '../../domain/services/requests_service.dart';
import 'ClientReceived.dart';


class ClientReceivedResponse extends ClientReceived{

  ClientReceivedResponse(messageMap) : super(messageMap, true);

  @override
  void implementation() {
    final responseCli = InternalAsklessResponseModel.fromMap(messageMap);
    getIt.get<RequestsService>().notifyThatHasBeenReceivedServerResponse(responseCli);
  }


}