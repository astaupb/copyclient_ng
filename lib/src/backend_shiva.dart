import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';

class BackendShiva implements Backend {
  final String host = 'astaprint.uni-paderborn.de';
  final String basePath = '/api/v1';
  final Client _innerClient = BrowserClient();

  Logger _log = Logger('BackendShiva');

  BackendShiva() {
    _log.fine('Creating Backend with ${_innerClient.toString()} as innerClient');
  }

  @override
  void close() {
    _log.fine('Closing Client: $_innerClient');
    _innerClient.close();
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    Request modRequest = Request(request.method, request.url);

    modRequest.persistentConnection = true;

    /// copy over headers from [request]
    for (String key in request.headers.keys) {
      modRequest.headers[key] = request.headers[key];
    }

    //modRequest.headers['Connection'] = 'keep-alive';

    /// copy over body from [request]
    if (request is Request) {
      modRequest.bodyBytes = request.bodyBytes;
    }

    /// send finalized request through [_innerClient] and return [StreamedResponse]
    return _innerClient.send(modRequest);
  }

  Map<String, String> toMap() => {
        'host': host,
        'basePath': basePath,
      };

  @override
  String toStringDeep() => toMap().toString();
}
