// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
/*
Remplacer les valeurs par celles de ton google-services.json :
current_key → apiKey
mobilesdk_app_id → appId
project_id → projectId
storage_bucket → storageBucket
project_number → messagingSenderId*/

class DefaultFirebaseOptions {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: 'AIzaSyDdO9TqGkYXZ-PQ4ZW6v0FrYulOEokA-V8',
    appId: '1:117575539930:android:b5814228b8c80be7db59e3',
    messagingSenderId: '117575539930',
    projectId: 'devmob-6f59a',
    storageBucket: 'devmob-6f59a.firebasestorage.app',
  );
}