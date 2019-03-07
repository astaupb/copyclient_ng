import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/src/router/router.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:blocs_copyclient/print_queue.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/joblist_provider.dart';
import '../providers/print_queue_provider.dart';
import '../providers/pdf_provider.dart';
import '../route_paths.dart';

@Component(
  selector: 'scan-component',
  templateUrl: 'scan_component.html',
  styleUrls: [
    'scan_component.scss.css',
    '../../styles/printer_selector.scss.css',
  ],
  directives: [
    NgIf,
    NgFor,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialListComponent,
    MaterialListItemComponent,
    routerDirectives,
  ],
  exports: [
    jobDetailsUrl,
    DateTime,
  ],
)
class ScanComponent extends AuthGuard implements OnActivate, OnDeactivate {
  final PrintQueueProvider printQueueProvider;
  PrintQueueBloc printQueueBloc;
  final JoblistProvider joblistProvider;
  JoblistBloc joblistBloc;
  final PdfProvider pdfProvider;
  PdfBloc pdfBloc;

  List<PrintQueueTask> printQueue = [];
  List<Job> newJobs = [];

  String leftPrinter = '';
  String rightPrinter = '';

  bool printerLocked = false;
  String lockedPrinter = '';
  String lockUid;

  DateTime activationTime;

  StreamSubscription listener;
  StreamSubscription jobListener;
  StreamSubscription lockListener;
  StreamSubscription pdfListener;

  Timer timer;
  Timer jobTimer;

  ScanComponent(AuthProvider authProvider, Router router,
      this.printQueueProvider, this.joblistProvider, this.pdfProvider)
      : super(authProvider, router) {
    printQueueBloc = printQueueProvider.printQueueBloc;
    joblistBloc = joblistProvider.joblistBloc;
    pdfBloc = pdfProvider.pdfBloc;
  }

  void lockLeft() {
    lockedPrinter = leftPrinter;
    lockPrinter(lockedPrinter);
  }

  void lockPrinter(String id) async {
    printQueueBloc.setDeviceId(int.tryParse(id));

    listener = printQueueBloc.state.listen((PrintQueueState state) {
      if (state.isResult) {
        printQueue = state.value.processing;
        printQueueBloc.onLockDevice();

        lockListener = printQueueBloc.state.listen((PrintQueueState state) {
          if (state.isLocked) {
            lockUid = state.lockUid;
            printerLocked = true;
            timer = Timer.periodic(
                Duration(seconds: 15),
                (Timer t) =>
                    printQueueBloc.onLockDevice(queueUid: state.lockUid));
            jobTimer = Timer.periodic(
                Duration(seconds: 3), (Timer t) => joblistBloc.onRefresh());
          } else if (!state.isLocked) {
            printerLocked = false;
            deactivate(timer);
            deactivate(jobTimer);
          }
        });

        jobListener = joblistBloc.state.listen((JoblistState state) async {
          if (state.isResult) {
            newJobs = state.value
                .where((Job job) => activationTime.isBefore(
                    DateTime.fromMillisecondsSinceEpoch(job.timestamp * 1000)))
                .toList();
          }
        });

        listener.cancel();
      }
    });
  }

  void lockRight() {
    lockedPrinter = rightPrinter;
    lockPrinter(lockedPrinter);
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    activationTime = DateTime.now();

    leftPrinter = const String.fromEnvironment('leftPrinter', defaultValue: '');

    rightPrinter =
        const String.fromEnvironment('rightPrinter', defaultValue: '');
  }

  @override
  void onDeactivate(RouterState previous, RouterState current) {
    deactivate(listener);
    deactivate(jobListener);
    deactivate(lockListener);

    deactivate(timer);
    deactivate(jobTimer);
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
        var event = MouseEvent("click", view: window, cancelable: false);
        link.dispatchEvent(event);

        pdfListener.cancel();
      }
    });
  }
}
