import 'dart:html';
import 'dart:core';

import 'package:angular/angular.dart';
import 'package:blocs_copyclient/src/models/backend.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:angular_bloc/angular_bloc.dart';

@Component(
  selector: 'joblist',
  styleUrls: ['joblist_component.css'],
  templateUrl: 'joblist_component.html',
  directives: [coreDirectives],
  pipes: [commonPipes, BlocPipe],
)
class JobListComponent implements OnInit {
  JoblistBloc jobsBloc;

  JobListComponent(Backend backend)
      : jobsBloc = JoblistBloc(backend, window.sessionStorage['token']);

  @override
  void ngOnInit() {
    jobsBloc.onStart();
    jobsBloc.state.listen(print);
  }
}
