import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:blocs_copyclient/preview.dart';
import 'package:blocs_copyclient/print_queue.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

import 'src/auth_guard.dart';
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

@Component(
  selector: 'copyclient',
  styleUrls: [
    'app_component.css',
    'package:angular_components/app_layout/layout.scss.css',
  ],
  templateUrl: 'app_component.html',
  directives: [
    routerDirectives,
    LoginComponent,
    JobListComponent,
    NgIf,
    DeferredContentDirective,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialPersistentDrawerDirective,
    MaterialListComponent,
    MaterialListItemComponent,
    MaterialListComponent,
    MaterialListItemComponent,
  ],
  providers: [
    AuthGuard,
    routerProvidersHash,
    ClassProvider(AuthProvider),
    ClassProvider(JoblistProvider),
    ClassProvider(PreviewProvider),
    ClassProvider(UploadsProvider),
    ClassProvider(PrintQueueProvider),
    ClassProvider(UserProvider),
    ClassProvider(PdfProvider),
    ClassProvider(http.Client, useClass: BrowserClient),
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

  /// The [User] as shown in the drawer header
  User user;

  /// The authorization state; true if [AuthBloc] yields authorized state
  bool authorized = false;

  /// Whether scanning link should be active in the drawer; defaults to false
  bool enableScanning = false;

  StreamSubscription<Event> uploadListener;
  StreamSubscription userListener;

  Timer refreshTimer;

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
    if (userListener != null) userListener.cancel();
    if (refreshTimer != null) refreshTimer.cancel();
  }

  @override
  void ngOnInit() {
    authBloc.state.listen(
      (AuthState state) {
        if (state.isAuthorized) {
          authorized = true;
          joblistBloc.onStart(state.token);
          uploadBloc.onStart(state.token);
          previewBloc.onStart(state.token);
          printQueueBloc.onStart(state.token);
          pdfBloc.onStart(state.token);
          userBloc.onStart(state.token);
          onLogin();
        } else if (state.isUnauthorized) {
          authorized = false;
        } else if (state.isException) {
          authorized = false;
        }
      },
    );

    // call [onLogout] if logout event from custom JS is received
    document.on["logout"].listen((Event event) {
      onLogout();
    });

    // check for direct printers to scan from
    enableScanning = (const String.fromEnvironment('leftPrinter', defaultValue: '').isNotEmpty ||
        const String.fromEnvironment('rightPrinter', defaultValue: '').isNotEmpty);
  }

  void onLogin() {
    // Listen for uploadJob event to be called by our custom JS
    uploadListener = document.on["uploadJob"].listen((Event event) {
      CustomEvent ce = (event as CustomEvent);

      // This converts event's payload from JSON to a Dart Map.
      Map<String, dynamic> payload = json.decode(ce.detail);
      String filename = payload['filename'];
      List<int> data = base64.decode(payload['data']);

      uploadBloc.onUpload(data, filename: filename);
    });

    // Tell our custom JS to start watching for fakeprinting
    document.dispatchEvent(CustomEvent("loggedIn"));

    // refresh user and joblist twice every minute to keep it synchronized
    refreshTimer = Timer.periodic(Duration(seconds: 30), (Timer t) {
      userBloc.onRefresh();
      joblistBloc.onRefresh();
    });

    // listen for new [User]s from the bloc and set local [user]
    userListener = userBloc.state.listen((UserState state) {
      if (state.isResult) {
        user = state.value;
      }
    });
  }

  void onLogout() {
    if (authorized) {
      window.localStorage.remove('token');
      if (authBloc != null) {
        authBloc.logout();
        var logoutListener;
        logoutListener = authBloc.state.listen((AuthState state) async {
          if (state.isUnauthorized) {
            _router.navigate(RoutePaths.login.path);
            document.dispatchEvent(CustomEvent("loggedOut"));
            logoutListener.cancel();
          }
        });
      }
      if (uploadListener != null) uploadListener.cancel();
      if (refreshTimer != null) refreshTimer.cancel();
    }
  }
}
