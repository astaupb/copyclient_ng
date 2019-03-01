import 'dart:html';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_components/material_select/material_dropdown_select.dart';
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
    MaterialListItemComponent,
    MaterialDropdownSelectComponent,
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

  bool color;
  int duplex;
  int copies;
  bool collate;
  bool a3;
  String range;
  int nup;
  int nupPageOrder;
  bool keep;

  final List<String> duplexOptions = ['simplex', 'kurze Kante', 'lange Kante'];
  String duplexSelection = 'simplex';

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

  void setJobOptions(JobOptions options) {
    this.color = options.color;
    this.duplex = options.duplex;
    this.copies = options.copies;
    this.collate = options.collate;
    this.a3 = options.a3;
    this.range = options.range;
    this.nup = options.nup;
    this.nupPageOrder = options.nupPageOrder;
    this.keep = options.keep;
  }

  @override
  void onActivate(_, RouterState current) async {
    int id = getId(current.parameters);
    if (id != null) {
      joblistBloc.state.listen((state) {
        if (state.isResult) {
          job = state.value.singleWhere((Job job) => job.id == id);
          setJobOptions(job.jobOptions);
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
      if (joblistBloc.jobs != null && joblistBloc.jobs.isEmpty)
        joblistBloc.onRefresh();
    }
  }
}
