import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';

@Component(
  selector: 'dashboard',
  templateUrl: 'dashboard_component.html',
  styleUrls: ['dashboard_component.css'],
  directives: [],
)
class DashboardComponent extends AuthGuard {
  Location _location;
  AuthBloc authBloc;

  DashboardComponent(AuthProvider authProvider, this._location, Router router)
      : super(authProvider, router) {
    authBloc = authProvider.authBloc;
  }
}
