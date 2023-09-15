enum Level { info, debug, error, warning }
typedef LoggerFunction = void Function (dynamic message, Level level, {dynamic additionalData});

class Logger{
  Logger({required bool debugLogs}){
    doLog = (message, Level level, {additionalData})  {
      if (level != Level.debug || debugLogs) {
        print("Askless [${level.toString().split(".").last.toUpperCase()}]: $message");
        if (additionalData != null) {
          print(additionalData.toString());
        }
      }
    };
    if (debugLogs) {
      doLog(
        '**********************************************************************************' +
        '** WARNING: debugLogs is true, set it to false in a production environment      **                                       **\n' +
        '**********************************************************************************',
        Level.warning,
      );
    }
  }

  late final LoggerFunction doLog;
}

LoggerFunction? _doLog;
void setAsklessLogger (Logger logger) {_doLog = logger.doLog; }
void logger(String message, {Level level=Level.debug, additionalData}) {
  if (_doLog != null) {
    _doLog!(message, level, additionalData: additionalData);
  }
}
