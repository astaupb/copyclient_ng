import 'package:angular/core.dart';
import 'package:blocs_copyclient/pdf_download.dart';
import 'package:http/browser_client.dart';

import '../backend_shiva.dart';

@Injectable()
class PdfProvider {
  static final PdfProvider _singleton = PdfProvider._internal(
    PdfBloc(BackendShiva(BrowserClient())),
  );

  PdfBloc pdfBloc;

  factory PdfProvider() => _singleton;

  PdfProvider._internal(this.pdfBloc);
}
