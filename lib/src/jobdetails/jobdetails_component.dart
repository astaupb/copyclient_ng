import 'dart:html';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/src/job/job_bloc.dart';
import 'package:blocs_copyclient/src/models/job.dart';
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
    NgIf,
    MaterialButtonComponent,
    MaterialToggleComponent,
  ],
  pipes: [
    BlocPipe,
    DecimalPipe,
  ],
  exports: [base64Encode],
)
class JobDetailsComponent extends AuthGuard implements OnActivate {
  JoblistBloc joblistBloc;
  JobBloc jobBloc;
  Location _location;
  Job job;
  double estimatedDouble = 0.0;

  JobDetailsComponent(JoblistProvider joblistProvider, this._location,
      AuthProvider authProvider, Router router)
      : super(authProvider, router) {
    joblistBloc = joblistProvider.joblistBloc;
  }

  void goBack() => _location.back();

  @override
  void onActivate(_, RouterState current) async {
    int id = getId(current.parameters);
    if (id != null) {
      jobBloc = JobBloc(BackendSunrise(BrowserClient()));

      jobBloc.state.listen((state) {
        if (state.isResult) {
          job = state.value;
          estimatedDouble = (state.value.priceEstimation as double) / 100.0;
          if (job.previews.length == 0) jobBloc.onGetPreview();
        }
      });

      joblistBloc.state.listen((state) {
        if (state.isResult) {
          job = state.value.firstWhere((Job job) => job.id == id);
          jobBloc.onStart(job,
              window.sessionStorage['token'] ?? window.localStorage['token']);
        }
      });

      if (joblistBloc.jobs == null) {
        joblistBloc.onRefresh();
      }
    }
  }
}
