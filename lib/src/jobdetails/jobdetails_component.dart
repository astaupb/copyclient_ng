import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/laminate/components/modal/modal.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_components/material_select/material_dropdown_select.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:blocs_copyclient/preview.dart';
import 'package:blocs_copyclient/src/models/job.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:copyclient_ng/src/providers/user_provider.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/joblist_provider.dart';
import '../providers/preview_provider.dart';
import '../providers/pdf_provider.dart';
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
    MaterialIconComponent,
    MaterialToggleComponent,
    MaterialListItemComponent,
    MaterialListComponent,
    MaterialDropdownSelectComponent,
    MaterialInputComponent,
    materialInputDirectives,
    formDirectives,
    ModalComponent,
    MaterialDialogComponent,
    coreDirectives,
  ],
  providers: [
    materialProviders,
  ],
  pipes: [
    BlocPipe,
    DecimalPipe,
  ],
  exports: [base64Encode],
)
class JobDetailsComponent extends AuthGuard
    implements OnActivate, OnDeactivate {
  JoblistBloc joblistBloc;
  PreviewBloc previewBloc;
  UserBloc userBloc;
  PdfBloc pdfBloc;
  Location _location;
  Job job;

  StreamSubscription jobListener;
  StreamSubscription previewListener;
  StreamSubscription pdfListener;
  StreamSubscription userListener;

  bool color = true;
  int duplex = 0;
  int copies = 1;
  bool collate = false;
  bool a3 = false;
  String range = '';
  int nup = 1;
  int nupPageOrder = 1;
  bool keep = false;

  final List<String> duplexOptions = ['Simplex', 'Lange Kante', 'Kurze Kante'];
  String duplexSelection = 'Simplex';

  final List<String> nupOptions = ['1', '2', '4'];
  String nupSelection = '1';

  // variables used for direct printing in kiosk mode
  bool directPrinter = false;
  String leftPrinter = '';
  String rightPrinter = '';
  String selectedPrinter = '';
  bool showSelectPrinter = false;

  final List<String> nupOrderOptions = [
    'Nach Rechts, dann Runter',
    'Nach Unten, dann Rechts',
    'Nach Links, dann Runter',
    'Nach Unten, dann Links',
  ];
  String nupOrderSelection = 'Nach Rechts, dann Runter';

  double estimatedDouble = 0.0;
  List<List<int>> previews;

  String pdfUrl = '';

  User user;

  JobDetailsComponent(
      JoblistProvider joblistProvider,
      PreviewProvider previewProvider,
      UserProvider userProvider,
      PdfProvider pdfProvider,
      this._location,
      AuthProvider authProvider,
      Router router)
      : super(authProvider, router) {
    joblistBloc = joblistProvider.joblistBloc;
    previewBloc = previewProvider.previewBloc;
    pdfBloc = pdfProvider.pdfBloc;
    userBloc = userProvider.userBloc;
  }

  void goBack() => _location.back();

  @override
  void onActivate(_, RouterState current) async {
    int id = getId(current.parameters);
    if (id != null) {
      jobListener = joblistBloc.state.listen((state) {
        if (state.isResult) {
          job = state.value.singleWhere((Job job) => job.id == id);
          setJobOptions(job.jobOptions);
          estimatedDouble = (job.priceEstimation as double) / 100.0;
          previewBloc.getPreview(job);
        }
      });

      previewListener = previewBloc.state.skip(1).listen((PreviewState state) {
        if (state.isResult) {
          previews = state.value
              .singleWhere((previewSet) => previewSet.jobId == id)
              .previews;
        }
      });

      userListener = userBloc.state.listen((UserState state) {
        if (state.isResult) {
          user = state.value;
        }
      });

      if (joblistBloc.jobs != null && joblistBloc.jobs.isEmpty)
        joblistBloc.onRefresh();

      leftPrinter =
          const String.fromEnvironment('leftPrinter', defaultValue: '');

      rightPrinter =
          const String.fromEnvironment('rightPrinter', defaultValue: '');

      if (leftPrinter.isNotEmpty || rightPrinter.isNotEmpty)
        directPrinter = true;
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

  void openPrintDialog() {
    if (leftPrinter.isNotEmpty && rightPrinter.isEmpty) {
      printJobLeft();
    } else if (rightPrinter.isNotEmpty && leftPrinter.isEmpty) {
      printJobRight();
    } else {
      showSelectPrinter = true;
    }

    if (!job.jobOptions.keep) {
      _location.back();
    }
  }

  void printJobLeft() {
    joblistBloc.onPrintById(leftPrinter, job.id);
    showSelectPrinter = false;
  }

  void printJobRight() {
    joblistBloc.onPrintById(rightPrinter, job.id);
    showSelectPrinter = false;
  }

  void deleteJob() {
    joblistBloc.onDeleteById(job.id);
    goBack();
  }

  void downloadPdf() {
    pdfBloc.onGetPdf(job.id);
    pdfListener = pdfBloc.state.listen((PdfState state) {
      if (state.isResult && state.value.last.id == job.id) {
        Blob pdfBlob = Blob([state.value.last.file], 'application/pdf');

        String blobUrl = Url.createObjectUrlFromBlob(pdfBlob);

        AnchorElement link = AnchorElement()
          ..href = blobUrl
          ..download = job.jobInfo.filename;

        // dispatch click event so firefox works as well
        var event = MouseEvent("click", view: window, cancelable: false);
        link.dispatchEvent(event);

        pdfListener.cancel();
      }
    });
  }

  @override
  void onDeactivate(RouterState previous, RouterState current) {
    jobListener.cancel();
    previewListener.cancel();
    if (pdfListener != null) pdfListener.cancel();
    userListener.cancel();
  }
}
