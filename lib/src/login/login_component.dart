import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_checkbox/material_checkbox.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:copyclient_ng/messages/messages_en.dart';
import 'package:intl/intl.dart';

import '../notifications.dart';
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
    routerDirectives,
    MaterialButtonComponent,
    MaterialInputComponent,
    MaterialCheckboxComponent,
    MaterialIconComponent,
    NgForm,
    NgFormControl,
    NgFormModel,
    MaterialTooltipDirective,
    MaterialInkTooltipComponent,
    MaterialTooltipTargetDirective,
    materialInputDirectives,
  ],
  providers: [
    popupBindings,
    materialTooltipBindings,
  ],
  pipes: [],
  exports: [RoutePaths],
)
class LoginComponent implements OnInit {
  static AuthBloc authBloc;
  Router _router;

  Credentials cred;

  Notifications notifications = Notifications();

  LoginComponent(AuthProvider auth, this._router) {
    authBloc = auth.authBloc;
    cred = Credentials();
  }

  String get _errorTimeout => Intl.message(
      'Zeitüberschreitung beim Login - Bitte überprüfe deine Internetverbindung',
      name: '_errorTimeout',
      desc: 'Notify user that the connection timed out');

  String get _forbiddenCharacters => Intl.message(
      'Nicht erlaubte Zeichen im Nutzernamen oder Passwort',
      name: '_forbiddenCharacters',
      desc:
          'Notify user that the username/password that was entered contains forbidden characters');

  String get _serverError =>
      Intl.message('Serverfehler - Bitte versuche es in einem Moment noch mal',
          name: '_serverError', desc: 'Notify user about server error');

  String get _wrongCredentials => Intl.message('Username oder Passwort falsch',
      name: '_wrongCredentials',
      desc: 'Notify user that the entered credentials are wrong');

  void clearForm() => cred = Credentials();

  @override
  void ngOnInit() async {
    authBloc.state.listen((AuthState state) async {
      if (state.isAuthorized) {
        if (cred.saveToken) {
          window.localStorage['token'] = state.token;
        }
        _router.navigate(RoutePaths.joblist.path);
      } else if (state.isException) {
        final ApiException error = state.error as ApiException;
        if (error.statusCode == 0) {
          notifications.add(_errorTimeout);
        } else if (error.statusCode == 400) {
          notifications.add(_forbiddenCharacters);
        } else if (error.statusCode == 401) {
          notifications.add(_wrongCredentials);
        } else if (error.statusCode >= 500) {
          notifications.add(_serverError);
        }
      }
    });
  }

  void submitForm() {
    print('submit form with $cred');
    authBloc.login(cred.username.trim(), cred.password.trim());
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
