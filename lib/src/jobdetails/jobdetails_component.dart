import 'dart:html';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/preview.dart';
import 'package:blocs_copyclient/src/models/job.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/joblist_provider.dart';
import '../providers/preview_provider.dart';
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
  PreviewBloc previewBloc;
  Location _location;
  Job job;
  double estimatedDouble = 0.0;
  List<List<int>> previews;

  JobDetailsComponent(
      JoblistProvider joblistProvider,
      PreviewProvider previewProvider,
      this._location,
      AuthProvider authProvider,
      Router router)
      : super(authProvider, router) {
    joblistBloc = joblistProvider.joblistBloc;
    previewBloc = previewProvider.previewBloc;
  }

  void goBack() => _location.back();

  @override
  void onActivate(_, RouterState current) async {
    int id = getId(current.parameters);
    if (id != null) {
      joblistBloc.state.listen((state) {
        if (state.isResult) {
          job = state.value.singleWhere((Job job) => job.id == id);
          estimatedDouble = (job.priceEstimation as double) / 100.0;
          previewBloc.getPreview(job);
        }
      });
      previewBloc.state.listen((PreviewState state) {
        if (state.isResult) {
          previews = state.value
              .singleWhere((previewSet) => previewSet.jobId == id)
              .previews;
        }
      });
      if (joblistBloc.jobs.isEmpty) {
        joblistBloc.onRefresh();
      }
    }
  }
}
