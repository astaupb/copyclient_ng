import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/exceptions.dart';

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
    authListener = authBloc.state.listen((AuthState state) async {
      if (state.isRegistered) {
        notifications.add('Registrierung als ${state.username} erfolgreich . Du wirst nun zum Login weitergeleitet.');
        Future.delayed(const Duration(seconds: 3)).then((_) {
          creds = RegisterCredentials();
          location.back();
        });
      } else if (state.isException) {
        ApiException error = state.error as ApiException;

        if (error.statusCode == 470) {
          notifications.add('Dieser Name ist leider schon vergeben, bitte probiere einen anderen.');
        } else if (error.statusCode == 471) {
          notifications.add('Unerlaubte Zeichen im Namen/Passwort oder nicht übereinstimmende Passwörter. Bitte überprüfe deine Eingaben.');
        } else if (error.statusCode >= 500) {
          notifications.add('Serverfehler - Bitte probiere es in einem Moment erneut.');
        } else if (error.statusCode == 0) {
          notifications.add('Zeitüberschreitung der Verbindung - Bitte prüfe deine Internetverbindung.');
        } else {
          notifications.add(error.toString());
        }
      }
    });
  }

  void onSubmitForm() {
    if (creds.password != creds.passwordRetype)
      notifications.add('Die Passwörter stimmen nicht überein');
    else if (creds.name.length < 2)
      notifications.add('Der Name ist zu kurz');
    else if (creds.password.length < 7)
      notifications.add('Das Passwort ist zu kurz');
    else {
      authBloc.register(creds.name.trim(), creds.password.trim());
      notifications.add('Registrierung wurde abgeschickt...');
    }
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
