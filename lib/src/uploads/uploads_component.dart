import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_bloc/angular_bloc.dart';
import 'package:angular_components/material_button/material_fab.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_router/angular_router.dart';
import 'package:blocs_copyclient/upload.dart';

import '../auth_guard.dart';
import '../providers/auth_provider.dart';
import '../providers/uploads_provider.dart';

@Component(
  selector: 'uploads',
  templateUrl: 'uploads_component.html',
  styleUrls: ['uploads_component.css'],
  directives: [
    NgFor,
    MaterialListComponent,
    MaterialListItemComponent,
    MaterialFabComponent,
    MaterialIconComponent,
  ],
  pipes: [BlocPipe],
)
class UploadsComponent extends AuthGuard implements OnInit {
  UploadBloc uploadBloc;
  String statusString = '';

  UploadsComponent(
      UploadsProvider uploadsProvider, AuthProvider authProvider, Router router)
      : super(authProvider, router) {
    uploadBloc = uploadsProvider.uploadBloc;
  }

  @override
  void ngOnInit() {
    // init listener for uploadBloc states
    uploadBloc.state.listen((UploadState state) {
      if (state.isResult) {
        statusString = 'Fertig';
      } else if (state.isException) {
        statusString = 'Error: ${state.error.toString()}';
      }
    });
  }

  void onUploadFileSelected(List<File> files) {
    print(files
        .expand<String>((file) => [file.name, file.lastModified.toString()]));

    var reader = FileReader();

    reader.readAsArrayBuffer(files[0]);

    reader.onLoadEnd.listen((progress) async {
      print(
          'uploading into bloc ${progress.loaded.toString()}/${progress.total}');
      if (progress.loaded == progress.total) {
        uploadBloc.onUpload(reader.result as List<int>,
            filename: files[0].name, color: true);
        await Future.delayed(Duration(seconds: 1));
        refreshQueue();
      }
    });
  }

  void refreshQueue() => uploadBloc.onRefresh();
}
