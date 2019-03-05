import 'package:angular_router/angular_router.dart';

import 'dashboard/dashboard_component.template.dart' as dashboard_template;
import 'jobdetails/jobdetails_component.template.dart' as jobdetails_template;
import 'joblist/joblist_component.template.dart' as joblist_template;
import 'login/login_component.template.dart' as login_template;
import 'route_paths.dart';
import 'scan/scan_component.template.dart' as scans_template;
import 'uploads/uploads_component.template.dart' as uploads_template;

export 'route_paths.dart';

class Routes {
  static final all = <RouteDefinition>[
    dashboard,
    jobdetails,
    joblist,
    login,
    uploads,
    scans,
    RouteDefinition.redirect(
      path: '',
      redirectTo: joblist.path,
    ),
  ];

  static final dashboard = RouteDefinition(
    routePath: RoutePaths.dashboard,
    component: dashboard_template.DashboardComponentNgFactory,
  );

  static final login = RouteDefinition(
    routePath: RoutePaths.login,
    component: login_template.LoginComponentNgFactory,
  );

  static final jobdetails = RouteDefinition(
    routePath: RoutePaths.jobdetails,
    component: jobdetails_template.JobDetailsComponentNgFactory,
  );

  static final joblist = RouteDefinition(
    routePath: RoutePaths.joblist,
    component: joblist_template.JobListComponentNgFactory,
  );

  static final uploads = RouteDefinition(
    routePath: RoutePaths.uploads,
    component: uploads_template.UploadsComponentNgFactory,
  );

  static final scans = RouteDefinition(
    routePath: RoutePaths.scans,
    component: scans_template.ScanComponentNgFactory,
  );
}
