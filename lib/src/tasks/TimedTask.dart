


import 'package:askless/src/index.dart';

abstract class TimedTask{
  int _intervalInSeconds;
  bool runTask = false;
  String taskName;

  TimedTask(this.taskName, int intervalInSeconds){
    this.changeInterval(intervalInSeconds);
  }

  changeInterval(int intervalInSeconds) {
    assert(intervalInSeconds > 0);
    this._intervalInSeconds = intervalInSeconds;
  }

  get intervalInSeconds => _intervalInSeconds;

  void run();

  void start(){
    _start();
  }

  Future<void> _start() async{
    onStart();
    Future.delayed(Duration(milliseconds: 100), () async{
      if(runTask){
        Internal.instance.logger(message:"Task '"+taskName+"' already started", level: Level.debug);
        return;
      }
      runTask = true;

      while(runTask){
        run();
        final lastIntervalInSeconds = intervalInSeconds;
        await Future.delayed(Duration(seconds: _intervalInSeconds));
        if(intervalInSeconds!=lastIntervalInSeconds)
          await Future.delayed(Duration(seconds: _intervalInSeconds));
      }
    });
  }

  void stop(){
    this.runTask = false;

    onStop();
  }

  onStop(){}
  onStart(){}

}
