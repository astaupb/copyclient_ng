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
import 'package:blocs_copyclient/src/models/joboptions.dart';
import 'package:copyclient_ng/src/tokens/tokens_component.dart';
import 'package:intl/intl.dart';

import '../auth_guard.dart';
import '../notifications.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../route_paths.dart';
import 'settings.dart';

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
    TokensComponent,
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
  final AuthProvider authProvider;
  final UserProvider userProvider;

  final Router _router;

  UserBloc userBloc;

  StreamSubscription userListener;

  Notifications notifications = Notifications();

  User user;

  bool refreshing = false;

  AuthBloc authBloc;

  bool isUsernameChange = false;
  bool isPasswordChange = false;
  bool isFetchingOptions = false;

  JobOptions defaultOptions;
  JobOptions newOptions = JobOptions();
  Settings settings = Settings();

  SettingsComponent(
    this.authProvider,
    this._router,
    this.userProvider,
  ) : super(authProvider, _router) {
    authBloc = authProvider.authBloc;
    userBloc = userProvider.userBloc;
  }

  String get _enterCurrentPw => Intl.message(
      'Bitte geben Sie Ihr aktuelles Passwort oder Ihre PIN ein',
      name: '_enterCurrentPw',
      desc: 'notify user that he/she should enter the current password to confirm its the user');

  String get _passwordChangeSuccess => Intl.message('Passwort erfolgreich geändert',
      name: '_passwordChangeSuccess',
      desc: 'Notify user that password or user change was a success');

  String get _passwordInvalid => Intl.message('Das Passwort ist ungültig',
      name: '_passwordInvalid', desc: 'Notify user that entered password is invalid');

  String get _passwordMismatch => Intl.message('Die neuen Passwörter stimmen nicht überein',
      name: '_passwordMismatch', desc: 'Notify user that the entered password is too short');

  String get _passwordTooShort => Intl.message('Das neue Passwort ist zu kurz',
      name: '_passwordTooShort', desc: 'Notify user that the entered new password is too short');

  String get _pwUnknownError => Intl.message('Konnte das Passwort nicht ändern: Unbekannter Fehler',
      name: '_pwUnknownError',
      desc: 'Notify user that password could not be changed due to unknown error');

  String get _usernameChangeSuccess => Intl.message('Benutzername erfolgreich geändert',
      name: '_usernameChangeSuccess',
      desc: 'Notify user that password or user change was a success');

  String get _usernameInvalid => Intl.message('Der Benutzername ist ungültig',
      name: '_usernameInvalid', desc: 'Notify user that the entered username is invalid');

  String get _usernameTaken => Intl.message('Der Benutzername ist bereits vergeben',
      name: '_usernameTaken', desc: 'Notify user that thee entered username is already taken');

  String get _usernameTooShort => Intl.message('Der Benutzername ist zu kurz',
      name: '_usernameTooShort', desc: 'Notify user that the entered name is too short');

  String get _usernameUnknownError =>
      Intl.message('Konnte den Benutzernamen nicht ändern: Unbekannter Fehler',
          name: '_usernameUnknownError',
          desc: 'Notify user that username could not be changed due to an unknown error');

  final List<String> duplexOptions = [_simplex, _longBorder, _shortBorder];
  String duplexSelection = _simplex;

  static String get _simplex =>
      Intl.message('Simplex', name: '_simplex', desc: 'Dropdown menu selection for simplex');
  static String get _longBorder => Intl.message('Lange Kante',
      name: '_longBorder', desc: 'Dropdown menu selection for duplexing at long border');
  static String get _shortBorder => Intl.message('Kurze Kante',
      name: '_shortBorder', desc: 'Dropdown menu selection for duplexing at short border');

  List<String> nupOptions = ['1', '2', '4'];
  String nupSelection = '1';

  final List<String> nupOrderOptions = [_nupOrder1, _nupOrder2, _nupOrder3, _nupOrder4];
  String nupOrderSelection = _nupOrder1;

  static String get _nupOrder1 => Intl.message('Nach Rechts, dann Runter', name: '_nupOrder1');
  static String get _nupOrder2 => Intl.message('Nach Unten, dann Rechts', name: '_nupOrder2');
  static String get _nupOrder3 => Intl.message('Nach Links, dann Runter', name: '_nupOrder3');
  static String get _nupOrder4 => Intl.message('Nach Unten, dann Links', name: '_nupOrder4');

  @override
  void onActivate(_, RouterState current) async {
    userListener = userBloc.listen((UserState state) {
      if (isUsernameChange || isPasswordChange) {
        if (state.isResult) {
          user = state.value;
          settings = Settings();
          notifications.add((isPasswordChange ? _passwordChangeSuccess : _usernameChangeSuccess));

          if (isPasswordChange) {
            authBloc.onLogout();
            window.localStorage.remove('token');
            window.location.reload();
          }
        } else if (state.isException) {
          ApiException e = (state.error as ApiException);
          final int statusCode = e != null ? e.statusCode : 499;

          if (isPasswordChange) {
            if (statusCode == 471)
              notifications.add(_passwordInvalid);
            else
              notifications.add(_pwUnknownError);
          } else {
            if (statusCode == 471)
              notifications.add(_usernameInvalid);
            else if (statusCode == 472)
              notifications.add(_usernameTaken);
            else
              notifications.add(_usernameUnknownError);
          }
        }
        isPasswordChange = false;
        isUsernameChange = false;
      } else if (isFetchingOptions) {
        if (state.isResult) {
          defaultOptions = state.value.options;
          if (defaultOptions != null) {
            newOptions.a3 = defaultOptions.a3;
            newOptions.color = defaultOptions.color;
            newOptions.collate = defaultOptions.collate;
            newOptions.duplex = defaultOptions.duplex;
            newOptions.nup = defaultOptions.nup;
            newOptions.nupPageOrder = defaultOptions.nupPageOrder;
            newOptions.copies = defaultOptions.copies;
            duplexSelection = duplexOptions[defaultOptions.duplex];
            nupSelection = defaultOptions.nup.toString();
            isFetchingOptions = false;
          }
        }
      }
    });
    userBloc.onGetOptions();
    isFetchingOptions = true;
  }

  @override
  void onDeactivate(RouterState current, RouterState next) {
    userListener.cancel();
  }

  void onSubmitName() {
    isPasswordChange = false;
    isUsernameChange = true;
    if (settings.name.length < 2) {
      notifications.add(_usernameTooShort);
    } else {
      userBloc.onChangeUsername(settings.name);
    }
  }

  void onSubmitPassword() {
    isPasswordChange = true;
    isUsernameChange = false;
    if (settings.passwordOld.length < 1) {
      notifications.add(_enterCurrentPw);
    } else if (settings.password.length < 7) {
      notifications.add(_passwordTooShort);
    } else if (settings.password != settings.passwordRetype) {
      notifications.add(_passwordMismatch);
    } else {
      userBloc.onChangePassword(settings.passwordOld, settings.password);
    }
  }

  void colorChecked() {
    newOptions.color = !newOptions.color;
    if (defaultOptions != null) defaultOptions.color = newOptions.color;
  }

  void a3Checked() {
    newOptions.a3 = !newOptions.a3;
    if (defaultOptions != null) defaultOptions.a3 = newOptions.a3;
  }

  void collateChecked() {
    newOptions.collate = !newOptions.collate;
    if (defaultOptions != null) defaultOptions.collate = newOptions.collate;
  }

  void duplexChanged(String selection) {
    duplexSelection = selection;
    newOptions.duplex = duplexOptions.indexWhere((String option) => option == selection);
    if (defaultOptions != null) defaultOptions.duplex = newOptions.duplex;
  }

  void copiesChanged() {
    if (defaultOptions != null) defaultOptions.copies = newOptions.copies;
  }

  void nupChanged(String selection) {
    nupSelection = selection;
    int index = nupOptions.indexWhere((String option) => option == selection);
    switch (index) {
      case 0:
        newOptions.nup = 1;
        break;
      case 1:
        newOptions.nup = 2;
        break;
      case 2:
        newOptions.nup = 4;
        break;
      default:
        newOptions.nup = 1;
        break;
    }
    if (defaultOptions != null) defaultOptions.nup = newOptions.nup;
  }

  void nupOrderChanged(String selection) {
    nupOrderSelection = selection;
    newOptions.nupPageOrder = nupOrderOptions.indexWhere((String option) => option == selection);
    if (defaultOptions != null) defaultOptions.nupPageOrder = newOptions.nupPageOrder;
  }

  void onSubmitOptions() {
    userBloc.onChangeOptions(defaultOptions);
    print('Foobar');
  }

  void onOpenTokens() {
    _router.navigate(RoutePaths.tokens.path);
  }
}
