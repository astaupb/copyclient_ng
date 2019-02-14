import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_checkbox/material_checkbox.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';

import '../providers/auth_provider.dart';
import '../route_paths.dart';

class Credentials {
  String username;
  String password;
  bool saveToken;

  Credentials({
    this.username = '',
    this.password = '',
    this.saveToken = false,
  });

  @override
  String toString() {
    return 'username: $username\npassword: $password';
  }
}

@Component(
  selector: 'login-form',
  styleUrls: [
    'login_component.css',
    'package:angular_components/css/mdc_web/card/mdc-card.scss.css',
  ],
  templateUrl: 'login_component.html',
  directives: [
    NgIf,
    coreDirectives,
    formDirectives,
    MaterialButtonComponent,
    MaterialInputComponent,
    MaterialCheckboxComponent,
    MaterialIconComponent,
    NgForm,
    NgFormControl,
    NgFormModel,
    materialInputDirectives,
  ],
  pipes: [BlocPipe],
)
class LoginComponent implements OnInit {
  static AuthBloc authBloc;
  Router _router;

  Credentials cred;

  bool showException = false;
  ApiException exception;

  LoginComponent(AuthProvider auth, this._router) {
    authBloc = auth.authBloc;
    cred = Credentials();
  }

  void clearForm() => cred = Credentials();

  @override
  void ngOnInit() async {
    authBloc.state.listen((AuthState state) async {
      if (state.isAuthorized) {
        window.sessionStorage['token'] = state.token;
        if (cred.saveToken) {
          window.localStorage['token'] = state.token;
        }
        _router.navigate(RoutePaths.joblist.path);
      } else if (state.isException) {
        showException = true;
        exception = state.error;
        await Future.delayed(Duration(seconds: 3));
        showException = false;
      }
    });
  }

  void submitForm() {
    print('submit form with $cred');
    authBloc.login(cred.username, cred.password);
  }

  /// TODO: implement password validation
  String validatePassword(String input) {
    return '';
  }

  /// TODO: implement username validation
  String validateUsername(String input) {
    return '';
  }
}
