import '../../domain/entities/internal_response_cli_entity.dart';
import 'askless_error_model.dart';


class InternalAsklessResponseModel extends InternalAsklessResponseEntity {
  static const type =  "_class_type_response";


  InternalAsklessResponseModel({
    required super.serverId,
    required super.clientRequestId,
    super.output,
    super.error
  });

  InternalAsklessResponseModel.fromMap (map) : super(
    serverId: map["serverId"],
    clientRequestId: map["clientRequestId"],
    error: map['error'] != null ? AsklessErrorModel.fromMap(map['error']) : null,
    output: map['output'],
  );

}