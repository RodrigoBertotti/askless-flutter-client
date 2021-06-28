import 'package:askless/src/middleware/data/receivements/ResponseCli.dart';

class ConfigureConnectionResponseCli extends ResponseCli{
  static final typeResponse = '_class_type_configureconnection';
  final _class_type_configureconnection = '_';

  ConfigureConnectionResponseCli.fromMap(messageMap) {
    super.setValuesFromMap(messageMap);
  }

  ConnectionConfiguration get connectionConfiguration => this.output == null ? null : ConnectionConfiguration.fromMap(this.output);
}

class ConnectionConfiguration{
  int intervalInSecondsServerSendSameMessage;
  int intervalInSecondsClientSendSameMessage;
  int intervalInSecondsClientPing;
  int reconnectClientAfterSecondsWithoutServerPong;
  int disconnectClientAfterSecondsWithoutClientPing;
  String serverVersion;
  ClientVersionCodeSupported clientVersionCodeSupported;
  bool isFromServer = false;
  String projectName;
  int requestTimeoutInSeconds;

  ConnectionConfiguration({
    this.clientVersionCodeSupported,
    this.disconnectClientAfterSecondsWithoutClientPing:38,
    this.intervalInSecondsClientPing:5,
    this.intervalInSecondsClientSendSameMessage:5,
    this.intervalInSecondsServerSendSameMessage:5,
    this.isFromServer,
    this.projectName,
    this.reconnectClientAfterSecondsWithoutServerPong:10,
    this.requestTimeoutInSeconds:15,
    this.serverVersion
  });

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


}

class ClientVersionCodeSupported{

  int lessThanOrEqual;
  int moreThanOrEqual;

  ClientVersionCodeSupported({this.lessThanOrEqual, this.moreThanOrEqual});

  ClientVersionCodeSupported.fromMap(map){
    lessThanOrEqual = map['lessThanOrEqual'];
    moreThanOrEqual = map['moreThanOrEqual'];
  }



}
