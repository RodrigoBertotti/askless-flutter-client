import '../../index.dart';

/// Result of request attempt to the server.
class AsklessResponse {

  /// The output the server sent, or null.
  ///
  /// Do NOT use this field to check if the operation
  /// failed (because it can be null even in case of success)
  dynamic output;

  /// Error details in case where [success] == [false]
  AsklessError? error;

  AsklessResponse({this.output, this.error});

  /// Indicates whether the request attempt is a success
  bool get success => error == null;

}
