
class RequestType {
  static const LISTEN = 'LISTEN';
  static const CONFIRM_RECEIPT = 'CONFIRM_RECEIPT';
  static const CONFIGURE_CONNECTION = 'CONFIGURE_CONNECTION';
  static const READ = 'READ';
  static const CREATE = 'CREATE';
  static const UPDATE = 'UPDATE';
  static const DELETE = 'DELETE';
}

const REQUEST_PREFIX = 'REQ-';
const LISTEN_PREFIX = 'LIS-';
const CLIENT_GENERATED_ID_PREFIX = 'CLIENT_GENERATED_ID-';

//TODO onupdate:
const CLIENT_LIBRARY_VERSION_NAME = '1.0.0';
const CLIENT_LIBRARY_VERSION_CODE = 1;
