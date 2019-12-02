import 'package:angular/core.dart';
import 'package:blocs_copyclient/tokens.dart';

import '../backend_shiva.dart';

@Injectable()
class TokensProvider {
  static final TokensProvider _singleton = TokensProvider._internal(
    TokensBloc(BackendShiva()),
  );

  TokensBloc tokensBloc;

  factory TokensProvider() => _singleton;

  TokensProvider._internal(this.tokensBloc);
}
