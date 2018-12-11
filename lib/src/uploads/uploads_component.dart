import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/upload.dart';

import '../auth_guard.dart';
import '../auth_provider.dart';
import '../providers/uploads_provider.dart';

@Component(
  selector: 'uploads',
  templateUrl: 'uploads_component.html',
  styleUrls: ['uploads_component.css'],
  directives: [
    NgFor,
    MaterialListComponent,
    MaterialListItemComponent,
  ],
)
class UploadsComponent extends AuthGuard implements OnInit {
  UploadBloc uploadBloc;
  List<DispatcherTask> queue;
  String statusString = '';

  UploadsComponent(
      UploadsProvider uploadsProvider, AuthProvider authProvider, Router router)
      : super(authProvider, router) {
    uploadBloc = uploadsProvider.uploadBloc;
  }

  @override
  void ngOnInit() {
    uploadBloc.state.listen((UploadState state) {
      if (state.isResult) {
        queue = state.value;
        statusString = 'Fertig';
      } else if (state.isException) {
        statusString = 'Error: ${state.error.toString()}';
      }
    });
    uploadBloc.onStart();
  }
}
