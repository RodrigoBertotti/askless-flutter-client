


class ReqErrorCode{
  //Server:
  static final TIMEOUT = "TIMEOUT";
  static final NO_CONNECTION = "NO_CONNECTION";
  static final PERMISSION_DENIED= 'PERMISSION_DENIED';
  static final BAD_REQUEST = 'BAD_REQUEST';
  static final NEED_CONFIGURE_HEADERS= 'NEED_CONFIGURE_HEADERS';
  static final INTERNAL_ERROR = 'INTERNAL_ERROR';

  //Local:
  static final TOKEN_INVALID = 'TOKEN_INVALID';
  static final UNAUTHORIZED = 'UNAUTHORIZED';
}

class RespondError{
  String code;
  String description;
  dynamic stack; //Always null in production

  RespondError(this.code, this.description, {this.stack});

  RespondError.fromMap(map){
    this.code = map['code'];
    this.description = map['description'];
    this.stack = map['stack'];
  }
}