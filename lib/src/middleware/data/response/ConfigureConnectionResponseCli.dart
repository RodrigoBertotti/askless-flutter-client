import 'package:askless/src/constants.dart';
import 'package:askless/src/middleware/data/response/RespondError.dart';
import 'package:askless/src/middleware/data/response/ResponseCli.dart';

class ConfigureConnectionResponseCli extends ResponseCli{
  static final typeResponse = '_class_type_configureconnection';
  final _class_type_configureconnection = '_';

  ConfigureConnectionResponseCli.fromMap(messageMap) {
    super.setValuesFromMap(messageMap);
  }

  ConnectionConfiguration get connectionConfiguration => this.output == null ? null : ConnectionConfiguration.fromMap(this.output);
}

class ConnectionConfiguration{
  int intervalInSecondsServerSendSameMessage = 5;
  int intervalInSecondsClientSendSameMessage = 5;
  int intervalInSecondsClientPing = 5;
  int reconnectClientAfterSecondsWithoutServerPong = 10;
  int disconnectClientAfterSecondsWithoutClientPing = 38;
  String serverVersion;
  ClientVersionCodeSupported clientVersionCodeSupported;
  bool isFromServer = false;
  String projectName;
  int requestTimeoutInSeconds = 15;

  ConnectionConfiguration();

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

  ClientVersionCodeSupported.fromMap(map){
    lessThanOrEqual = map['lessThanOrEqual'];
    moreThanOrEqual = map['moreThanOrEqual'];
  }



}
