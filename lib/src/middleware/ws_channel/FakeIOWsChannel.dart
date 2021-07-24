


import 'package:askless/askless.dart';
import 'package:askless/src/constants.dart';
import 'package:askless/src/middleware/data/Mappable.dart';
import 'package:askless/src/middleware/data/connection/PingPong.dart';
import 'package:askless/src/middleware/receivements/ClientReceived.dart';
import 'package:askless/src/middleware/ws_channel/AbstractIOWsChannel.dart';
import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';
import 'package:askless/src/middleware/data/request/ClientConfirmReceiptCli.dart';
import 'package:askless/src/middleware/data/request/ConfigureConnectionRequestCli.dart';
import 'package:injectable/injectable.dart';



Map<String, dynamic> _serverSentConfirmReceiptMap (String clientRequestId) => {
  'serverId': 'serverId'+clientRequestId.toString(),
  '_class_type_response': '_',
  '_class_type_serverconfirmreceipt': '_',
  'clientRequestId': clientRequestId,
};

void handlingServerConfirmReceipt (String clientRequestId){
  ClientReceived.from(_serverSentConfirmReceiptMap(clientRequestId)).handle();
}

typedef SimulateServerResponse = void Function(AbstractRequestCli request, void Function(dynamic output) responseCallback);

@Injectable(as: AbstractIOWsChannel, env: ['test'])
class FakeIOWsChannel extends AbstractIOWsChannel {

  static void Function(ConfigureConnectionRequestCli request)? clientIsSendingConfigureConnectionRequestCli;
  static void Function(ClientConfirmReceiptCli request)? clientIsSendingConfirmReceiptCli;
  static void Function(CreateCli request)? clientIsSendingCreateCli;
  static void Function(ReadCli request)? clientIsSendingReadCli;
  static void Function(UpdateCli request)? clientIsSendingUpdateCli;
  static void Function(DeleteCli request)? clientIsSendingDeleteCli;
  static void Function(ListenCli request)? clientIsSendingListenCli;
  static SimulateServerResponse? simulateServerResponseWithOutput;
  static bool? simulateServerConfirmReceipt;
  static bool? simulateServerSendConnectionConfigurationAsResponseOfConnectionRequest;

  FakeIOWsChannel({
    @factoryParam required String? serverUrl,
  }) : super(serverUrl ?? '');

  @override
  void wsClose() {

  }

  @override
  void wsConnect() {

  }



  static void configure ({
    void Function(ConfigureConnectionRequestCli request)? clientIsSendingConfigureConnectionRequestCli,
    void Function(ClientConfirmReceiptCli request)? clientIsSendingClientConfirmReceiptCli,
    void Function(CreateCli request)? clientIsSendingCreateCli,
    void Function(ReadCli request)? clientIsSendingReadCli,
    void Function(UpdateCli request)? clientIsSendingUpdateCli,
    void Function(DeleteCli request)? clientIsSendingDeleteCli,
    void Function(ListenCli request)? clientIsSendingListenCli,
    SimulateServerResponse? simulateServerResponseWithOutputParam,
    bool? simulateServerConfirmReceiptParam,
    bool? simulateServerSendConnectionConfigurationAsResponseOfConnectionRequestParam,
  }){
    if(simulateServerConfirmReceiptParam != null)
      simulateServerConfirmReceipt = simulateServerConfirmReceiptParam;
    if(simulateServerSendConnectionConfigurationAsResponseOfConnectionRequestParam != null)
      simulateServerSendConnectionConfigurationAsResponseOfConnectionRequest = simulateServerSendConnectionConfigurationAsResponseOfConnectionRequestParam;
    if(simulateServerResponseWithOutputParam != null)
      simulateServerResponseWithOutput = simulateServerResponseWithOutputParam;
    if(clientIsSendingConfigureConnectionRequestCli!=null)
      FakeIOWsChannel.clientIsSendingConfigureConnectionRequestCli = clientIsSendingConfigureConnectionRequestCli;
    if(clientIsSendingClientConfirmReceiptCli!=null)
      FakeIOWsChannel.clientIsSendingConfirmReceiptCli = clientIsSendingClientConfirmReceiptCli;
    if(clientIsSendingCreateCli!=null)
      FakeIOWsChannel.clientIsSendingCreateCli = clientIsSendingCreateCli;
    if(clientIsSendingReadCli!=null)
      FakeIOWsChannel.clientIsSendingReadCli = clientIsSendingReadCli;
    if(clientIsSendingUpdateCli!=null)
      FakeIOWsChannel.clientIsSendingUpdateCli = clientIsSendingUpdateCli;
    if(clientIsSendingDeleteCli!=null)
      FakeIOWsChannel.clientIsSendingDeleteCli = clientIsSendingDeleteCli;
    if(clientIsSendingListenCli!=null)
      FakeIOWsChannel.clientIsSendingListenCli = clientIsSendingListenCli;
  }

  static void reset(){
    FakeIOWsChannel.clientIsSendingListenCli = null;
    FakeIOWsChannel.clientIsSendingDeleteCli = null;
    FakeIOWsChannel.clientIsSendingUpdateCli = null;
    FakeIOWsChannel.clientIsSendingReadCli = null;
    FakeIOWsChannel.clientIsSendingCreateCli = null;
    FakeIOWsChannel.clientIsSendingConfirmReceiptCli = null;
    FakeIOWsChannel.clientIsSendingConfigureConnectionRequestCli = null;
    FakeIOWsChannel.simulateServerResponseWithOutput = null;
    FakeIOWsChannel.simulateServerSendConnectionConfigurationAsResponseOfConnectionRequest = null;
    FakeIOWsChannel.simulateServerConfirmReceipt = null;
  }

  @override
  bool get isReady => true;

  @override
  void sinkAdd({Mappable? map, String? data}) {
    super.sinkAdd(map: map, data: data);

    // if (map is AbstractRequestCli){
    //   if(map.requestType == RequestType.CREATE){
    //     clientIsSendingCreateCli?.call(map as CreateCli);
    //   }else if(map.requestType == RequestType.UPDATE){
    //     clientIsSendingUpdateCli?.call(map as UpdateCli);
    //   }else if(map.requestType == RequestType.DELETE){
    //     clientIsSendingDeleteCli?.call(map as DeleteCli);
    //   }else if(map.requestType == RequestType.READ){
    //     clientIsSendingReadCli?.call(map as ReadCli);
    //   }else if(map.requestType == RequestType.LISTEN) {
    //     clientIsSendingListenCli?.call(map as ListenCli);
    //   }else if(map.requestType == RequestType.CONFIRM_RECEIPT){
    //     clientIsSendingClientConfirmReceiptCli?.call(map as ClientConfirmReceiptCli);
    //   }else if(map.requestType == RequestType.CONFIGURE_CONNECTION){
    //     clientIsSendingConfigureConnectionRequestCli?.call(map as ConfigureConnectionRequestCli);
    //   }else {
    //     throw "TODO 1: request:"+map.requestType.toString() +'  ' + map.toMap().toString() + '  data:' + (data?.toString()??'null');
    //   }
    // }else if (data is PingPong){
    //
    // }{
    //   throw "TODO 2: request:"+(map?.toMap().toString() ?? 'null') +'  ' + '  data:' + (data?.toString()??'null');
    // }

    if (map is PingPong){

    } else {
      final request = map as AbstractRequestCli;

      if(simulateServerConfirmReceipt == true){
        handlingServerConfirmReceipt(request.clientRequestId);
      }
      if(simulateServerSendConnectionConfigurationAsResponseOfConnectionRequest == true && request.requestType == RequestType.CONFIGURE_CONNECTION){
        new ClientReceived.from(
            simulateConnectionConfigurationMapReceivedFromServer(request.clientRequestId)
        ).handle();
        clientIsSendingConfigureConnectionRequestCli?.call(request as ConfigureConnectionRequestCli);
      }

      simulateServerResponseWithOutput?.call(request, (output){
        if(request.requestType == RequestType.CONFIRM_RECEIPT){
          print('simulateServerResponseWithOutput: ignoring RequestType.CONFIRM_RECEIPT');
          return;
        }
        print('sending server response');
        ClientReceived.from({
          ResponseCli.type: '_',
          'serverId': 'serverId'+request.clientRequestId,
          'clientRequestId': request.clientRequestId,
          'requestType': request.requestType.toString().split('.').last,
          'output': output,
        }).handle();
      });

      if(request.requestType == RequestType.CREATE){
        clientIsSendingCreateCli?.call(request as CreateCli);
      }else if(request.requestType == RequestType.UPDATE){
        clientIsSendingUpdateCli?.call(request as UpdateCli);
      }else if(request.requestType == RequestType.DELETE){
        clientIsSendingDeleteCli?.call(request as DeleteCli);
      }else if(request.requestType == RequestType.READ){
        clientIsSendingReadCli?.call(request as ReadCli);
      }else if(request.requestType == RequestType.LISTEN) {
        clientIsSendingListenCli?.call(request as ListenCli);
      }else if(request.requestType == RequestType.CONFIRM_RECEIPT){
        clientIsSendingConfirmReceiptCli?.call(request as ClientConfirmReceiptCli);
      }else if(request.requestType == RequestType.CONFIGURE_CONNECTION){
        clientIsSendingConfigureConnectionRequestCli?.call(request as ConfigureConnectionRequestCli);
      }else {
        throw "TODO 1: request:"+request.requestType.toString() +'  ' + request.toMap().toString() + '  data:' + (data?.toString()??'null');
      }
    }

  }

  @override
  void wsHandleError(void Function(dynamic error)? handleError) {

  }

  @override
  void wsListen(void Function(dynamic data) param0, {void Function(dynamic err)? onError, void Function()? onDone}) {

  }

}

// Apagar acima e substituir por mockito + dependencie injection?

//Essa função seria auxiliar do mockito

// void onSink (map, {
//   void Function(ConfigureConnectionRequestCli request) clientIsSendingConfigureConnectionRequestCli,
//   void Function(CreateCli request) clientIsSendingCreateCli,
//   this.clientIsSendingReadCli,
//   this.clientIsSendingUpdateCli,
//   this.clientIsSendingDeleteCli,
//   this.clientIsSendingClientConfirmReceiptCli,
//   this.clientIsSendingListenCli,
// }){
//   if(map[AbstractRequestCli.fieldRequestType] == RequestType.CREATE.toString().split('.').last){
//     clientIsSendingCreateCli?.call(CreateCli.fromMap(map));
//   }else if(map[AbstractRequestCli.fieldRequestType] == RequestType.UPDATE.toString().split('.').last){
//     clientIsSendingUpdateCli?.call(UpdateCli.fromMap(map));
//   }else if(map[AbstractRequestCli.fieldRequestType] == RequestType.DELETE.toString().split('.').last){
//     this.clientIsSendingDeleteCli?.call(DeleteCli.fromMap(map));
//   }else if(map[AbstractRequestCli.fieldRequestType] == RequestType.READ.toString().split('.').last){
//     this.clientIsSendingReadCli?.call(ReadCli.fromMap(map));
//   }else if(map[ClientConfirmReceiptCli.fieldType] != null){
//     this.clientIsSendingClientConfirmReceiptCli?.call(ClientConfirmReceiptCli.fromMap(map));
//   }else if(map[ListenCli.fieldType] != null) {
//     this.clientIsSendingListenCli?.call(ListenCli.fromMap(map));
//   }else{
//     throw "TODO: "+map;
//   }
// }

Map<String,dynamic> simulateConnectionConfigurationMapReceivedFromServer (String clientRequestId) => {
  '_class_type_response': '_',
  'clientRequestId': clientRequestId,
  'serverId': 'serverId#123#',
  '_class_type_configureconnection': '_',
  'output': {
    'intervalInSecondsServerSendSameMessage': 11,
    'intervalInSecondsClientSendSameMessage': 22,
    'intervalInSecondsClientPing': 33,
    'reconnectClientAfterSecondsWithoutServerPong': 44,
    'isFromServer': true,
    'serverVersion': "1.0.0",
    'clientVersionCodeSupported': {
      'lessThanOrEqual': 1000,
      'moreThanOrEqual': 1,
    },
    'projectName': 'project',
    'requestTimeoutInSeconds': 55,
    'disconnectClientAfterSecondsWithoutClientPing': 66,
  }
};