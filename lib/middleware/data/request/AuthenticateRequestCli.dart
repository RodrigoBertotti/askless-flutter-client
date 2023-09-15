import '../../../middleware/data/request/AbstractRequestCli.dart';
import '../../../constants.dart';




class AuthenticateRequestCli extends AbstractRequestCli {
  static const _type = '_class_type_authenticaterequest';
  static const _clientIdInternalApp = 'clientIdInternalApp';
  static const _clientType = 'clientType';
  static const _credential = 'credential';

  final String clientIdInternalApp;
  final dynamic credential;

  AuthenticateRequestCli({required this.clientIdInternalApp, required this.credential}) : super(RequestType.AUTHENTICATE);

  @override
  String? getRoute() {
    return null;
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[_type] = '_';
    map[_clientIdInternalApp] = clientIdInternalApp;
    map[_clientType] = 'flutter';
    map[_credential] = credential;
    return map;
  }
}
