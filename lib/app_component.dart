import 'dart:async';
import 'dart:convert';
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
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:blocs_copyclient/preview.dart';
import 'package:blocs_copyclient/print_queue.dart';
import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:http/browser_client.dart';
import 'package:http/src/client.dart';

import 'src/auth_guard.dart';
import 'src/backend_shiva.dart';
import 'src/fullscreen_spinner.dart';
import 'src/joblist/joblist_component.dart';
import 'src/login/login_component.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/joblist_provider.dart';
import 'src/providers/uploads_provider.dart';
import 'src/providers/preview_provider.dart';
import 'src/providers/print_queue_provider.dart';
import 'src/providers/user_provider.dart';
import 'src/providers/pdf_provider.dart';
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
    ClassProvider(JoblistProvider),
    ClassProvider(PreviewProvider),
    ClassProvider(UploadsProvider),
    ClassProvider(PrintQueueProvider),
    ClassProvider(UserProvider),
    ClassProvider(PdfProvider),
    ClassProvider(Backend, useClass: BackendShiva),
    ClassProvider(Client, useClass: BrowserClient),
  ],
  exports: [RoutePaths, Routes],
)
class AppComponent implements OnInit, OnDestroy {
  Router _router;

  AuthBloc authBloc;
  JoblistBloc joblistBloc;
  UploadBloc uploadBloc;
  PreviewBloc previewBloc;
  PrintQueueBloc printQueueBloc;
  UserBloc userBloc;
  PdfBloc pdfBloc;

  bool authorized = false;
  bool navOptionsVisible = false;
  RelativePosition popupPosition = RelativePosition.OffsetBottomLeft;
  bool customWidth = true;
  bool appBusy = false;
  StreamSubscription<Event> uploadListener;
  bool enableScanning = false;

  AppComponent(
      AuthProvider authProvider,
      JoblistProvider joblistProvider,
      UploadsProvider uploadsProvider,
      PreviewProvider previewProvider,
      PrintQueueProvider printQueueProvider,
      UserProvider userProvider,
      PdfProvider pdfProvider,
      this._router) {
    authBloc = authProvider.authBloc;
    joblistBloc = joblistProvider.joblistBloc;
    uploadBloc = uploadsProvider.uploadBloc;
    previewBloc = previewProvider.previewBloc;
    printQueueBloc = printQueueProvider.printQueueBloc;
    userBloc = userProvider.userBloc;
    pdfBloc = pdfProvider.pdfBloc;
  }

  @override
  void ngOnDestroy() {
    authBloc.dispose();
    joblistBloc.dispose();
    uploadBloc.dispose();
    previewBloc.dispose();
    printQueueBloc.dispose();
    userBloc.dispose();
    pdfBloc.dispose();
  }

  @override
  void ngOnInit() {
    authBloc.state.listen((AuthState state) {
      if (state.isBusy) {
        appBusy = true;
      } else if (state.isAuthorized) {
        authorized = true;
        appBusy = false;
        joblistBloc.onStart(state.token);
        uploadBloc.onStart(state.token);
        previewBloc.onStart(state.token);
        printQueueBloc.onStart(state.token);
        pdfBloc.onStart(state.token);
        userBloc.onStart(state.token);
        onLogin();
      } else if (state.isUnauthorized) {
        authorized = false;
        appBusy = false;
      } else if (state.isException) {
        appBusy = false;
        authorized = false;
      }
    });

    document.on["logout"].listen((Event event) {
      onLogout();
    });

    // check for direct printers to scan from
    enableScanning =
        (const String.fromEnvironment('leftPrinter', defaultValue: '')
                .isNotEmpty ||
            const String.fromEnvironment('rightPrinter', defaultValue: '')
                .isNotEmpty);
  }

  onLogin() {
    // Listen for uploadJob event to be called by our custom JS
    uploadListener = document.on["uploadJob"].listen((Event event) {
      CustomEvent ce = (event as CustomEvent);

      // This converts event's payload from JSON to a Dart Map.
      Map payload = jsonDecode(ce.detail);
      String filename = payload['filename'];
      List<int> data = base64Decode(payload['data']);

      uploadBloc.onUpload(data, filename: filename);
    });

    // Tell our custom JS to start watching for fakeprinting
    document.dispatchEvent(new CustomEvent("loggedIn"));
  }

  onLogout() {
    if (authorized) {
      if (authBloc != null) {
        authBloc.logout();
      }
      if (uploadListener != null) {
        uploadListener.cancel();
      }
      window.sessionStorage.remove('token');
      window.localStorage.remove('token');
    }
    document.dispatchEvent(new CustomEvent("loggedOut"));
    _router.navigate(RoutePaths.login.path);
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
