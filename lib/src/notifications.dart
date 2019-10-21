class _Notification {
  Notifications notifications = Notifications();
  String text;
  int id;

  _Notification(int id, String text) {
    this.id = id;
    this.text = text;

    Future.delayed(const Duration(seconds: 5))
        .then((_){
          notifications.list.removeWhere((n) => n.id == this.id);
          notifications._buildNotificationText();
          if (notifications.list.length == 0) {
            notifications.show = false;
            notifications.text = '';
          }
        });
  }
}

class Notifications {
  static final Notifications _singleton = Notifications._();
  bool show = false;
  String text = '';
  int count = 0;
  int max = 20;
  List<_Notification> list = [];

  factory Notifications() {
    return _singleton;
  }

  Notifications._();

  void add(String message) {
      list.add(new _Notification(count, message));
      _buildNotificationText();
      show = true;
      count = (count + 1) % max;
  }

  void _buildNotificationText() {
    String t = '';

    for (int i = list.length - 1; i > -1; i--) {
      t += list[i].text + (i > 0 ? '<hr />' : '');
    }

    text = t;
  }
}