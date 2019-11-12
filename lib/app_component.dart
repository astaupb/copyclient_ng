import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/blocs.dart';
import 'package:blocs_copyclient/pdf_creation.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

import 'src/auth_guard.dart';
import 'src/joblist/joblist_component.dart';
import 'src/login/login_component.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/joblist_provider.dart';
import 'src/providers/journal_provider.dart';
import 'src/providers/pdf_creation_provider.dart';
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
    MaterialSpinnerComponent,
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
    ClassProvider(JournalProvider),
    ClassProvider(PdfCreationProvider),
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
  JournalBloc journalBloc;
  PdfCreationBloc pdfCreation;

  /// The [User] as shown in the drawer header
  User user;

  /// The authorization state; true if [AuthBloc] yields authorized state
  bool authorized = false;

  bool blockInterface = false;
  String blockedInterfaceText = '';

  StreamSubscription<Event> uploadListener;
  StreamSubscription userListener;
  StreamSubscription pdfCreationListener;

  Timer refreshTimer;

  AppComponent(
      AuthProvider authProvider,
      JoblistProvider joblistProvider,
      UploadsProvider uploadsProvider,
      PreviewProvider previewProvider,
      PrintQueueProvider printQueueProvider,
      UserProvider userProvider,
      PdfProvider pdfProvider,
      JournalProvider journalProvider,
      PdfCreationProvider pdfCreationProvider,
      this._router) {
    authBloc = authProvider.authBloc;
    joblistBloc = joblistProvider.joblistBloc;
    uploadBloc = uploadsProvider.uploadBloc;
    previewBloc = previewProvider.previewBloc;
    printQueueBloc = printQueueProvider.printQueueBloc;
    userBloc = userProvider.userBloc;
    pdfBloc = pdfProvider.pdfBloc;
    journalBloc = journalProvider.journalBloc;
    pdfCreation = pdfCreationProvider.pdfCreationBloc;
  }

  @override
  void ngOnDestroy() {
    authBloc.close();
    joblistBloc.close();
    uploadBloc.close();
    previewBloc.close();
    printQueueBloc.close();
    userBloc.close();
    pdfBloc.close();
    if (userListener != null) userListener.cancel();
    if (refreshTimer != null) refreshTimer.cancel();
  }

  @override
  void ngOnInit() {
    authBloc.listen(
      (AuthState state) {
        if (state.isAuthorized) {
          authorized = true;
          joblistBloc.onStart(state.token);
          uploadBloc.onStart(state.token);
          previewBloc.onStart(state.token);
          printQueueBloc.onStart(state.token);
          pdfBloc.onStart(state.token);
          userBloc.onStart(state.token);
          journalBloc.onStart(state.token);
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
  }

  void onLogin() {
    // Listen for uploadJob event to be called by our custom JS
    uploadListener = document.on["uploadJob"].listen((Event event) {
      CustomEvent ce = (event as CustomEvent);

      // This converts event's payload from JSON to a Dart Map.
      Map<String, dynamic> payload = json.decode(ce.detail);
      String filename = payload['filename'];
      bool a3 = payload.containsKey('a3') ? payload['a3'] : null;
      bool color = payload.containsKey('color') ? payload['color'] : null;
      int duplex = payload.containsKey('duplex') ? payload['duplex'] : null;
      int copies = payload.containsKey('copies') ? payload['copies'] : null;
      List<int> data = base64.decode(payload['data']);

      final String mime = lookupMimeType(filename, headerBytes: data.sublist(0, 8));
      if (mime.startsWith('image/')) {
        pdfCreation.onCreateFromImage(data);
        StreamSubscription listener;
        listener = pdfCreation.listen((PdfCreationState state) {
          if (state.isResult) {
            uploadBloc.onUpload(state.value,
                filename: filename, a3: a3, color: color, duplex: duplex, copies: copies);
            listener.cancel();
          }
        });
      } else if (mime.startsWith('text/')) {
        pdfCreation.onCreateFromText(utf8.decode(data));
        StreamSubscription listener;
        listener = pdfCreation.listen((PdfCreationState state) {
          if (state.isResult) {
            uploadBloc.onUpload(state.value,
                filename: filename, a3: a3, color: color, duplex: duplex, copies: copies);
            listener.cancel();
          }
        });
      } else if (mime == 'application/pdf') {
        uploadBloc.onUpload(data,
            filename: filename, a3: a3, color: color, duplex: duplex, copies: copies);
      }
    });

    // Tell our custom JS to start watching for fakeprinting
    document.dispatchEvent(CustomEvent("loggedIn"));

    // refresh user and joblist twice every minute to keep it synchronized
    refreshTimer = Timer.periodic(Duration(seconds: 30), (Timer t) {
      userBloc.onRefresh();
      joblistBloc.onRefresh();
    });

    // listen for new [User]s from the bloc and set local [user]
    userListener = userBloc.listen((UserState state) {
      if (state.isResult) {
        user = state.value;
      }
    });

    pdfCreationListener = pdfCreation.listen((PdfCreationState state) {
      print('PdfCreation receive: $state');
      if (state.isBusy) {
        blockedInterfaceText = 'Konvertiere Datei';
        blockInterface = true;
      } else if (state.isResult) {
        blockInterface = false;
      }
    });
  }

  void onChangeLocale() {
    if (window.localStorage.containsKey('locale') && window.localStorage['locale'] == 'en_US')
      window.localStorage['locale'] = 'de_DE';
    else
      window.localStorage['locale'] = 'en_US';
    window.location.reload();
  }

  void onLogout() {
    if (authorized) {
      window.localStorage.remove('token');
      if (authBloc != null) {
        authBloc.onLogout();
        var logoutListener;
        logoutListener = authBloc.listen((AuthState state) async {
          if (state.isUnauthorized) {
            _router.navigate(RoutePaths.login.path);
            document.dispatchEvent(CustomEvent("loggedOut"));
            logoutListener.cancel();
          }
        });
      }
      if (uploadListener != null) uploadListener.cancel();
      if (refreshTimer != null) refreshTimer.cancel();
      if (pdfCreationListener != null) pdfCreationListener.cancel();
    }
  }
}
