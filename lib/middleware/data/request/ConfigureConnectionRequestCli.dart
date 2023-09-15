import '../../../constants.dart';
import 'AbstractRequestCli.dart';




class ConfigureConnectionRequestCli extends AbstractRequestCli {
  static const _type = '_class_type_configureconnectionrequest';
  static const _clientIdInternalApp = 'clientIdInternalApp';
  static const _clientType = 'clientType';

  final String clientIdInternalApp;
  final String clientType = 'flutter';

  ConfigureConnectionRequestCli(this.clientIdInternalApp,) : super(RequestType.CONFIGURE_CONNECTION);

  @override
  String? getRoute() {
    return null;
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[_type] = '_';
    map[_clientIdInternalApp] = clientIdInternalApp;
    map[_clientType] = clientType;
    return map;
  }
}
