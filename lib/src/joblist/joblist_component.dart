import 'dart:core';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_button/material_fab.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:blocs_copyclient/upload.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/joblist_provider.dart';
import '../route_paths.dart';

@Component(
  selector: 'joblist',
  styleUrls: [
    'joblist_component.css',
    '../../styles/listpage_navigation.css',
  ],
  templateUrl: 'joblist_component.html',
  directives: [
    routerDirectives,
    coreDirectives,
    MaterialListComponent,
    MaterialListItemComponent,
    MaterialIconComponent,
    MaterialButtonComponent,
    MaterialFabComponent,
    MaterialDialogComponent,
    MaterialInputComponent,
    materialInputDirectives,
    ModalComponent,
  ],
  providers: [
    materialProviders,
  ],
  pipes: [commonPipes, BlocPipe],
  exports: [
    DateTime,
    jobDetailsUrl,
  ],
)
class JobListComponent extends AuthGuard implements OnActivate {
  JoblistBloc jobsBloc;
  UploadBloc uploadBloc;
  Location location;
  Router _router;

  int printingJob;
  String selectedPrinter = '';
  bool showSelectPrinter = false;

  bool refreshing = true;

  JobListComponent(Backend backend, JoblistProvider joblistProvider,
      AuthProvider authProvider, this._router, this.location)
      : super(authProvider, _router) {
    jobsBloc = joblistProvider.joblistBloc;
  }

  void deleteJob(int id) {
    jobsBloc.onDeleteById(id);
    jobsBloc.onRefresh();
  }

  void keepJob(int id) {
    JobOptions newOptions = jobsBloc.jobs.singleWhere((Job job) =>  job.id ==  id).jobOptions;
    newOptions.keep  = !newOptions.keep;
    jobsBloc.onUpdateOptionsById(id, newOptions);
  }

  @override
  void onActivate(_, __) {
    refreshJobs();
    jobsBloc.state.listen((JoblistState state) {
      if (state.isResult) {
        refreshing = false;
      }
    });
  }

  void printJobDialog(int id) {
    print('printing job with id $id');
    printingJob = id;
    showSelectPrinter = true;
  }

  void printJob() {
    jobsBloc.onPrintById(selectedPrinter, printingJob);
    showSelectPrinter = false;
  }

  void refreshJobs() {
    print('refresh those jobs dude');
    refreshing = true;
    jobsBloc.onRefresh();
  }

  void showJobDetails(int id) {
    print('showing job details for $id');
    _router.navigateByUrl(jobDetailsUrl(id));
  }
}
