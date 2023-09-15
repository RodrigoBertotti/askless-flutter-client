import '../../../constants.dart';
import '../../../domain/entities/internal_response_cli_entity.dart';
import '../../../index.dart';

class ConfigureConnectionAsklessResponse extends InternalAsklessResponseEntity {
  static const typeResponse = '_class_type_configureconnection';

  ConfigureConnectionAsklessResponse (
      dynamic output,
      AsklessError? error,
      String clientRequestId,
      String? serverId
  ) : super(clientRequestId: clientRequestId, serverId: serverId, error: error, output: output);

  ConnectionConfiguration? get connectionConfiguration => success ? ConnectionConfiguration.fromMap(output["connectionConfiguration"]) : null;

  String? get errorDescription => error?.description;

  factory ConfigureConnectionAsklessResponse.fromResponse(InternalAsklessResponseEntity asklessResponse) {
    return ConfigureConnectionAsklessResponse(asklessResponse.output, asklessResponse.error, asklessResponse.clientRequestId, asklessResponse.serverId);
  }
}

class ConnectionConfiguration{
  late int intervalInMsServerSendSameMessage;
  late int intervalInMsClientSendSameMessage;
  late int intervalInMsClientPing;
  late int reconnectClientAfterMillisecondsWithoutServerPong;
  late int millisecondsToDisconnectClientAfterWithoutClientPing;
  late String serverVersion;
  late ClientVersionCodeSupported clientVersionCodeSupported;
  late bool isFromServer;
  late int requestTimeoutInMs;
  late int waitForAuthenticationTimeoutInMs;

  ConnectionConfiguration({
    ClientVersionCodeSupported? clientVersionCodeSupported,
    this.millisecondsToDisconnectClientAfterWithoutClientPing = 12 * 1000,
    this.intervalInMsClientPing = 1 * 1000,
    this.intervalInMsClientSendSameMessage = 5 * 1000,
    this.intervalInMsServerSendSameMessage = 5 * 1000,
    this.isFromServer = false,
    this.reconnectClientAfterMillisecondsWithoutServerPong = 6 * 1000,
    this.requestTimeoutInMs = 7 * 1000,
    this.waitForAuthenticationTimeoutInMs = 4 * 1000,
    this.serverVersion = 'none',
  }){
    this.clientVersionCodeSupported = clientVersionCodeSupported ?? ClientVersionCodeSupported();
  }

  ConnectionConfiguration.fromMap(map){
    this.intervalInMsServerSendSameMessage = map['intervalInMsServerSendSameMessage'];
    this.intervalInMsClientSendSameMessage = map['intervalInMsClientSendSameMessage'];
    this.intervalInMsClientPing = map['intervalInMsClientPing'];
    this.reconnectClientAfterMillisecondsWithoutServerPong = map['reconnectClientAfterMillisecondsWithoutServerPong'];
    this.isFromServer = map['isFromServer'];
    this.serverVersion = map['serverVersion'];
    this.clientVersionCodeSupported = ClientVersionCodeSupported.fromMap(map['clientVersionCodeSupported']);
    this.requestTimeoutInMs = map['requestTimeoutInMs'];
    this.millisecondsToDisconnectClientAfterWithoutClientPing = map['millisecondsToDisconnectClientAfterWithoutClientPing'];
    this.waitForAuthenticationTimeoutInMs = map['waitForAuthenticationTimeoutInMs'];
  }

  bool get incompatibleVersion => (clientVersionCodeSupported.moreThanOrEqual != null && CLIENT_LIBRARY_VERSION_CODE < clientVersionCodeSupported.moreThanOrEqual!) || (clientVersionCodeSupported.lessThanOrEqual != null && CLIENT_LIBRARY_VERSION_CODE > clientVersionCodeSupported.lessThanOrEqual!);

}

class ClientVersionCodeSupported{

  int? lessThanOrEqual;
  int? moreThanOrEqual;

  ClientVersionCodeSupported({this.lessThanOrEqual, this.moreThanOrEqual});

  ClientVersionCodeSupported.fromMap(map){
    lessThanOrEqual = map['lessThanOrEqual'];
    moreThanOrEqual = map['moreThanOrEqual'];
  }

}
