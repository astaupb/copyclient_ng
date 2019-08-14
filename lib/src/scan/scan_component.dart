import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/src/router/router.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:blocs_copyclient/print_queue.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:copyclient_ng/src/providers/uploads_provider.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/joblist_provider.dart';
import '../providers/pdf_provider.dart';
import '../providers/print_queue_provider.dart';
import '../route_paths.dart';

@Component(
  selector: 'scan-component',
  templateUrl: 'scan_component.html',
  styleUrls: [
    'scan_component.scss.css',
    'package:copyclient_ng/styles/printer_selector.scss.css',
  ],
  directives: [
    NgIf,
    NgFor,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialListComponent,
    MaterialListItemComponent,
    routerDirectives,
    MaterialSpinnerComponent,
  ],
  exports: [
    jobDetailsUrl,
    DateTime,
  ],
)
class ScanComponent extends AuthGuard implements OnActivate, OnDeactivate, OnDestroy {
  final PrintQueueProvider printQueueProvider;
  PrintQueueBloc printQueueBloc;
  final JoblistProvider joblistProvider;
  JoblistBloc joblistBloc;
  final PdfProvider pdfProvider;
  PdfBloc pdfBloc;
  final UploadsProvider uploadsProvider;
  UploadBloc uploadBloc;

  List<PrintQueueTask> printQueue = [];
  List<Job> newJobs = [];
  List<DispatcherTask> uploadTasks = [];

  String leftPrinter = '';
  String rightPrinter = '';

  bool printerLocked = false;
  String lockedPrinter = '';
  String lockUid;

  DateTime activationTime;

  StreamSubscription printQueueListener;
  StreamSubscription _jobListener;

  StreamSubscription _lockListener;

  StreamSubscription pdfListener;
  StreamSubscription _uploadListener;

  Timer timer;

  Timer jobTimer;
  Timer uploadsTimer;
  ScanComponent(
    AuthProvider authProvider,
    Router router,
    this.printQueueProvider,
    this.joblistProvider,
    this.pdfProvider,
    this.uploadsProvider,
  ) : super(authProvider, router) {
    printQueueBloc = printQueueProvider.printQueueBloc;
    joblistBloc = joblistProvider.joblistBloc;
    pdfBloc = pdfProvider.pdfBloc;
    uploadBloc = uploadsProvider.uploadBloc;
  }

  StreamSubscription get jobListener => _jobListener;

  set jobListener(StreamSubscription jobListener) {
    _jobListener = jobListener;
  }

  StreamSubscription get lockListener => _lockListener;
  set lockListener(StreamSubscription lockListener) {
    _lockListener = lockListener;
  }
  StreamSubscription get uploadListener => _uploadListener;

  set uploadListener(StreamSubscription uploadListener) {
    _uploadListener = uploadListener;
  }

  void deactivate<T>(T subject) {
    if (subject != null) {
      if (subject is StreamSubscription) {
        if (!subject.isPaused) subject.cancel();
      } else if (subject is Timer) {
        if (subject.isActive) subject.cancel();
      }
    }
  }

  void directDelete(int id) {
    joblistBloc.onDeleteById(id);
  }

  void directPrint(int id) {
    joblistBloc.onPrintById(lockedPrinter, id);
  }

  void downloadPdf(int id) {
    pdfBloc.onGetPdf(id);
    pdfListener = pdfBloc.state.listen((PdfState state) {
      if (state.isResult && state.value.last.id == id) {
        Blob pdfBlob = Blob([state.value.last.file], 'application/pdf');

        String blobUrl = Url.createObjectUrlFromBlob(pdfBlob);

        AnchorElement link = AnchorElement()
          ..href = blobUrl
          ..download = newJobs.last.jobInfo.filename;

        // dispatch click event so firefox works as well
        final MouseEvent event = MouseEvent("click", view: window, cancelable: false);
        link.dispatchEvent(event);

        pdfListener.cancel();
      }
    });
  }

  void lockLeft() {
    lockedPrinter = leftPrinter;
    lockPrinter(lockedPrinter);
  }

  void lockPrinter(String id) async {
    printQueueBloc.setDeviceId(int.tryParse(id));

    printQueueListener = printQueueBloc.state.listen((PrintQueueState state) {
      if (state.isResult) {
        printQueue = state.value.processing;
        printQueueBloc.onLockDevice();

        lockListener = printQueueBloc.state.listen((PrintQueueState state) {
          if (state.isLocked) {
            lockUid = state.lockUid;
            printerLocked = true;
            if (timer != null) timer.cancel();
            timer =
                Timer.periodic(Duration(seconds: 50), (Timer t) => printQueueBloc.onLockDevice());
            if (jobTimer != null) jobTimer.cancel();
            jobTimer = Timer.periodic(Duration(seconds: 2), (Timer t) => joblistBloc.onRefresh());
            if (uploadsTimer != null) uploadsTimer.cancel();
            uploadsTimer =
                Timer.periodic(Duration(seconds: 1), (Timer t) => uploadBloc.onRefresh());
          } else if (!state.isLocked) {
            printerLocked = false;
            deactivate(timer);
            deactivate(jobTimer);
            deactivate(uploadsTimer);
          }
        });

        jobListener = joblistBloc.state.listen((JoblistState state) async {
          if (state.isResult) {
            newJobs = state.value
                .where((Job job) => activationTime
                    .isBefore(DateTime.fromMillisecondsSinceEpoch(job.timestamp * 1000)))
                .toList()
                .reversed
                .toList();
          }
        });

        uploadListener = uploadBloc.state.listen((UploadState state) {
          if (state.isResult) {
            uploadTasks = state.value;
          }
        });

        printQueueListener.cancel();
      }
    });
  }

  void lockRight() {
    lockedPrinter = rightPrinter;
    lockPrinter(lockedPrinter);
  }

  @override
  void ngOnDestroy() {
    deactivate(printQueueListener);
    deactivate(jobListener);
    deactivate(lockListener);

    deactivate(timer);
    deactivate(jobTimer);
    deactivate(uploadsTimer);

    printQueueBloc.onDelete();
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    activationTime = DateTime.now();

    leftPrinter = const String.fromEnvironment('leftPrinter', defaultValue: '');

    rightPrinter = const String.fromEnvironment('rightPrinter', defaultValue: '');

    if (leftPrinter.isNotEmpty && rightPrinter.isEmpty) {
      lockLeft();
    } else if (rightPrinter.isNotEmpty && leftPrinter.isEmpty) {
      lockRight();
    }
  }

  @override
  void onDeactivate(RouterState previous, RouterState current) {
    deactivate(printQueueListener);
    deactivate(jobListener);
    deactivate(lockListener);
    deactivate(uploadListener);

    deactivate(timer);
    deactivate(jobTimer);
    deactivate(uploadsTimer);

    printQueueBloc.onDelete();
  }
}
