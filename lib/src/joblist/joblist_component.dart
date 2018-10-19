import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'package:http/browser_client.dart';

import 'package:angular/angular.dart';

@Component(
  selector: 'joblist',
  styleUrls: ['joblist_component.css'],
  templateUrl: 'joblist_component.html',
  directives: [coreDirectives],
  pipes: [commonPipes],
)
class JobListComponent implements OnInit {
  BrowserClient client;
  String token;
  List<Job> jobs = [];

  @override
  void ngOnInit() async {
    client = new BrowserClient();
    token = window.sessionStorage['token'];
    jobs = await getJobs();
  }

  Future<List<Job>> getJobs() async {
    return await client.get(
      'https://sunrise.upb.de/astaprint-backend/jobs',
      headers: {
        'X-Api-Key': token,
        'Accept': 'application/json',
      },
    ).then(
      (response) {
        return List<Job>.from(
            json.decode(response.body).map((job) => Job.fromJson(job)));
      },
    );
  }
}

class Job {
  String uid;
  int timestamp;
  String filename;

  Job({this.uid, this.filename, this.timestamp});

  factory Job.fromJson(Map json) {
    return Job(
        uid: json['uid'],
        filename: json['info']['filename'],
        timestamp: json['timestamp']);
  }
}
