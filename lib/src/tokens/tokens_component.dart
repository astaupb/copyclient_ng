import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/tokens.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/tokens_provider.dart';

@Component(
  selector: 'tokens',
  templateUrl: 'tokens_component.html',
  styleUrls: ['tokens_component.scss.css'],
  directives: [
    MaterialListComponent,
    MaterialListItemComponent,
    NgFor,
    NgIf,
    NgSwitch,
    NgSwitchWhen,
    MaterialButtonComponent,
    MaterialIconComponent,
  ],
  exports: [ClientType],
)
class TokensComponent extends AuthGuard implements OnInit, OnDestroy {
  final Router _router;
  TokensBloc tokensBloc;

  List<Token> tokens = [];

  StreamSubscription tokensListener;

  @Input()
  String loadFirst;

  @Input()
  bool compact = false;

  TokensComponent(AuthProvider authProvider, TokensProvider tokensProvider, this._router)
      : super(authProvider, _router) {
    tokensBloc = tokensProvider.tokensBloc;
  }

  @override
  void ngOnDestroy() {
    tokensListener.cancel();
  }

  @override
  void ngOnInit() {
    tokensListener = tokensBloc.listen((TokensState state) {
      print('tokens: $state');
      if (state.isResult) {
        if (loadFirst != null) {
          int loadCount = int.tryParse(loadFirst);
          tokens = state.value
              .sublist(0, (loadCount > state.value.length) ? state.value.length : loadCount);
        } else {
          tokens = state.value;
        }
        print('tokens: $tokens');
      }
    });

    tokensBloc.onGetTokens();
  }

  void onDeleteToken(int id) {
    tokensBloc.onDeleteToken(id);
  }

  void onReturn() {
    _router.navigateByUrl('/settings');
  }

  String translateClientType(ClientType type) {
    switch (type) {
      case ClientType.safari:
        return 'Safari';
      case ClientType.firefox:
        return 'Firefox';
      case ClientType.dartio:
        return 'Mobile App';
      case ClientType.electron:
        return 'Desktop App';
      case ClientType.curl:
        return 'curl';
      case ClientType.chrome:
        return 'Chrome';
      default:
        return '???';
    }
  }
}
