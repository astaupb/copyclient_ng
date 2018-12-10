import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/src/models/job.dart';
import 'package:blocs_copyclient/src/job/job_bloc.dart';
import 'package:copyclient_ng/src/backend_sunrise.dart';
import 'package:http/browser_client.dart';

import '../route_paths.dart';
import '../auth_provider.dart';
import '../auth_guard.dart';

@Component(
  selector: 'jobdetails',
  templateUrl: 'jobdetails_component.html',
  styleUrls: ['jobdetails_component.css'],
  directives: [
    MaterialButtonComponent,
  ],
)
class JobDetailsComponent extends AuthGuard implements OnActivate {
  JobBloc _jobBloc;
  int id;
  Location _location;
  Job job;

  JobDetailsComponent(AuthProvider authProvider, Router router, this._location)
      : super(authProvider, router);

  @override
  void onActivate(_, RouterState current) async {
    id = getId(current.parameters);
    if (id != null)
      _jobBloc = JobBloc(
        BackendSunrise(BrowserClient()),
        window.localStorage['token'] ?? window.sessionStorage['token'],
        id: id,
      );
    _jobBloc.state
        .listen((state) => (state.isResult) ? job = state.value : null);
  }

  void goBack() => _location.back();
}
