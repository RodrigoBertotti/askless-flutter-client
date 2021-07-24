import 'package:askless/askless.dart';
import 'package:askless/src/constants.dart';
import 'package:askless/src/middleware/data/receivements/ResponseCli.dart';

class ConfigureConnectionResponseCli extends ResponseCli{
  static const typeResponse = '_class_type_configureconnection';

  ConfigureConnectionResponseCli.fromMap(messageMap) : super.fromMap(messageMap);

  ConnectionConfiguration get connectionConfiguration => ConnectionConfiguration.fromMap(this.output);
}

class ConnectionConfiguration{
  late int intervalInSecondsServerSendSameMessage;
  late int intervalInSecondsClientSendSameMessage;
  late int intervalInSecondsClientPing;
  late int reconnectClientAfterSecondsWithoutServerPong;
  late int disconnectClientAfterSecondsWithoutClientPing;
  late String serverVersion;
  late ClientVersionCodeSupported clientVersionCodeSupported;
  late bool isFromServer;
  String? projectName;
  late int requestTimeoutInSeconds;

  ConnectionConfiguration({
    ClientVersionCodeSupported? clientVersionCodeSupported,
    this.disconnectClientAfterSecondsWithoutClientPing:38,
    this.intervalInSecondsClientPing:5,
    this.intervalInSecondsClientSendSameMessage:5,
    this.intervalInSecondsServerSendSameMessage:5,
    this.isFromServer:false,
    this.projectName,
    this.reconnectClientAfterSecondsWithoutServerPong:10,
    this.requestTimeoutInSeconds:15,
    this.serverVersion:'none',
  }){
    this.clientVersionCodeSupported = clientVersionCodeSupported ?? ClientVersionCodeSupported();
  }

  ConnectionConfiguration.fromMap(map){
    this.intervalInSecondsServerSendSameMessage = map['intervalInSecondsServerSendSameMessage'];
    this.intervalInSecondsClientSendSameMessage = map['intervalInSecondsClientSendSameMessage'];
    this.intervalInSecondsClientPing = map['intervalInSecondsClientPing'];
    this.reconnectClientAfterSecondsWithoutServerPong = map['reconnectClientAfterSecondsWithoutServerPong'];
    this.isFromServer = map['isFromServer'];
    this.serverVersion = map['serverVersion'];
    this.clientVersionCodeSupported = ClientVersionCodeSupported.fromMap(map['clientVersionCodeSupported']);
    this.projectName = map['projectName'];
    this.requestTimeoutInSeconds = map['requestTimeoutInSeconds'];
    this.disconnectClientAfterSecondsWithoutClientPing = map['disconnectClientAfterSecondsWithoutClientPing'];
  }

  bool get differentProjectName => AsklessClient.instance.projectName != null &&
      projectName != null &&
      AsklessClient.instance.projectName !=
          projectName;

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
