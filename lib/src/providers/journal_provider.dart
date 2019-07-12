import 'package:angular/core.dart';
import 'package:blocs_copyclient/journal.dart';

import '../backend_shiva.dart';

@Injectable()
class JournalProvider {
  static final JournalProvider _singleton = JournalProvider._internal(
    JournalBloc(BackendShiva()),
  );

  JournalBloc journalBloc;

  factory JournalProvider() => _singleton;

  JournalProvider._internal(this.journalBloc);
}
