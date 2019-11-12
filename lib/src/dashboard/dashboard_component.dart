import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/auth.dart';
import 'package:blocs_copyclient/journal.dart';
import 'package:blocs_copyclient/user.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/user_provider.dart';
import '../route_paths.dart';

@Component(
  selector: 'dashboard',
  templateUrl: 'dashboard_component.html',
  styleUrls: [
    'dashboard_component.scss.css',
    'package:angular_components/css/mdc_web/card/mdc-card.scss.css',
    'package:copyclient_ng/styles/listpage_navigation.css',
  ],
  directives: [
    routerDirectives,
    MaterialListItemComponent,
    MaterialListComponent,
    MaterialButtonComponent,
    MaterialFabComponent,
    MaterialIconComponent,
    MaterialTooltipDirective,
    MaterialInkTooltipComponent,
    MaterialTooltipTargetDirective,
    NgFor,
    NgIf,
  ],
  providers: [
    materialTooltipBindings,
    materialProviders,
  ],
  exports: [RoutePaths],
)
class DashboardComponent extends AuthGuard implements OnActivate, OnDeactivate {
  AuthBloc authBloc;
  UserBloc userBloc;
  JournalBloc journalBloc;

  User user;
  List<Transaction> transactions;

  StreamSubscription userListener;
  StreamSubscription journalListener;

  bool refreshing = false;

  DashboardComponent(
    AuthProvider authProvider,
    Router router,
    UserProvider userProvider,
    JournalProvider journalProvider,
  ) : super(authProvider, router) {
    authBloc = authProvider.authBloc;
    userBloc = userProvider.userBloc;
    journalBloc = journalProvider.journalBloc;
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    userListener = userBloc.listen((UserState state) {
      if (state.isResult) {
        user = state.value;
      }
    });

    journalListener = journalBloc.listen((JournalState state) {
      if (state.isResult) {
        transactions = state.value.transactions.sublist(0, 5);
      }
    });

    userBloc.onRefresh();
  }

  @override
  void onDeactivate(RouterState current, RouterState next) {
    userListener.cancel();
    journalListener.cancel();
  }

  void onRefreshDashboard() {
    userBloc.onRefresh();
    journalBloc.onRefresh();
  }
}
