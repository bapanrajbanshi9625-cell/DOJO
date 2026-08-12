import 'package:firebase_core/firebase_core.dart'
    show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web platforms are not configured.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS platforms are not configured.',
        );

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android =
      FirebaseOptions(
    apiKey:
        'AIzaSyAUUiXYiPevzQyg_wLuhwzCk-N9UEx8GFs',
    appId:
        '1:719463503810:android:b4a6686354d244c300a85b',
    messagingSenderId:
        '719463503810',
    projectId:
        'dojo-platform-a5dc8',
    databaseURL:
        'https://dojo-platform-a5dc8-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket:
        'dojo-platform-a5dc8.firebasestorage.app',
  );
}
