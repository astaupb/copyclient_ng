import 'dart:convert';
import 'dart:html';

import 'package:angular/angular.dart';

import 'package:angular_forms/angular_forms.dart';

import 'package:http/browser_client.dart';

@Component(
  selector: 'login-form',
  styleUrls: ['login_component.css'],
  templateUrl: 'login_component.html',
  directives: [formDirectives],
)
class LoginComponent implements OnInit {
  Credentials cred;
  String token;
  BrowserClient client;

  bool loggedIn;

  @override
  void ngOnInit() {
    cred = new Credentials(username: 'test', password: 'test!420');
    token = '';
    loggedIn = (window.sessionStorage['token'] != null && window.sessionStorage['token'].isNotEmpty);
    client = new BrowserClient();
  }

  void submitData() async {
    print(cred.toString());
    var response = await client.post(
      'https://sunrise.upb.de/astaprint-backend/user/login',
      headers: {
        'Accept': 'text/plain',
        'Authorization':
            'Basic ${base64.encode(utf8.encode(cred.username + ':' + cred.password))}',
      },
    );
    print(response.body);

    if (response.statusCode == 200) {
      token = response.body;
      loggedIn = true;

      window.sessionStorage['token'] = token;
    }
  }
}

class Credentials {
  String username;
  String password;

  Credentials({this.username, this.password});

  @override
  String toString() {
    return 'username: $username\npassword: $password';
  }
}
