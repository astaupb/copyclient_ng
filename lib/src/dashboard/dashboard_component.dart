import 'package:angular/angular.dart';
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
  AuthBloc authBloc;

  DashboardComponent(AuthProvider authProvider, Router router)
      : super(authProvider, router) {
    authBloc = authProvider.authBloc;
  }
}
