import 'package:angular/core.dart';
import 'package:blocs_copyclient/pdf_creation.dart';

@Injectable()
class PdfCreationProvider {
  static final PdfCreationProvider _singleton = PdfCreationProvider._internal(
    PdfCreationBloc(),
  );

  PdfCreationBloc pdfCreationBloc;

  factory PdfCreationProvider() => _singleton;

  PdfCreationProvider._internal(this.pdfCreationBloc);
}
