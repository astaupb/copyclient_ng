import 'dart:html';
import 'dart:core';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:angular_bloc/angular_bloc.dart';

@Component(
  selector: 'joblist',
  styleUrls: ['joblist_component.css'],
  templateUrl: 'joblist_component.html',
  directives: [
    coreDirectives,
    MaterialListComponent,
    MaterialListItemComponent,
    MaterialIconComponent,
    MaterialButtonComponent,
  ],
  pipes: [commonPipes, BlocPipe],
)
class JobListComponent implements OnInit {
  JoblistBloc jobsBloc;

  JobListComponent(Backend backend)
      : jobsBloc = JoblistBloc(backend, window.sessionStorage['token']);

  @override
  void ngOnInit() {
    jobsBloc.onStart();
  }

  void showJobDetails(String uid) {
    print('showing job details for $uid');
    /// TODO: show job details
  }

  void printJob(String uid) {
    print('printing job with id $uid');
    /// TODO: make printer selectable
    jobsBloc.onPrintbyUid('42000', uid);
  }
}
