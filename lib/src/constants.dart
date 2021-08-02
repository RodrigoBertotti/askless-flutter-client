
enum RequestType {
  LISTEN,
  CONFIRM_RECEIPT,
  CONFIGURE_CONNECTION,
  READ,
  CREATE,
  UPDATE,
  DELETE
}

const REQUEST_PREFIX = 'REQ-';
const LISTEN_PREFIX = 'LIS-';
const CLIENT_GENERATED_ID_PREFIX = 'CLIENT_GENERATED_ID-';

// TODO onupdate:
const CLIENT_LIBRARY_VERSION_NAME = '2.0.0';
const CLIENT_LIBRARY_VERSION_CODE = 3;

// TODO onupdate: CHECK README EN / PT  (# Add this line: askless: ^2.0.0)

// TODO onupdate: add changelog