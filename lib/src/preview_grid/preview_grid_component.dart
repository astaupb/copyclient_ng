import 'dart:async';
import 'dart:convert';

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:blocs_copyclient/blocs.dart';
import 'package:copyclient_ng/src/providers/preview_provider.dart';

@Component(
  selector: 'preview-grid',
  templateUrl: 'preview_grid_component.html',
  styleUrls: ['preview_grid_component.scss.css'],
  directives: [
    NgIf,
  ],
  providers: [],
  exports: [base64Encode],
)
class PreviewGridComponent implements OnInit, OnDestroy {
  static PreviewBloc previewBloc;
  StreamSubscription previewListener;

  @Input('job')
  Job job;

  bool refreshing = false;

  /// stores the actual preview data
  /// has a maximum of 4 items
  List<List<int>> previews = [];

  /// easy  getters for knowing which NuP to show
  bool get shouldShowNup1 => (job.jobOptions.nup == 1) && (previews.length >= 1);
  bool get shouldShowNup2 => (job.jobOptions.nup == 2) && (previews.length >= 2);
  bool get shouldShowNup4 => (job.jobOptions.nup == 4) && (previews.length >= 4);

  bool get isPortrait {
    final Map dimensions = getImageDimensions(previews.first);
    return (dimensions['width'] < dimensions['height']);
  }

  PreviewGridComponent(PreviewProvider previewProvider) {
    previewBloc = previewProvider.previewBloc;
  }

  @override
  void ngOnDestroy() {
    if (previewListener != null) previewListener.cancel();
  }

  @override
  void ngOnInit() {
    previewListener = previewBloc.state.skip(1).listen((PreviewState state) {
      if (state.isResult) {
        refreshing = false;
        previews =
            state.value.singleWhere((PreviewSet preview) => preview.jobId == job.id).previews;
      } else if (state.isBusy) {
        refreshing = true;
      } else if (state.isException) {
        refreshing = false;
      }
    });

    previewBloc.getPreview(job);
  }

  /// return image dimensions of PNG files according to information found in the file header
  /// returned as [Map] with 'width' and 'height' as keys and the amount of pixels as values
  Map<String, int> getImageDimensions(List<int> imageBytes) {
    Map<String, int> _dim = {'width': 0, 'height': 0};

    String header = '';
    for (int i = 0; i < 8; i++) {
      header = header +
          ((imageBytes[i].toRadixString(16).length < 2) ? '0' : '') +
          imageBytes[i].toRadixString(16);
    }

    if (header == '89504e470d0a1a0a') {
      String width = '';
      for (int i = 16; i < 20; i++) {
        width = width +
            ((imageBytes[i].toRadixString(16).length < 2) ? '0' : '') +
            imageBytes[i].toRadixString(16);
      }
      _dim['width'] = int.parse(width, radix: 16);

      String height = '';
      for (int i = 20; i < 24; i++) {
        height = height +
            ((imageBytes[i].toRadixString(16).length < 2) ? '0' : '') +
            imageBytes[i].toRadixString(16);
      }
      _dim['height'] = int.parse(height, radix: 16);
    } else {
      print('preview_grid_component: header ($header) of preview does not match png header');
    }
    return _dim;
  }
}
