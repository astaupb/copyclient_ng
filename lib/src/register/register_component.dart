import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';

import '../providers/auth_provider.dart';

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
    '../../styles/bottom_notification.scss.css',
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

  /// Variables for notification throwing
  bool showNotification = false;
  String notificationText = '';

  RegisterComponent(AuthProvider authProvider, this.location) {
    authBloc = authProvider.authBloc;
  }

  @override
  void onDeactivate(RouterState previous, RouterState current) {
    authListener.cancel();
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    authListener = authBloc.state.listen((AuthState state) async {
      if (state.isRegistered) {
        notificationText =
            'Registrierung als ${state.username} erfolgreich . Du wirst nun zum Login weitergeleitet.';
        showNotification = true;
        Future.delayed(const Duration(seconds: 3)).then((_) {
          creds = RegisterCredentials();
          notificationText = '';
          showNotification = false;
          location.back();
        });
      } else if (state.isException) {
        ApiException error = state.error as ApiException;

        if (error.statusCode == 470) {
          notificationText =
              'Dieser Name ist leider schon vergeben, bitte probiere einen anderen.';
        } else if (error.statusCode == 471) {
          notificationText =
              'Unerlaubte Zeichen im Namen/Passwort oder nicht übereinstimmende Passwörter. Bitte überprüfe deine Eingaben.';
        } else if (error.statusCode >= 500) {
          notificationText =
              'Serverfehler - Bitte probiere es in einem Moment erneut.';
        } else if (error.statusCode == 0) {
          notificationText =
              'Zeitüberschreitung der Verbindung - Bitte prüfe deine Internetverbindung.';
        } else {
          notificationText = error.toString();
        }

        showNotification = true;
        Future.delayed(const Duration(seconds: 5)).then((_) {
          showNotification = false;
          notificationText = '';
        });
      }
    });
  }

  void onSubmitForm() {
    if (creds.password != creds.passwordRetype)
      notificationText = 'Die Passwörter stimmen nicht überein';
    else if (creds.name.length < 2)
      notificationText = 'Der Name ist zu kurz';
    else if (creds.password.length < 7)
      notificationText = 'Das Passwort ist zu kurz';
    else {
      authBloc.register(creds.name.trim(), creds.password.trim());
      notificationText = 'Registrierung wurde abgeschickt...';
    }
    showNotification = true;
    Future.delayed(const Duration(seconds: 3))
        .then((_) => showNotification = false);
  }
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
