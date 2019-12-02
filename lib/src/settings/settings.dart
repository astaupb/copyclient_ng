/// Object representation of the settings form
class Settings {
  String name;
  String password;
  String passwordRetype;
  String passwordOld;

  Settings({
    this.name = '',
    this.password = '',
    this.passwordRetype = '',
    this.passwordOld = ''
  });

  Map<String, String> toMap() => {
        'name': name,
        'password': password,
        'password_old': passwordOld,
        'password_retype': passwordRetype,
      };

  @override
  String toString() => toMap().toString();
}