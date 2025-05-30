import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Default Firebase configuration options for your app
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyBSXXcFpN-zfMF0HR70Phay0VN4RcsA6-k',
      appId: '1:488149400173:android:79b1e7feac0c878c281d64',
      messagingSenderId: '488149400173',
      projectId: 'schoolbusapp-ccb3f',
      storageBucket: 'schoolbusapp-ccb3f.firebasestorage.app',
    );
  }
}