import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:angular_components/app_layout/material_persistent_drawer.dart';
import 'package:angular_components/content/deferred_content.dart';
import 'package:angular_components/laminate/enums/alignment.dart';
import 'package:angular_components/laminate/popup/module.dart';
import 'package:angular_components/laminate/popup/popup.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_components/material_popup/material_popup.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:http/browser_client.dart';
import 'package:http/src/client.dart';

import 'src/backend_sunrise.dart';
import 'src/joblist/joblist_component.dart';
import 'src/login/login_component.dart';

@Injectable()
PopupSizeProvider createPopupSizeProvider() {
  return PercentagePopupSizeProvider();
}

@Component(
    selector: 'copyclient',
    styleUrls: [
      'app_component.css',
      'package:angular_components/app_layout/layout.scss.css',
    ],
    templateUrl: 'app_component.html',
    directives: [
      DefaultPopupSizeProvider,
      LoginComponent,
      JobListComponent,
      NgIf,
      DeferredContentDirective,
      MaterialButtonComponent,
      MaterialIconComponent,
      MaterialPersistentDrawerDirective,
      MaterialListComponent,
      MaterialListItemComponent,
      MaterialPopupComponent,
      PopupSourceDirective,
      MaterialListComponent,
      MaterialListItemComponent,
    ],
    pipes: [BlocPipe],
    providers: [
      popupBindings,
      ClassProvider(AuthProvider),
      ClassProvider(Backend, useClass: BackendSunrise),
      ClassProvider(Client, useClass: BrowserClient),
    ])
class AppComponent implements OnInit, OnDestroy {
  static AuthBloc authBloc;

  bool authorized = false;
  bool navOptionsVisible = false;
  RelativePosition popupPosition = RelativePosition.OffsetBottomLeft;
  bool customWidth = true;

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
        authorized = true;
      } else if (state.isUnauthorized) {
        authorized = false;
      }
    });
  }

  onLogout() {
    authBloc.logout();
    window.sessionStorage['token'] = '';
    window.localStorage['token'] = '';
  }
}

class AuthProvider {
  static final AuthProvider _singleton = AuthProvider._internal(
    AuthBloc(backend: BackendSunrise(BrowserClient())),
  );
  AuthBloc authBloc;
  factory AuthProvider(Backend backend) => _singleton;

  AuthProvider._internal(this.authBloc) {
    String storageToken =
        window.localStorage['token'] ?? window.sessionStorage['token'] ?? '';
    if (storageToken.isNotEmpty) authBloc.tokenLogin(storageToken);
  }
}

@Directive(
  selector: '[defaultPopupSizeProvider]',
  providers: [Provider(PopupSizeProvider, useFactory: createPopupSizeProvider)],
)
class DefaultPopupSizeProvider {}
