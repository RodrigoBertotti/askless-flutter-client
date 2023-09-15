import '../domain/utils/logger.dart';

abstract class TimedTask{
  late int _intervalInMs;
  bool runTask = false;
  String taskName;

  TimedTask(this.taskName, int intervalInSeconds){
    changeInterval(intervalInSeconds);
  }

  changeInterval(int intervalInMs) {
    assert(intervalInMs > 0);
    _intervalInMs = intervalInMs;
  }

  int get intervalInMs => _intervalInMs;

  void run();

  Future<void> start() async {
    _start();
  }

  Future<void> _start() async{
    onStart();
    Future.delayed(const Duration(milliseconds: 100), () async{
      if(runTask){
        logger("Task '$taskName' already started", level: Level.debug);
        return;
      }
      runTask = true;

      while (runTask){
        run();
        final _lastIntervalInMs = intervalInMs;
        await Future.delayed(Duration(milliseconds: _intervalInMs));
        if(intervalInMs!=_lastIntervalInMs) {
          await Future.delayed(Duration(milliseconds: _intervalInMs));
        }
      }
    });
  }

  void stop(){
    runTask = false;

    onStop();
  }

  onStop(){}
  onStart(){}

}
