import 'package:askless/src/middleware/data/response/ResponseCli.dart';

class ServerConfirmReceiptCli extends ResponseCli{
  static final typeResponse = '_class_type_serverconfirmreceipt';
  final _class_type_serverconfirmreceipt = '_';

  ServerConfirmReceiptCli.fromMap(messageMap) {
    super.setValuesFromMap(messageMap);
  }
}
