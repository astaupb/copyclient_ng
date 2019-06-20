import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:copyclient_ng/app_component.template.dart' as ng;
import 'package:logging/logging.dart';

import 'main.template.dart' as self;

void main() {
  runApp(ng.AppComponentNgFactory);

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print(
        '${rec.level.name}: ${rec.time.toString().split(' ')[1]}: ${rec.loggerName}: ${rec.message}');
  });
}

@GenerateInjector(
  routerProvidersHash, // You can use routerProviders in production
)
final InjectorFactory injector = self.injector$Injector;
