import 'dart:html';

import 'package:angular/core.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:http/browser_client.dart';

import '../backend_sunrise.dart';

@Injectable()
class UploadsProvider {
  static String _token;
  static final UploadsProvider _singleton = UploadsProvider._internal(
    UploadBloc(BackendSunrise(BrowserClient()), _token),
  );

  UploadBloc uploadBloc;

  factory UploadsProvider() => _singleton;

  UploadsProvider._internal(this.uploadBloc) {
    _token =
        window.localStorage['token'] ?? window.sessionStorage['token'] ?? '';
  }
}
