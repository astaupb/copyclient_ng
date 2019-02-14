import 'package:angular/core.dart';
import 'package:blocs_copyclient/preview.dart';
import 'package:http/browser_client.dart';

import '../backend_shiva.dart';

@Injectable()
class PreviewProvider {
  static final PreviewProvider _singleton = PreviewProvider._internal(
    PreviewBloc(BackendShiva(BrowserClient())),
  );

  PreviewBloc previewBloc;

  factory PreviewProvider() => _singleton;

  PreviewProvider._internal(this.previewBloc);
}
