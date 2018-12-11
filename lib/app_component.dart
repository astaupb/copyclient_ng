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
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:http/browser_client.dart';
import 'package:http/src/client.dart';

import 'src/auth_guard.dart';
import 'src/auth_provider.dart';
import 'src/backend_sunrise.dart';
import 'src/fullscreen_spinner.dart';
import 'src/joblist/joblist_component.dart';
import 'src/login/login_component.dart';
import 'src/providers/uploads_provider.dart';
import 'src/route_paths.dart';
import 'src/routes.dart';

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
    routerDirectives,
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
    FullscreenSpinnerComponent,
  ],
  pipes: [BlocPipe],
  providers: [
    AuthGuard,
    popupBindings,
    routerProvidersHash,
    ClassProvider(AuthProvider),
    ClassProvider(UploadsProvider),
    ClassProvider(Backend, useClass: BackendSunrise),
    ClassProvider(Client, useClass: BrowserClient),
  ],
  exports: [RoutePaths, Routes],
)
class AppComponent implements OnInit, OnDestroy {
  AuthBloc authBloc;
  Location _location;
  Router _router;

  bool authorized = false;
  bool navOptionsVisible = false;
  RelativePosition popupPosition = RelativePosition.OffsetBottomLeft;
  bool customWidth = true;
  bool appBusy = false;

  AppComponent(AuthProvider auth, UploadsProvider uploads, this._location, this._router) {
    authBloc = auth.authBloc;
  }

  @override
  void ngOnDestroy() {
    authBloc.dispose();
  }

  @override
  void ngOnInit() {
    authBloc.state.listen((AuthState state) {
      if (state.isBusy) {
        appBusy = true;
      } else if (state.isAuthorized) {
        authorized = true;
        appBusy = false;
        _router.navigate(RoutePaths.joblist.path);
      } else if (state.isUnauthorized) {
        authorized = false;
        appBusy = false;
        _router.navigate(RoutePaths.login.path);
      } else if (state.isException) {
        appBusy = false;
        authorized = false;
      }
    });
  }

  onLogout() {
    authBloc.logout();
    window.sessionStorage.remove('token');
    window.localStorage.remove('token');
    document.dispatchEvent(new CustomEvent("unsetWatches"));
    document.dispatchEvent(new CustomEvent("unsetDragDrop"));
  }

  onOpenDialog() {
    document.dispatchEvent(new CustomEvent("showOpenPDF"));
  }
}

@Directive(
  selector: '[defaultPopupSizeProvider]',
  providers: [Provider(PopupSizeProvider, useFactory: createPopupSizeProvider)],
)
class DefaultPopupSizeProvider {}
