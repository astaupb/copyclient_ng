import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/blocs.dart';
import 'package:blocs_copyclient/exceptions.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:blocs_copyclient/pdf_creation.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:blocs_copyclient/upload.dart';
import 'package:copyclient_ng/src/providers/pdf_creation_provider.dart';
import 'package:copyclient_ng/src/providers/pdf_provider.dart';
import 'package:copyclient_ng/src/providers/print_queue_provider.dart';
import 'package:intl/intl.dart';

import '../auth_guard.dart';
import '../notifications.dart';
import '../providers/auth_provider.dart';
import '../providers/joblist_provider.dart';
import '../providers/uploads_provider.dart';
import '../route_paths.dart';

@Component(
  selector: 'joblist',
  styleUrls: [
    'joblist_component.scss.css',
    'package:copyclient_ng/styles/listpage_navigation.css',
    'package:copyclient_ng/styles/printer_selector.scss.css',
    'package:copyclient_ng/styles/bottom_notification.scss.css',
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
    MaterialTooltipDirective,
    MaterialInkTooltipComponent,
    MaterialTooltipTargetDirective,
    materialInputDirectives,
    ModalComponent,
    MaterialSpinnerComponent,
    MaterialTooltipDirective,
  ],
  providers: [
    materialTooltipBindings,
    materialProviders,
  ],
  pipes: [commonPipes],
  exports: [
    DateTime,
    jobDetailsUrl,
  ],
)
class JobListComponent extends AuthGuard implements OnActivate, OnDeactivate {
  JoblistBloc jobsBloc;
  UploadBloc uploadBloc;
  PdfBloc pdfBloc;
  PrintQueueBloc printQueueBloc;
  PdfCreationBloc pdfCreation;

  bool refreshing = true;

  /// last complete joblist known to this component
  List<Job> lastJobs = [];

  List<DispatcherTask> uploads = [];

  List<PrintQueueTask> printQueue = [];

  /// variables used for direct printing in kiosk mode
  bool directPrinter = false;
  String leftPrinter = '';
  String rightPrinter = '';
  int printingJob;
  String selectedPrinter = '';

  /// modal display booleans
  bool showSelectPrinter = false;
  bool showDeleteAll = false;
  bool showPrintAll = false;
  bool showDownloadAll = false;

  // Listeners
  StreamSubscription<UploadState> uploadListener;
  StreamSubscription<JoblistState> jobListener;
  StreamSubscription<PrintQueueState> printQueueListener;
  StreamSubscription<PrintQueueState> lockListener;

  bool printerLocked = false;
  String lockUid;
  Timer printLockTimer;
  Timer jobTimer;
  Timer uploadsTimer;

  bool copyMode = false;
  DateTime copyStartTime;
  List<int> copiedIds = [];

  Notifications notifications = Notifications();

  JobListComponent(
    JoblistProvider joblistProvider,
    UploadsProvider uploadsProvider,
    AuthProvider authProvider,
    PdfProvider pdfProvider,
    PrintQueueProvider printQueueProvider,
    PdfCreationProvider pdfCreationProvider,
    Router _router,
  ) : super(authProvider, _router) {
    jobsBloc = joblistProvider.joblistBloc;
    uploadBloc = uploadsProvider.uploadBloc;
    pdfBloc = pdfProvider.pdfBloc;
    printQueueBloc = printQueueProvider.printQueueBloc;
    pdfCreation = pdfCreationProvider.pdfCreationBloc;
  }

  String get _fileBroken => Intl.message(
      'Die hochgeladene Datei ist fehlerhaft oder kann nicht gelesen werden. Bitte überprüfe dein Dokument.',
      name: '_fileBroken',
      desc: 'Notify user that the selected file is corrupt or  cant  be read');

  String get _printerLocked => Intl.message('Der Drucker ist bereits gesperrt!',
      name: '_printerLocked',
      desc: 'Notify user that the selected printer is locked by another user');

  String get _unknownUploadError => Intl.message('Unbekannter Fehler beim Hochladen einer Datei',
      name: '_unknownUploadError', desc: 'Notify user that an unknown error occured during upload');

  void deactivate<T>(T subject) {
    if (subject != null) {
      if (subject is StreamSubscription) {
        if (!subject.isPaused) subject.cancel();
      } else if (subject is Timer) {
        if (subject.isActive) subject.cancel();
      }
    }
  }

  @override
  void onActivate(_, __) {
    //onRefreshJobs();
    jobListener = jobsBloc.listen((JoblistState state) {
      if (state.isResult) {
        refreshing = false;

        if (copyMode) {
          for (Job job in (state.value.where((Job j) =>
              !copiedIds.contains(j.id) &&
              DateTime.fromMillisecondsSinceEpoch(j.timestamp * 1000).isAfter(copyStartTime)))) {
            print('copying ${job.jobInfo.filename}');
            jobsBloc.onPrintById(selectedPrinter, job.id);
            copiedIds.add(job.id);
          }
        }

        lastJobs = state.value;
      }
    });

    leftPrinter = const String.fromEnvironment('leftPrinter', defaultValue: '');

    rightPrinter = const String.fromEnvironment('rightPrinter', defaultValue: '');

    if (leftPrinter.isEmpty)
      selectedPrinter = rightPrinter;
    else
      selectedPrinter = leftPrinter;

    directPrinter = (leftPrinter.isNotEmpty || rightPrinter.isNotEmpty);

    uploadListener = uploadBloc.listen((UploadState state) async {
      if (state.isResult) {
        uploads = state.value.reversed.toList();
        if (state.value.isNotEmpty) {
          if (!state.value.first.isUploading) {
            await Future.delayed(const Duration(seconds: 1));
            uploadBloc.onRefresh();
          }
        } else {
          refreshing = true;
          //await Future.delayed(const Duration(milliseconds: 1000));
          jobsBloc.onRefresh();
        }
      } else if (state.isException) {
        uploads = [];
        if ((state.error as ApiException).statusCode == 400)
          notifications.add(_fileBroken);
        else
          notifications.add(_unknownUploadError);
      }
    });
  }

  @override
  void onDeactivate(RouterState previous, RouterState current) {
    _cancelListeners();

    if (printQueueBloc.state.isLocked) printQueueBloc.onDelete();

    _cancelTimers();
  }

  void onDeleteAll() {
    showDeleteAll = false;
    for (Job job in lastJobs) {
      jobsBloc.onDeleteById(job.id);
    }
  }

  void onDeleteJob(int id) {
    jobsBloc.onDeleteById(id);
  }

  void onDownloadAll() async {
    showDownloadAll = false;
    for (Job job in lastJobs) {
      onDownloadPdf(job.id);
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void onDownloadPdf(int id) {
    pdfBloc.onGetPdf(id);
    StreamSubscription pdfListener;
    pdfListener = pdfBloc.skip(1).listen((PdfState state) {
      if (state.isResult) {
        final Blob pdfBlob = Blob(
            [state.value.where((PdfFile file) => id == file.id).first.file], 'application/pdf');

        final String blobUrl = Url.createObjectUrlFromBlob(pdfBlob);
        String filename = lastJobs.where((Job job) => id == job.id).first.jobInfo.filename;
        filename = filename.endsWith('.pdf') ? filename : filename + '.pdf';

        final AnchorElement link = AnchorElement()
          ..href = blobUrl
          ..download = filename;

        // dispatch click event so firefox works as well
        final MouseEvent event = MouseEvent("click", view: window, cancelable: false);
        link.dispatchEvent(event);

        pdfListener.cancel();
      }
    });
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

  void onPrintAll() async {
    showPrintAll = false;
    for (Job job in lastJobs) {
      print('printing job ${job.id}');
      jobsBloc.onPrintById((leftPrinter.isEmpty) ? rightPrinter : leftPrinter, job.id);
      await Future.delayed(const Duration(milliseconds: 500));
      jobsBloc.onRefresh();
    }
  }

  void onRefreshJobs() {
    refreshing = true;
    jobsBloc.onRefresh();
  }

  void onStartCopying() {
    copyMode = true;
    copyStartTime = DateTime.now();
    onStartScanning();
  }

  void onStartScanning() {
    printQueueListener = printQueueBloc.listen((PrintQueueState state) {
      if (state.isResult) {
        printQueue = state.value.processing;
        printQueueBloc.onLockDevice();

        lockListener = printQueueBloc.listen((PrintQueueState state) {
          if (state.isLocked) {
            lockUid = state.lockUid;
            printerLocked = true;
            if (printLockTimer != null) printLockTimer.cancel();
            printLockTimer =
                Timer.periodic(Duration(seconds: 50), (Timer t) => printQueueBloc.onLockDevice());
            //if (jobTimer != null) jobTimer.cancel();
            //jobTimer = Timer.periodic(Duration(seconds: 2), (Timer t) => jobsBloc.onRefresh());
            if (uploadsTimer != null) uploadsTimer.cancel();
            uploadsTimer =
                Timer.periodic(Duration(seconds: 1), (Timer t) => uploadBloc.onRefresh());
          } else if (state.isException && (state.error as ApiException).statusCode == 423) {
            notifications.add(_printerLocked);
            printerLocked = false;
            deactivate(printLockTimer);
            deactivate(uploadsTimer);
            copyMode = false;
          } else if (!state.isLocked) {
            printerLocked = false;
            deactivate(printLockTimer);
            //deactivate(jobTimer);
            deactivate(uploadsTimer);
          }
        });

        printQueueListener.cancel();
      }
    });

    printQueueBloc.setDeviceId(int.tryParse(selectedPrinter));
  }

  void onUnlockPrinter() {
    printQueueBloc.onDelete();
    lockUid = null;
    printerLocked = false;
    copyMode = false;
    _cancelTimers();
    deactivate(printQueueListener);
    deactivate(lockListener);
  }

  void onUploadFileSelected(List<File> files) {
    files.forEach((File file) async {
      if (_isSupportedDocument(file.name)) {
        FileReader reader = FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoadEnd.listen(
          (ProgressEvent progress) {
            if (progress.loaded == progress.total) {
              uploadBloc.onUpload(reader.result as List<int>, filename: file.name);
            }
          },
        ).asFuture();
      } else if (_isSupportedImage(file.name)) {
        FileReader reader = FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoadEnd.listen(
          (ProgressEvent progress) {
            if (progress.loaded == progress.total) {
              pdfCreation.onCreateFromImage(reader.result as List<int>);
              StreamSubscription listener;
              listener = pdfCreation.skip(1).listen((PdfCreationState state) {
                if (state.isResult) {
                  uploadBloc.onUpload(state.value, filename: file.name);
                  listener.cancel();
                }
              });
            }
          },
        ).asFuture();
      } else if (_isSupportedText(file.name)) {
        FileReader reader = FileReader();
        reader.readAsText(file);
        await reader.onLoadEnd.listen(
          (ProgressEvent progress) {
            if (progress.loaded == progress.total) {
              pdfCreation.onCreateFromText(reader.result as String);
              StreamSubscription listener;
              listener = pdfCreation.skip(1).listen((PdfCreationState state) {
                if (state.isResult) {
                  uploadBloc.onUpload(state.value, filename: file.name);

                  listener.cancel();
                }
              });
            }
          },
        ).asFuture();
      } else {
        notifications.add(_unsupportedFormat(file.name));
      }
    });

    (window.document.getElementById('input-box') as InputElement).value = null;
  }

  void printJobLeft() {
    jobsBloc.onPrintById(leftPrinter, printingJob);
    showSelectPrinter = false;
  }

  void printJobRight() {
    jobsBloc.onPrintById(rightPrinter, printingJob);
    showSelectPrinter = false;
  }

  void _cancelListeners() {
    deactivate(uploadListener);
    deactivate(jobListener);
    deactivate(printQueueListener);
    deactivate(lockListener);
  }

  void _cancelTimers() {
    deactivate(uploadsTimer);
    deactivate(printLockTimer);
  }

  bool _isSupportedDocument(String filename) {
    const List<String> fileTypes = [
      'pdf',
      'ai',
    ];
    final String suffix = filename.split('.').last;
    return fileTypes.contains(suffix.toLowerCase());
  }

  bool _isSupportedImage(String filename) {
    const List<String> imageTypes = [
      'png',
      'apng',
      'jpeg',
      'jpg',
      'jif',
      'jfif',
      'jpe',
      'jfi',
      'webp',
      'tga',
      'tpic',
      'gif',
      'pvr',
      'tiff',
      'tif',
      'psd',
      'exr',
    ];
    final String suffix = filename.split('.').last;
    return imageTypes.contains(suffix.toLowerCase());
  }

  bool _isSupportedText(String filename) {
    const List<String> fileTypes = [
      'txt',
      'asc',
      'json',
      'conf',
      'cnf',
      'cfg',
      'log',
      'xml',
      'ini',
      'tsv',
      'tab',
      'yaml',
      'toml',
      'md',
      'diff',
    ];
    final String suffix = filename.split('.').last;
    return fileTypes.contains(suffix.toLowerCase());
  }

  String _unsupportedFormat(String filename) => Intl.message(
      '$filename hat ein nicht unterstütztes Format. Bitte versuche es mit gültigen PDFs, Bildern oder reinem Text.',
      name: '_unsupportedFormat',
      args: [filename],
      desc:
          'Notify user that the provided file is not in one of the supported fiel formats (which is PDF, most images and pure text)');
}
