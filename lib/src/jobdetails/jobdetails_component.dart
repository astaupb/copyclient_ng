import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/src/job/job_bloc.dart';
import 'package:blocs_copyclient/src/models/job.dart';
import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:copyclient_ng/src/backend_sunrise.dart';
import 'package:http/browser_client.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/joblist_provider.dart';
import '../route_paths.dart';

@Component(
  selector: 'jobdetails',
  templateUrl: 'jobdetails_component.html',
  styleUrls: [
    'package:angular_components/css/mdc_web/card/mdc-card.scss.css',
    'jobdetails_component.css'
  ],
  directives: [
    MaterialButtonComponent,
  ],
  pipes: [BlocPipe],
)
class JobDetailsComponent extends AuthGuard implements OnActivate {
  final Backend _backend;
  final JoblistProvider _joblistProvider;
  JobBloc jobBloc;
  Location _location;
  Job job;

  JobDetailsComponent(this._backend, this._joblistProvider, this._location,
      AuthProvider authProvider, Router router)
      : super(authProvider, router);

  void goBack() => _location.back();

  @override
  void onActivate(_, RouterState current) async {
    int id = getId(current.parameters);
    if (id != null) {
      if (_joblistProvider.joblistBloc.jobs == null)
        job =
            _joblistProvider.joblistBloc.jobs.firstWhere((job) => job.id == id);

      jobBloc = JobBloc(BackendSunrise(BrowserClient()));

      jobBloc.onStart(
          job, window.sessionStorage['token'] ?? window.localStorage['token']);

      jobBloc.state.listen((state) {
        if (state.isResult) {
          job = state.value;
        }
      });
    }
  }
}
