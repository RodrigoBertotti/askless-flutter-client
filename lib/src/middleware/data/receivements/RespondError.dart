


class ReqErrorCode{
  //Server:
  static const TIMEOUT = "TIMEOUT";
  static const NO_CONNECTION = "NO_CONNECTION";
  static const PERMISSION_DENIED= 'PERMISSION_DENIED';
  static const BAD_REQUEST = 'BAD_REQUEST';
  static const NEED_CONFIGURE_HEADERS= 'NEED_CONFIGURE_HEADERS';
  static const INTERNAL_ERROR = 'INTERNAL_ERROR';

  //Local:
  static const TOKEN_INVALID = 'TOKEN_INVALID';
  static const UNAUTHORIZED = 'UNAUTHORIZED';
}

class RespondError{
  late final String code;
  late final String description;
  late final dynamic stack; //Always null in production

  RespondError(this.code, this.description, {this.stack});

  RespondError.fromMap(map){
    this.code = map['code'] ?? 'none';
    this.description = map['description'] ?? 'none';
    this.stack = map['stack'];
  }
}