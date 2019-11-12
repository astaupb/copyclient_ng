import 'dart:html';

import 'package:angular/angular.dart';
import 'package:blocs_copyclient/auth.dart';

import '../backend_shiva.dart';

@Injectable()
class AuthProvider {
  static final AuthProvider _singleton = AuthProvider._internal(
    AuthBloc(backend: BackendShiva()),
  );
  AuthBloc authBloc;
  factory AuthProvider() => _singleton;

  AuthProvider._internal(this.authBloc) {
    String storageToken = window.localStorage['token'] ?? '';
    if (storageToken.isNotEmpty) authBloc.onTokenLogin(storageToken);
  }
}
