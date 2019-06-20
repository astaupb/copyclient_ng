import 'package:angular/core.dart';
import 'package:blocs_copyclient/print_queue.dart';

import '../backend_shiva.dart';

@Injectable()
class PrintQueueProvider {
  static final PrintQueueProvider _singleton = PrintQueueProvider._internal(
    PrintQueueBloc(BackendShiva()),
  );

  PrintQueueBloc printQueueBloc;

  factory PrintQueueProvider() => _singleton;

  PrintQueueProvider._internal(this.printQueueBloc);
}
