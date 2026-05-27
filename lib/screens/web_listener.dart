// web_listener.dart
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// SETUP ONLINE / OFFLINE LISTENERS
void setupWebListeners({
  required void Function() onOffline,
  required void Function() onOnline,
}) {
  /// OFFLINE EVENT
  web.window.addEventListener(
    'offline',
    ((web.Event e) {
      /// INTERNET LOST
      onOffline();
    }).toJS,
  );

  /// ONLINE EVENT
  web.window.addEventListener(
    'online',
    ((web.Event e) {
      /// INTERNET RESTORED
      onOnline();
    }).toJS,
  );
}
