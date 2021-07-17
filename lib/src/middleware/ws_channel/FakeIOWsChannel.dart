


import 'package:askless/askless.dart';
import 'package:askless/src/constants.dart';
import 'package:askless/src/middleware/data/Mappable.dart';
import 'package:askless/src/middleware/data/connection/PingPong.dart';
import 'package:askless/src/middleware/ws_channel/AbstractIOWsChannel.dart';
import 'package:askless/src/middleware/data/receivements/ConfigureConnectionResponseCli.dart';
import 'package:askless/src/middleware/data/request/AbstractRequestCli.dart';
import 'package:askless/src/middleware/data/request/ClientConfirmReceiptCli.dart';
import 'package:askless/src/middleware/data/request/ConfigureConnectionRequestCli.dart';
import 'package:injectable/injectable.dart';



@Injectable(as: AbstractIOWsChannel, env: ['test'])
class FakeIOWsChannel extends AbstractIOWsChannel {

  static void Function(ConfigureConnectionRequestCli request)? serverResponseToConfigureConnectionRequestCli;
  static void Function(ClientConfirmReceiptCli request)? serverResponseToClientConfirmReceiptCli;
  static void Function(CreateCli request)? serverResponseToCreateCli;
  static void Function(ReadCli request)? serverResponseToReadCli;
  static void Function(UpdateCli request)? serverResponseToUpdateCli;
  static void Function(DeleteCli request)? serverResponseToDeleteCli;
  static void Function(ListenCli request)? serverResponseToListenCli;

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
    void Function(ConfigureConnectionRequestCli request)? serverResponseToConfigureConnectionRequestCli,
    void Function(ClientConfirmReceiptCli request)? serverResponseToClientConfirmReceiptCli,
    void Function(CreateCli request)? serverResponseToCreateCli,
    void Function(ReadCli request)? serverResponseToReadCli,
    void Function(UpdateCli request)? serverResponseToUpdateCli,
    void Function(DeleteCli request)? serverResponseToDeleteCli,
    void Function(ListenCli request)? serverResponseToListenCli,
  }){
    if(serverResponseToConfigureConnectionRequestCli!=null)
      FakeIOWsChannel.serverResponseToConfigureConnectionRequestCli = serverResponseToConfigureConnectionRequestCli;
    if(serverResponseToClientConfirmReceiptCli!=null)
      FakeIOWsChannel.serverResponseToClientConfirmReceiptCli = serverResponseToClientConfirmReceiptCli;
    if(serverResponseToCreateCli!=null)
      FakeIOWsChannel.serverResponseToCreateCli = serverResponseToCreateCli;
    if(serverResponseToReadCli!=null)
      FakeIOWsChannel.serverResponseToReadCli = serverResponseToReadCli;
    if(serverResponseToUpdateCli!=null)
      FakeIOWsChannel.serverResponseToUpdateCli = serverResponseToUpdateCli;
    if(serverResponseToDeleteCli!=null)
      FakeIOWsChannel.serverResponseToDeleteCli = serverResponseToDeleteCli;
    if(serverResponseToListenCli!=null)
      FakeIOWsChannel.serverResponseToListenCli = serverResponseToListenCli;
  }

  static void reset(){
    FakeIOWsChannel.serverResponseToListenCli = null;
    FakeIOWsChannel.serverResponseToDeleteCli = null;
    FakeIOWsChannel.serverResponseToUpdateCli = null;
    FakeIOWsChannel.serverResponseToReadCli = null;
    FakeIOWsChannel.serverResponseToCreateCli = null;
    FakeIOWsChannel.serverResponseToClientConfirmReceiptCli = null;
    FakeIOWsChannel.serverResponseToConfigureConnectionRequestCli = null;
  }

  @override
  bool get isReady => true;

  @override
  void sinkAdd({Mappable? map, String? data}) {
    super.sinkAdd(map: map, data: data);

    // if (map is AbstractRequestCli){
    //   if(map.requestType == RequestType.CREATE){
    //     serverResponseToCreateCli?.call(map as CreateCli);
    //   }else if(map.requestType == RequestType.UPDATE){
    //     serverResponseToUpdateCli?.call(map as UpdateCli);
    //   }else if(map.requestType == RequestType.DELETE){
    //     serverResponseToDeleteCli?.call(map as DeleteCli);
    //   }else if(map.requestType == RequestType.READ){
    //     serverResponseToReadCli?.call(map as ReadCli);
    //   }else if(map.requestType == RequestType.LISTEN) {
    //     serverResponseToListenCli?.call(map as ListenCli);
    //   }else if(map.requestType == RequestType.CONFIRM_RECEIPT){
    //     serverResponseToClientConfirmReceiptCli?.call(map as ClientConfirmReceiptCli);
    //   }else if(map.requestType == RequestType.CONFIGURE_CONNECTION){
    //     serverResponseToConfigureConnectionRequestCli?.call(map as ConfigureConnectionRequestCli);
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
      map = map as AbstractRequestCli;
      if(map.requestType == RequestType.CREATE){
        serverResponseToCreateCli?.call(map as CreateCli);
      }else if(map.requestType == RequestType.UPDATE){
        serverResponseToUpdateCli?.call(map as UpdateCli);
      }else if(map.requestType == RequestType.DELETE){
        serverResponseToDeleteCli?.call(map as DeleteCli);
      }else if(map.requestType == RequestType.READ){
        serverResponseToReadCli?.call(map as ReadCli);
      }else if(map.requestType == RequestType.LISTEN) {
        serverResponseToListenCli?.call(map as ListenCli);
      }else if(map.requestType == RequestType.CONFIRM_RECEIPT){
        serverResponseToClientConfirmReceiptCli?.call(map as ClientConfirmReceiptCli);
      }else if(map.requestType == RequestType.CONFIGURE_CONNECTION){
        serverResponseToConfigureConnectionRequestCli?.call(map as ConfigureConnectionRequestCli);
      }else {
        throw "TODO 1: request:"+map.requestType.toString() +'  ' + map.toMap().toString() + '  data:' + (data?.toString()??'null');
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
//   void Function(ConfigureConnectionRequestCli request) serverResponseToConfigureConnectionRequestCli,
//   void Function(CreateCli request) serverResponseToCreateCli,
//   this.serverResponseToReadCli,
//   this.serverResponseToUpdateCli,
//   this.serverResponseToDeleteCli,
//   this.serverResponseToClientConfirmReceiptCli,
//   this.serverResponseToListenCli,
// }){
//   if(map[AbstractRequestCli.fieldRequestType] == RequestType.CREATE.toString().split('.').last){
//     serverResponseToCreateCli?.call(CreateCli.fromMap(map));
//   }else if(map[AbstractRequestCli.fieldRequestType] == RequestType.UPDATE.toString().split('.').last){
//     serverResponseToUpdateCli?.call(UpdateCli.fromMap(map));
//   }else if(map[AbstractRequestCli.fieldRequestType] == RequestType.DELETE.toString().split('.').last){
//     this.serverResponseToDeleteCli?.call(DeleteCli.fromMap(map));
//   }else if(map[AbstractRequestCli.fieldRequestType] == RequestType.READ.toString().split('.').last){
//     this.serverResponseToReadCli?.call(ReadCli.fromMap(map));
//   }else if(map[ClientConfirmReceiptCli.fieldType] != null){
//     this.serverResponseToClientConfirmReceiptCli?.call(ClientConfirmReceiptCli.fromMap(map));
//   }else if(map[ListenCli.fieldType] != null) {
//     this.serverResponseToListenCli?.call(ListenCli.fromMap(map));
//   }else{
//     throw "TODO: "+map;
//   }
// }