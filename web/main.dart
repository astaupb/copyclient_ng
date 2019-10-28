import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:copyclient_ng/app_component.template.dart' as ng;
import 'package:copyclient_ng/messages/messages_all.dart';
import 'package:intl/intl_browser.dart';
import 'package:logging/logging.dart';

import 'main.template.dart' as self;

void main() async {
  // init locale from browser storage or system
  String locale;
  if (window.localStorage.containsKey('locale')) {
    locale = window.localStorage['locale'];
  } else {
    locale = await findSystemLocale();
  }
  print('locale: $locale');
  await initializeMessages(locale);

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
