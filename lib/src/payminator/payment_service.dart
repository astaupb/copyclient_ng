import 'dart:convert';

import 'package:angular/core.dart' show Injectable;

import 'package:http/http.dart' as http;

@Injectable()
class PaymentService {
  final http.Client _client;
  static const String baseUrl = 'https://astaprint.upb.de/aufwerter';

  PaymentService(this._client);

  Future<String> getPaymentUrl(int userId, int value) async {
    return await _client
        .post('$baseUrl/create/$value?user_id=$userId')
        .then((http.Response response) {
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))['link'];
      } else {
        throw Exception('wrong status code received: ${response.statusCode} ${response.body}');
      }
    });
  }
}
