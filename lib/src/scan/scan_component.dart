import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/src/router/router.dart';
import 'package:blocs_copyclient/print_queue.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/print_queue_provider.dart';

@Component(
  selector: 'scan-component',
  templateUrl: 'scan_component.html',
  styleUrls: [
    'scan_component.scss.css',
    '../../styles/printer_selector.scss.css',
  ],
  directives: [
    NgIf,
    MaterialButtonComponent,
    MaterialIconComponent,
  ],
)
class ScanComponent extends AuthGuard implements OnActivate {
  final PrintQueueProvider printQueueProvider;
  PrintQueueBloc printQueueBloc;

  List<PrintQueueTask> printQueue = [];

  String leftPrinter = '';
  String rightPrinter = '';

  bool printerLocked = false;
  String lockedPrinter = '';
  String lockUid;

  ScanComponent(
      AuthProvider authProvider, Router router, this.printQueueProvider)
      : super(authProvider, router) {
    printQueueBloc = printQueueProvider.printQueueBloc;
  }

  void lockLeft() {
    lockedPrinter = leftPrinter;
    lockPrinter(lockedPrinter);
  }

  void lockRight() {
    lockedPrinter = rightPrinter;
    lockPrinter(lockedPrinter);
  }

  void lockPrinter(String id) async {
    Timer timer;

    printQueueBloc.setDeviceId(int.tryParse(id));

    var listener;
    listener = printQueueBloc.state.listen((PrintQueueState state) {
      if (state.isResult) {
        printQueue = state.value.processing;
        printQueueBloc.onLockDevice();
        printQueueBloc.state.listen((PrintQueueState state) {
          if (state.isLocked) {
            lockUid = state.lockUid;
            printerLocked = true;
            timer = Timer.periodic(
                Duration(seconds: 5),
                (Timer timer) =>
                    printQueueBloc.onLockDevice(queueUid: state.lockUid));
          } else if (!state.isLocked) {
            printerLocked = false;
            if (timer != null && timer.isActive) timer.cancel();
          }
        });
        listener.cancel();
      }
    });
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    leftPrinter = const String.fromEnvironment('leftPrinter', defaultValue: '');

    rightPrinter =
        const String.fromEnvironment('rightPrinter', defaultValue: '');
  }
}
