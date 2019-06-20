import 'package:angular/core.dart';
import 'package:blocs_copyclient/joblist.dart';

import '../backend_shiva.dart';

@Injectable()
class JoblistProvider {
  static final JoblistProvider _singleton = JoblistProvider._internal(
    JoblistBloc(BackendShiva()),
  );

  JoblistBloc joblistBloc;

  factory JoblistProvider() => _singleton;

  JoblistProvider._internal(this.joblistBloc);
}
