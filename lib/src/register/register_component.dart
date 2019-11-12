import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../notifications.dart';

@Component(
  selector: 'register',
  directives: [
    coreDirectives,
    formDirectives,
    materialInputDirectives,
    MaterialButtonComponent,
    MaterialTooltipDirective,
    MaterialPaperTooltipComponent,
    MaterialTooltipTargetDirective,
    MaterialIconComponent,
    NgIf,
    MaterialIconTooltipComponent,
  ],
  providers: [
    popupBindings,
    materialTooltipBindings,
  ],
  styleUrls: [
    'register_component.scss.css',
    'package:copyclient_ng/styles/bottom_notification.scss.css',
    'package:angular_components/css/mdc_web/card/mdc-card.scss.css',
  ],
  templateUrl: 'register_component.html',
)
class RegisterComponent implements OnActivate, OnDeactivate {
  /// The current location of the router for calling back() on it
  Location location;

  /// The business logic for registering stays here
  AuthBloc authBloc;

  /// The position to display the tooltips right next to the input fields
  final preferredTooltipPositions = const [RelativePosition.OffsetBottomRight];

  /// The currently used [RegisterCredentials]
  RegisterCredentials creds = RegisterCredentials();

  /// The listener that reacts to new states in [AuthBloc] to navigate/show errors
  StreamSubscription<AuthState> authListener;

  Notifications notifications = Notifications();

  RegisterComponent(AuthProvider authProvider, this.location) {
    authBloc = authProvider.authBloc;
  }

  @override
  void onDeactivate(RouterState previous, RouterState current) {
    authListener.cancel();
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    authListener = authBloc.listen((AuthState state) async {
      if (state.isRegistered) {
        notifications.add(_registerSucessful(state.username));
        Future.delayed(const Duration(seconds: 3)).then((_) {
          creds = RegisterCredentials();
          location.back();
        });
      } else if (state.isException) {
        ApiException error = state.error as ApiException;

        if (error.statusCode == 470) {
          notifications.add(_nameUsed);
        } else if (error.statusCode == 471) {
          notifications.add(_forbiddenCharacters);
        } else if (error.statusCode >= 500) {
          notifications.add(_serverError);
        } else if (error.statusCode == 0) {
          notifications.add(_timeout);
        } else {
          notifications.add(error.toString());
        }
      }
    });
  }

  void onSubmitForm() {
    if (creds.password != creds.passwordRetype)
      notifications.add(_passwordMismatch);
    else if (creds.name.length < 2)
      notifications.add(_nameShort);
    else if (creds.password.length < 7)
      notifications.add(_passwordShort);
    else {
      authBloc.onRegister(creds.name.trim(), creds.password.trim());
      notifications.add(_registrationSubmitted);
    }
  }

  String _registerSucessful(String name) => Intl.message(
      'Registrierung als $name erfolgreich . Du wirst nun zum Login weitergeleitet.',
      args: [name],
      name: '_registerSucessful',
      desc:
          'Message to be shown if registration went well and the ui is returning to login window');

  String get _nameUsed =>
      Intl.message('Dieser Name ist leider schon vergeben, bitte probiere einen anderen.',
          name: '_nameUsed', desc: 'Notification to be shown if entered name is already used');

  String get _forbiddenCharacters => Intl.message(
      'Unerlaubte Zeichen im Namen/Passwort oder nicht übereinstimmende Passwörter. Bitte überprüfe deine Eingaben.',
      name: '_forbiddenCharacters',
      desc: 'Notification to be shown if username contains forbidden characters');

  String get _serverError =>
      Intl.message('Serverfehler - Bitte probiere es in einem Moment erneut.',
          name: '_serverError',
          desc: 'Notification to be shown if app receives a server error (500)');

  String get _timeout =>
      Intl.message('Zeitüberschreitung der Verbindung - Bitte prüfe deine Internetverbindung.',
          name: '_timeout',
          desc: 'Notification to  be shown if connection to server takes too long');

  String get _passwordMismatch => Intl.message('Die angegebenen Passwörter stimmen nicht überein',
      name: '_passwordMismatch',
      desc: 'Notification to be shown if the password confirmation on register page fails');

  String get _nameShort => Intl.message('Der Name ist zu kurz',
      name: '_nameShort',
      desc: 'Notification to be shown if the name to be registered is too short');

  String get _passwordShort => Intl.message('Das Passwort ist zu kurz',
      name: '_passwordShort', desc: 'Notification to be shown if password is too short');

  String get _registrationSubmitted => Intl.message('Registrierung wurde abgeschickt...',
      name: '_registrationSubmitted',
      desc: 'Notification to be shown if registration is submitted');
}

/// Object representation of the register form
class RegisterCredentials {
  String name;
  String password;
  String passwordRetype;

  RegisterCredentials({
    this.name = '',
    this.password = '',
    this.passwordRetype = '',
  });

  Map<String, String> toMap() => {
        'name': name,
        'password': password,
        'password_retype': passwordRetype,
      };

  @override
  String toString() => toMap().toString();
}
