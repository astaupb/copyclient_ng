import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_components/material_select/material_dropdown_select.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_forms/angular_forms.dart';
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
    MaterialListComponent,
    MaterialDropdownSelectComponent,
    MaterialInputComponent,
    materialInputDirectives,
    formDirectives,
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

  bool color = true;
  int duplex = 0;
  int copies = 1;
  bool collate = false;
  bool a3 = false;
  String range = '';
  int nup = 1;
  int nupPageOrder = 1;
  bool keep = false;

  final List<String> duplexOptions = ['Simplex', 'Kurze Kante', 'Lange Kante'];
  String duplexSelection = 'Simplex';

  final List<String> nupOptions = ['1', '2', '4'];
  String nupSelection = '1';

  final List<String> nupOrderOptions = [
    'Nach Rechts, dann Runter',
    'Nach Unten, dann Rechts',
    'Nach Links, dann Runter',
    'Nach Unten, dann Links',
  ];
  String nupOrderSelection = 'Nach Rechts, dann Runter';

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
          setJobOptions(job.jobOptions);
          estimatedDouble = (job.priceEstimation as double) / 100.0;
          previewBloc.getPreview(job);
        }
      });

      previewBloc.state.skip(1).listen((PreviewState state) {
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

  void colorChecked() {
    color = !color;
    job.jobOptions.color = color;
    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
  }

  void duplexChanged(String selection) {
    duplexSelection = selection;
    duplex = duplexOptions.indexWhere((String option) => option == selection);
    job.jobOptions.duplex = duplex;
    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
  }

  void a3Checked() {
    a3 = !a3;
    job.jobOptions.a3 = a3;
    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
  }

  void collateChecked() {
    collate = !collate;
    job.jobOptions.collate = collate;
    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
  }

  void rangeChanged() {
    job.jobOptions.range = range;
    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
  }

  void copiesChanged() {
    job.jobOptions.copies = copies;
    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
  }

  void nupChanged(String selection) {
    nupSelection = selection;
    int index = nupOptions.indexWhere((String option) => option == selection);
    switch (index) {
      case 0:
        nup = 1;
        break;
      case 1:
        nup = 2;
        break;
      case 2:
        nup = 4;
        break;
      default:
        nup = 1;
        break;
    }
    job.jobOptions.nup = nup;
    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
  }

  void nupOrderChanged(String selection) {
    nupOrderSelection = selection;
    nupPageOrder =
        nupOrderOptions.indexWhere((String option) => option == selection);
    job.jobOptions.nup = nup;
    joblistBloc.onUpdateOptionsById(job.id, job.jobOptions);
  }
}
