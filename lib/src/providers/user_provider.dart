import 'package:angular/core.dart';
import 'package:blocs_copyclient/user.dart';
import 'package:http/browser_client.dart';

import '../backend_shiva.dart';

@Injectable()
class UserProvider {
  static final UserProvider _singleton = UserProvider._internal(
    UserBloc(BackendShiva(BrowserClient())),
  );

  UserBloc userBloc;

  factory UserProvider() => _singleton;

  UserProvider._internal(this.userBloc);
}
