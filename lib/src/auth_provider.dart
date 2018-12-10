import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:http/browser_client.dart';

import 'backend_sunrise.dart';
import 'route_paths.dart';

@Injectable()
class AuthProvider {
  static final AuthProvider _singleton = AuthProvider._internal(
    AuthBloc(backend: BackendSunrise(BrowserClient())),
  );
  AuthBloc authBloc;
  factory AuthProvider(Backend backend) => _singleton;

  AuthProvider._internal(this.authBloc) {
    String storageToken =
        window.localStorage['token'] ?? window.sessionStorage['token'] ?? '';
    if (storageToken.isNotEmpty) authBloc.tokenLogin(storageToken);
  }
}
