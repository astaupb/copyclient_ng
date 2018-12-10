import 'package:angular/angular.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';

@Component(
  selector: 'fullscreen-spinner',
  template: '<div class="filler"><material-spinner></material-spinner></div>',
  styles: [
    '''
    .filler {
      position: absolute;
      min-width: 100%;
      min-height: 100%;
      background-color: white;
      text-align: center;
      padding-top: 45%;
    }'''
  ],
  directives: [MaterialSpinnerComponent],
)
class FullscreenSpinnerComponent {}
