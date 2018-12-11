import 'package:angular_router/angular_router.dart';

const idParam = 'uid';

int getId(Map<String, String> parameters) {
  final id = parameters[idParam];
  return id == null ? null : int.tryParse(id);
}

String jobDetailsUrl(int id) =>
    RoutePaths.jobdetails.toUrl(parameters: {idParam: '$id'});

class RoutePaths {
  static final dashboard = RoutePath(path: 'dashboard');
  static final login = RoutePath(path: 'login');
  static final joblist = RoutePath(path: 'joblist');
  static final jobdetails = RoutePath(path: '${joblist.path}/:$idParam');
  static final uploads = RoutePath(path: 'uploads');
}
