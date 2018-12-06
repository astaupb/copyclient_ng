import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:http/browser_client.dart';
import 'package:http/src/client.dart';

import 'src/backend_sunrise.dart';
import 'src/login/login_component.dart';

@Component(
    selector: 'copyclient',
    styleUrls: ['app_component.css'],
    templateUrl: 'app_component.html',
    directives: [
      LoginComponent,
      NgIf,
    ],
    pipes: [BlocPipe],
    providers: [
      ClassProvider(AuthProvider),
      ClassProvider(Backend, useClass: BackendSunrise),
      ClassProvider(Client, useClass: BrowserClient),
    ])
class AppComponent implements OnInit, OnDestroy {
  static AuthBloc authBloc;

  bool authorized = false;

  AppComponent(AuthProvider auth) {
    authBloc = auth.authBloc;
  }

  @override
  void ngOnDestroy() {
    authBloc.dispose();
  }

  @override
  void ngOnInit() {
    authBloc.state.listen((AuthState state) {
      if (state.isAuthorized) {
        print('authorized! ${state.token}');
        authorized = true;
      } else if (state.isUnauthorized) {
        print('unauthorized!');
        authorized = false;
      }
    });
  }

  onLogout() {
    authBloc.logout();
    window.sessionStorage['token'] = '';
  }
}

class AuthProvider {
  static final AuthProvider _singleton = AuthProvider._internal(
    AuthBloc(backend: BackendSunrise(BrowserClient())),
  );
  AuthBloc authBloc;
  factory AuthProvider(Backend backend) => _singleton;

  AuthProvider._internal(this.authBloc) {
    String storageToken = window.sessionStorage['token'] ?? '';
    if (storageToken.isNotEmpty) authBloc.tokenLogin(storageToken);
  }
}
