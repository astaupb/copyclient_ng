import 'package:angular_router/angular_router.dart';

import 'joblist/joblist_component.template.dart' as joblist_template;
import 'jobdetails/jobdetails_component.template.dart' as jobdetails_template;
import 'login/login_component.template.dart' as login_template;
import 'dashboard/dashboard_component.template.dart' as dashboard_template;
import 'route_paths.dart';

export 'route_paths.dart';

class Routes {
  static final all = <RouteDefinition>[
    dashboard,
    jobdetails,
    joblist,
    login,
  ];

  static final dashboard = RouteDefinition(
    routePath: RoutePaths.dashboard,
    component: dashboard_template.DashboardComponentNgFactory,
    useAsDefault: true,
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
}
