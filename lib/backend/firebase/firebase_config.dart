import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyARtpFwuNIgiIbQtEVp6h6zf1unqbtHmNE",
            authDomain: "travel-app-miuvoz.firebaseapp.com",
            projectId: "travel-app-miuvoz",
            storageBucket: "travel-app-miuvoz.appspot.com",
            messagingSenderId: "953740340207",
            appId: "1:953740340207:web:333ee2e22204883b40641a"));
  } else {
    await Firebase.initializeApp();
  }
}
