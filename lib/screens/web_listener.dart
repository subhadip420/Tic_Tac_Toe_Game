// web_listener.dart
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void setupWebListeners({
  required void Function() onOffline,
  required void Function() onOnline,
}) {

  web.window.addEventListener(
    'offline',
    ((web.Event e) {
      onOffline(); // no return
    }).toJS,
  );

  web.window.addEventListener(
    'online',
    ((web.Event e) {
      onOnline(); // no return
    }).toJS,
  );
}