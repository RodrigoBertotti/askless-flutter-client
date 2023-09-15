import '../../index.dart';


class AsklessErrorModel extends AsklessError {

  AsklessErrorModel({required super.code, required super.description});

  factory AsklessErrorModel.fromMap(map){
    return AsklessErrorModel(
        code: map['code'] ?? 'none',
        description: map['description'] ?? 'none'
    );
  }
}