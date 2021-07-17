


class AbstractServerData{
  static const srvServerId = 'serverId';

  late final String serverId;

  fromMap(messageMap){
    serverId = messageMap['serverId'];
  }
}