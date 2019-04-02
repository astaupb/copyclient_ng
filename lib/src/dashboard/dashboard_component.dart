import 'package:angular/angular.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/user.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

@Component(
  selector: 'dashboard',
  templateUrl: 'dashboard_component.html',
  styleUrls: [
    'dashboard_component.scss.css',
    'package:angular_components/css/mdc_web/card/mdc-card.scss.css',
  ],
  directives: [
    MaterialListItemComponent,
    MaterialListComponent,
  ],
)
class DashboardComponent extends AuthGuard implements OnActivate {
  AuthBloc authBloc;
  UserBloc userBloc;

  User user;

  DashboardComponent(
      AuthProvider authProvider, Router router, UserProvider userProvider)
      : super(authProvider, router) {
    authBloc = authProvider.authBloc;
    userBloc = userProvider.userBloc;
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    userBloc.onRefresh();

    userBloc.state.listen((UserState state) {
      if (state.isResult) {
        user = state.value;
      }
    });
  }
}
