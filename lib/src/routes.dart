import 'package:angular_router/angular_router.dart';

import 'dashboard/dashboard_component.template.dart' as dashboard_template;
import 'jobdetails/jobdetails_component.template.dart' as jobdetails_template;
import 'joblist/joblist_component.template.dart' as joblist_template;
import 'login/login_component.template.dart' as login_template;
import 'route_paths.dart';
import 'scan/scan_component.template.dart' as scans_template;
import 'register/register_component.template.dart' as register_template;

export 'route_paths.dart';

class Routes {
  static final all = <RouteDefinition>[
    dashboard,
    jobdetails,
    joblist,
    login,
    scans,
    register,
    RouteDefinition.redirect(
      path: '',
      redirectTo: joblist.path,
    ),
  ];

  static final dashboard = RouteDefinition(
    routePath: RoutePaths.dashboard,
    component: dashboard_template.DashboardComponentNgFactory,
    additionalData: 'Dashboard',
  );

  static final login = RouteDefinition(
    routePath: RoutePaths.login,
    component: login_template.LoginComponentNgFactory,
    additionalData: 'Login',
  );

  static final jobdetails = RouteDefinition(
    routePath: RoutePaths.jobdetails,
    component: jobdetails_template.JobDetailsComponentNgFactory,
    additionalData: 'Jobdetails',
  );

  static final joblist = RouteDefinition(
    routePath: RoutePaths.joblist,
    component: joblist_template.JobListComponentNgFactory,
    additionalData: 'Jobliste',
  );

  static final scans = RouteDefinition(
    routePath: RoutePaths.scans,
    component: scans_template.ScanComponentNgFactory,
    additionalData: 'Scanmodus',
  );

  static final register = RouteDefinition(
    routePath: RoutePaths.register,
    component: register_template.RegisterComponentNgFactory,
    additionalData: 'Registrieren',
  );
}
