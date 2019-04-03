import 'dart:async';
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
import '../providers/uploads_provider.dart';
import '../route_paths.dart';

@Component(
  selector: 'joblist',
  styleUrls: [
    'joblist_component.scss.css',
    '../../styles/listpage_navigation.css',
    '../../styles/printer_selector.scss.css'
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
    MaterialSpinnerComponent,
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

  bool refreshing = true;

  /// last complete joblist known to this component
  List<Job> lastJobs = [];

  /// variables used for direct printing in kiosk mode
  bool directPrinter = false;
  String leftPrinter = '';
  String rightPrinter = '';
  int printingJob;
  String selectedPrinter = '';
  bool showSelectPrinter = false;

  JobListComponent(Backend backend, JoblistProvider joblistProvider, AuthProvider authProvider,
      UploadsProvider uploadsProvider, this._router, this.location)
      : super(authProvider, _router) {
    jobsBloc = joblistProvider.joblistBloc;
    uploadBloc = uploadsProvider.uploadBloc;
  }

  @override
  void onActivate(_, __) {
    onRefreshJobs();
    jobsBloc.state.listen((JoblistState state) {
      if (state.isResult) {
        refreshing = false;
        lastJobs = state.value;
      }
    });

    leftPrinter = const String.fromEnvironment('leftPrinter', defaultValue: '');

    rightPrinter = const String.fromEnvironment('rightPrinter', defaultValue: '');

    if (leftPrinter.isNotEmpty || rightPrinter.isNotEmpty) directPrinter = true;

    uploadBloc.state.listen((UploadState state) async {
      if (state.isResult) {
        if (state.value.isNotEmpty) {
          if (!state.value.first.isUploading) {
            await Future.delayed(const Duration(seconds: 1));
            uploadBloc.onRefresh();
          }
        } else {
          refreshing = true;
          await Future.delayed(const Duration(milliseconds: 1000));
          jobsBloc.onRefresh();
        }
      }
    });
  }

  void onDeleteJob(int id) {
    jobsBloc.onDeleteById(id);
  }

  void onKeepJob(int id) {
    JobOptions newOptions = jobsBloc.jobs.singleWhere((Job job) => job.id == id).jobOptions;
    newOptions.keep = !newOptions.keep;
    jobsBloc.onUpdateOptionsById(id, newOptions);
  }

  void onOpenPrintDialog(int id) {
    print('printing job with id $id');
    printingJob = id;
    if (leftPrinter.isNotEmpty && rightPrinter.isEmpty) {
      printJobLeft();
    } else if (rightPrinter.isNotEmpty && leftPrinter.isEmpty) {
      printJobRight();
    } else {
      showSelectPrinter = true;
    }
  }

  void onRefreshJobs() {
    refreshing = true;
    jobsBloc.onRefresh();
  }

  void onUploadFileSelected(List<File> files) {
    print(files.toString());

    files.forEach((File file) async {
      FileReader reader = FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoadEnd.listen(
        (ProgressEvent progress) {
          if (progress.loaded == progress.total) {
            uploadBloc.onUpload(reader.result as List<int>, filename: file.name);
          }
        },
      ).asFuture();
    });
  }

  void printJobLeft() {
    jobsBloc.onPrintById(leftPrinter, printingJob);
    showSelectPrinter = false;
  }

  void printJobRight() {
    jobsBloc.onPrintById(rightPrinter, printingJob);
    showSelectPrinter = false;
  }
}
