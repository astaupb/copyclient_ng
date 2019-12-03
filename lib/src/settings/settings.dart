/// Object representation of the settings form
class Settings {
  String name;
  String password;
  String passwordRetype;
  String passwordOld;
  String email;

  Settings({
    this.name = '',
    this.password = '',
    this.passwordRetype = '',
    this.passwordOld = '',
    this.email = ''
  });

  Map<String, String> toMap() => {
        'name': name,
        'password': password,
        'password_old': passwordOld,
        'password_retype': passwordRetype,
        'email': email,
      };

  @override
  String toString() => toMap().toString();
}