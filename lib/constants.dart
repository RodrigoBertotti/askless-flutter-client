
enum RequestType {
  LISTEN,
  CONFIRM_RECEIPT,
  CONFIGURE_CONNECTION,
  AUTHENTICATE,
  READ,
  CREATE,
  UPDATE,
  DELETE
}

const REQUEST_PREFIX = 'REQ-';
const LISTEN_PREFIX = 'LIS-';

// TODO onupdate:
const CLIENT_LIBRARY_VERSION_NAME = '3.1.0';
const CLIENT_LIBRARY_VERSION_CODE = 7;

// TODO onupdate: CHECK README  (# Add this line: askless: ^3.1.0)

// TODO onupdate: add changelog
