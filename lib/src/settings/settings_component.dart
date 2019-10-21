import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/laminate/components/modal/modal.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_components/material_select/material_dropdown_select.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/src/auth/auth_bloc.dart';
import 'package:blocs_copyclient/user.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../notifications.dart';

/// Object representation of the settings form
class Settings {
  String name;
  String password;
  String passwordRetype;
  String passwordOld;

  Settings({
    this.name = '',
    this.password = '',
    this.passwordRetype = '',
    this.passwordOld = '',
  });

  Map<String, String> toMap() => {
        'name': name,
        'password': password,
        'password_old': passwordOld,
        'password_retype': passwordRetype,
      };

  @override
  String toString() => toMap().toString();
}

@Component(
  selector: 'settings',
  templateUrl: 'settings_component.html',
  styleUrls: [
    'package:angular_components/css/mdc_web/card/mdc-card.scss.css',
    'settings_component.css',
    'package:copyclient_ng/styles/bottom_notification.scss.css',
  ],
  directives: [
    NgIf,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialToggleComponent,
    MaterialListItemComponent,
    MaterialListComponent,
    MaterialDropdownSelectComponent,
    MaterialFabComponent,
    MaterialInputComponent,
    materialInputDirectives,
    formDirectives,
    ModalComponent,
    MaterialDialogComponent,
    coreDirectives,
    MaterialTooltipDirective,
    MaterialInkTooltipComponent,
    MaterialPaperTooltipComponent,
    MaterialTooltipTargetDirective,
    NgIf,
  ],
  providers: [
    materialTooltipBindings,
    materialProviders,
  ],
  pipes: [
    DecimalPipe,
  ],
)
class SettingsComponent extends AuthGuard implements OnActivate, OnDeactivate {
  final Router _router;

  final AuthProvider authProvider;
  final UserProvider userProvider;

  UserBloc userBloc;

  StreamSubscription userListener;

  Notifications notifications = Notifications();

  User user;

  Settings settings = Settings();

  bool refreshing = false;

  AuthBloc authBloc;

  bool isUsernameChange = false;
  bool isPasswordChange = false;

  SettingsComponent(
    this.authProvider,
    this._router,
    this.userProvider,
  ) : super(authProvider, _router) {
    authBloc = authProvider.authBloc;
    userBloc = userProvider.userBloc;
  }

  @override
  void onActivate(_, RouterState current) async {
      userListener = userBloc.state.listen((UserState state) {
        if (isUsernameChange || isPasswordChange) {
          if (state.isResult) {
            user = state.value;
            settings = Settings();
            notifications.add((isPasswordChange ? 'Passwort' : 'Benutzername') + ' erfolgreich geändert');

            if (isPasswordChange) {
              authBloc.logout();
              window.localStorage.remove('token');
              window.location.reload();
            }
          } else if (state.isException) {
            ApiException e = (state.error as ApiException);
            final int statusCode = e != null ? e.statusCode : 499;

            if (isPasswordChange) {
              if (statusCode == 471)
                notifications.add('Das Passwort ist ungültig');
              else
                notifications.add('Konnte das Passwort nicht ändern: Unbekannter Fehler');
            } else {
              if (statusCode == 471)
                notifications.add('Der Benutzername ist ungültig');
              else if (statusCode == 472)
                notifications.add('Der Benutzername ist bereits vergeben');
              else
                notifications.add('Konnte den Benutzernamen nicht ändern: Unbekannter Fehler');
            }
          }
          isPasswordChange = false;
          isUsernameChange = false;
        }
      });
    }

  @override
  void onDeactivate(RouterState current, RouterState next) {
    userListener.cancel();
  }

  void onSubmitName() {
    isPasswordChange = false;
    isUsernameChange = true;
    if (settings.name.length < 2) {
      notifications.add('Der Benutzername ist zu kurz');
    } else {
      userBloc.onChangeUsername(settings.name);
    }
  }

  void onSubmitPassword() {
    isPasswordChange = true;
    isUsernameChange = false;
    if (settings.passwordOld.length < 1) {
      notifications.add('Bitte geben Sie Ihr aktuelles Passwort oder Ihre PIN ein');
    } else if (settings.password.length < 7) {
      notifications.add('Das neue Passwort ist zu kurz');
    } else if (settings.password != settings.passwordRetype) {
      notifications.add('Die neuen Passwörter stimmen nicht überein');
    } else {
      userBloc.onChangePassword(settings.passwordOld, settings.password);
    }
  }
}
