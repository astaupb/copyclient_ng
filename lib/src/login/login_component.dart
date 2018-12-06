import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/src/models/backend.dart';

import '../../app_component.dart';

class Credentials {
  String username;
  String password;
  bool saveToken;

  Credentials({
    this.username,
    this.password,
    this.saveToken = false,
  });

  @override
  String toString() {
    return 'username: $username\npassword: $password';
  }
}

@Component(
  selector: 'login-form',
  styleUrls: ['login_component.css'],
  templateUrl: 'login_component.html',
  directives: [formDirectives],
  pipes: [BlocPipe],
)
class LoginComponent implements OnInit {
  static AuthBloc authBloc;

  Credentials cred;

  LoginComponent(AuthProvider auth) {
    authBloc = auth.authBloc;
    cred = Credentials();
  }

  @override
  void ngOnInit() async {
    authBloc.state.listen(
      (AuthState state) {
          if (state.isAuthorized) {
            window.sessionStorage['token'] = state.token;
            if (cred.saveToken) {
              window.localStorage['token'] = state.token;
            }
          }
      }
    );
  }

  void submitForm() {
    authBloc.login(cred.username, cred.password);
  }
}
