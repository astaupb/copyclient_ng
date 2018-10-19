import 'package:angular/angular.dart';

import 'src/login/login_component.dart';
import 'src/joblist/joblist_component.dart';

@Component(
  selector: 'copyclient',
  styleUrls: ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: [LoginComponent, JobListComponent],
)
class AppComponent {}
