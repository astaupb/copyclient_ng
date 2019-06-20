import 'package:angular/core.dart';
import 'package:blocs_copyclient/upload.dart';

import '../backend_shiva.dart';

@Injectable()
class UploadsProvider {
  static final UploadsProvider _singleton = UploadsProvider._internal(
    UploadBloc(BackendShiva()),
  );

  UploadBloc uploadBloc;

  factory UploadsProvider() => _singleton;

  UploadsProvider._internal(this.uploadBloc);
}
