import '../../../domain/entities/internal_response_cli_entity.dart';
import '../../../index.dart';

class AuthenticateResponseCli extends InternalAsklessResponseEntity {
  static const typeResponse = '_class_type_authenticateresponse';

  AuthenticateResponseCli (
      dynamic output,
      AsklessError? error,
      String clientRequestId,
      String? serverId
  ) : super(clientRequestId: clientRequestId, serverId: serverId, error: error, output: output);

  bool get invalidCredential => !success && error?.code == AsklessErrorCode.invalidCredential;

  Map<String,dynamic>? get credential => output?["credential"] == null ? null : Map.from(output["credential"]);

  List<String>? get claims => output?["claims"] == null ? null : List<String>.from(output?["claims"]);

  dynamic get userId => output?["userId"];

  String? get errorDescription => error?.description;

  factory AuthenticateResponseCli.fromResponse(InternalAsklessResponseEntity asklessResponse) {
    return AuthenticateResponseCli(asklessResponse.output, asklessResponse.error, asklessResponse.clientRequestId, asklessResponse.serverId);
  }

  bool get isCredentialError => output?["credentialErrorCode"] != null;
}
