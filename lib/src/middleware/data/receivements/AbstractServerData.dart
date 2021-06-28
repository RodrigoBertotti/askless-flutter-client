


class AbstractServerData{
  static final srvServerId = 'serverId';

  String serverId;

  fromMap(messageMap){
    serverId = messageMap['serverId'];
  }
}