import 'dart:html';
import 'dart:core';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:angular_bloc/angular_bloc.dart';

import '../auth_provider.dart';
import '../route_paths.dart';
import '../auth_guard.dart';

@Component(
  selector: 'joblist',
  styleUrls: ['joblist_component.css'],
  templateUrl: 'joblist_component.html',
  directives: [
    routerDirectives,
    coreDirectives,
    MaterialListComponent,
    MaterialListItemComponent,
    MaterialIconComponent,
    MaterialButtonComponent,
  ],
  pipes: [commonPipes, BlocPipe],
  exports: [DateTime],
)
class JobListComponent extends AuthGuard implements OnActivate {
  JoblistBloc jobsBloc;
  Location location;
  Router _router;

  JobListComponent(
      Backend backend, AuthProvider authProvider, this._router, this.location)
      : jobsBloc = JoblistBloc(backend,
            window.localStorage['token'] ?? window.sessionStorage['token']),
        super(authProvider, _router);

  @override

  void onActivate(_, __) {
    jobsBloc.onStart();

    // Listen for uploadJob event to be called by our custom JS
    document.on["uploadJob"].listen((Event event) {
      CustomEvent ce = (event as CustomEvent);

      // This converts event's payload from JSON to a Dart Map.
      Map payload = jsonDecode(ce.detail);
      String filename = payload['filename'];
      List<int> data = base64Decode(payload['data']);

      // TODO: Actually upload job

      print('data: $data');
      print('filename: $filename');
    });

    // Tell our custom JS to start watching for fakeprinting
    document.dispatchEvent(new CustomEvent("setupWatches"));
    document.dispatchEvent(new CustomEvent("setupDragDrop"));
  }

  void showJobDetails(int id) {
    print('showing job details for $id');
    _router.navigateByUrl(jobDetailsUrl(id));
  }

  void printJob(int id) {
    print('printing job with id $id');

    /// TODO: make printer selectable
    jobsBloc.onPrintbyId('42000', id);
  }
}
