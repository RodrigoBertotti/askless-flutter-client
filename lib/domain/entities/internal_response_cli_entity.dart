import '../../index.dart';
import '../entities/response_entity.dart';

class InternalAsklessResponseEntity extends AsklessResponse {
  final String? serverId;
  final String clientRequestId;

  InternalAsklessResponseEntity({
    this.serverId, required this.clientRequestId,
    dynamic output, AsklessError? error
  }) : super(output: output, error: error);

}