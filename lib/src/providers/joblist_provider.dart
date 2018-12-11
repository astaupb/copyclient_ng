import 'dart:html';

import 'package:angular/core.dart';
import 'package:blocs_copyclient/joblist.dart';
import 'package:http/browser_client.dart';

import '../backend_sunrise.dart';

@Injectable()
class JoblistProvider {
  static String _token = window.localStorage['token'];
  
  static final JoblistProvider _singleton = JoblistProvider._internal(
    JoblistBloc(BackendSunrise(BrowserClient()), _token),
  );

  JoblistBloc joblistBloc;

  factory JoblistProvider() => _singleton;

  JoblistProvider._internal(this.joblistBloc);
}
