import 'package:angular/core.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';

import 'providers/auth_provider.dart';
import 'route_paths.dart';

@Injectable()
class AuthGuard implements CanActivate {
  AuthBloc _authBloc;
  Router _router;

  AuthGuard(AuthProvider authProvider, this._router) {
    _authBloc = authProvider.authBloc;
  }

  @override
  Future<bool> canActivate(RouterState current, RouterState next) async {
    // Just continue if already authorized
    if (await _authBloc.state.first.then((state) => state.isAuthorized)) return true;

    //  otherwise navigate to login if not already
    if (next.path != RoutePaths.login.path) _router.navigate(RoutePaths.login.path);

    return false;
  }
}
