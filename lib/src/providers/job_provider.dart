import 'package:angular/core.dart';
import 'package:blocs_copyclient/job.dart';
import 'package:http/browser_client.dart';

import '../backend_shiva.dart';

@Injectable()
class JobProvider {
  static final JobProvider _singleton = JobProvider._internal(
    {},
  );

  Map<int, JobBloc> jobBlocs;

  factory JobProvider() => _singleton;

  JobProvider._internal(this.jobBlocs);

  void addJob(Job job, String token) {
    jobBlocs[job.id] = JobBloc(BackendShiva(BrowserClient()));
    jobBlocs[job.id].onStart(job, token);
  }

  void removeJob(int id) {
    jobBlocs.removeWhere((key, _) => key == id);
  }

  void updateJobs(List<Job> jobs, String token) {
    for (final job in jobs) {
      if (jobBlocs[job.id] != null) {
        if (jobBlocs[job.id].job.timestamp < job.timestamp) {
          jobBlocs[job.id].onStart(job, token);
        } 
      } else {
        addJob(job, token);
      }
    }/*
    for (final key in jobBlocs.keys) {
      bool found = false;
      for (final job in jobs) {
        if (job.id == key) found = true;
      }
      if (!found) removeJob(key);
    }*/
  }
}
