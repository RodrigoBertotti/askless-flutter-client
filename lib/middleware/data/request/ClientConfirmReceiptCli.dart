import 'package:random_string/random_string.dart';
import '../../../constants.dart';
import 'AbstractRequestCli.dart';




class ClientConfirmReceiptCli extends AbstractRequestCli {
  static const fieldType = '_class_type_clientconfirmreceipt';
  static const fieldServerId = 'serverId';

  String serverId;

  ClientConfirmReceiptCli(this.serverId) : super(RequestType.CONFIRM_RECEIPT, clientRequestId: '${REQUEST_PREFIX}_${randomAlphaNumeric(28)}');

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map[fieldType] = '_';
    map[fieldServerId] = serverId;
    return map;
  }

  @override
  String? getRoute() {
    return null;
  }

}
