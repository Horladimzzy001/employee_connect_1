import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase core
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'package:phidrillsim_connect/intro.dart';
import 'package:phidrillsim_connect/screens/auth/signup_screen.dart';
import 'package:phidrillsim_connect/screens/auth/login_screen.dart';
import 'package:phidrillsim_connect/screens/home.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Firebase App Check
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart'; // OneSignal
import 'package:flutter/foundation.dart' show kIsWeb;


import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';



// Dr Etaje Abeg o
// Future<bool> _requestStoragePermission() async {
//   if (Platform.isAndroid) {
//     var androidInfo = await DeviceInfoPlugin().androidInfo;
//     if (androidInfo.version.sdkInt >= 30) {
//       // Android 11 and above
//       var status = await Permission.storage.status;
//       if (status.isGranted) {
//         return true;
//       } else {
//         var result = await Permission.storage.request();
//         return result == PermissionStatus.granted;
//       }
//     } else {
//       // Below Android 11
//       return await _requestPermission(Permission.storage);
//     }
//   }
//   return true;
// }




// Create a global instance of Local Notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Background message handler for Firebase Messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Initialize Firebase if needed
  _showNotification(message); // Show the notification
}

// Function to show the local notification
Future<void> _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel', // Channel ID
    'High Importance Notifications', // Channel name
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    message.notification?.title ?? 'New Message',
    message.notification?.body ?? 'You have a new notification',
    platformChannelSpecifics,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  if (kIsWeb) {
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBUUE4BZtCV9NWGjSiNDUDem32XDBtJlM4",
      authDomain: "employee-connect-772d3.firebaseapp.com",
      databaseURL: "https://employee-connect-772d3-default-rtdb.firebaseio.com",
      projectId: "employee-connect-772d3",
      storageBucket: "employee-connect-772d3.appspot.com",
      messagingSenderId: "893105852039",
      appId: "1:893105852039:web:a994dfcaec41e9f3d23222",
    ),
  );
} else {
  await Firebase.initializeApp(); // For mobile platforms
}

  
  // Activate Firebase App Check
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.appAttest,
  );
  
// Initialize OneSignal
  OneSignal.shared.setAppId("fccf0d7c-8243-46dd-af70-1b359d1ec095");

  // Retrieve the Player ID and store it in Firestore
  OneSignal.shared.getDeviceState().then((deviceState) async {
    String? playerId = deviceState?.userId;
    if (playerId != null) {
      // Assuming you have a method to get the current user's UID
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // Store the Player ID in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'playerId': playerId,
      });
    }
  });

  // Optional: request user's permission for notifications (for iOS)
  OneSignal.shared.promptUserForPushNotificationPermission().then((accepted) {
    print("Accepted permission: $accepted");
  });

  // Handle notification opened event
OneSignal.shared.setNotificationOpenedHandler((OSNotificationOpenedResult result) {
  print("Notification opened: ${result.notification.jsonRepresentation().replaceAll("\\n", "\n")}");
});

// Handle notification received event
OneSignal.shared.setNotificationWillShowInForegroundHandler((OSNotificationReceivedEvent event) {
  print("Notification received: ${event.notification.jsonRepresentation().replaceAll("\\n", "\n")}");
});


  // Initialize Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // Request permission for iOS notifications
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }
  // // Request storage permission after notifications permission
  // await requestStoragePermission(); // <-- Add this line

  // Set up background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Handle messages when the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    _showNotification(message); // Show notification when a new message arrives
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: IntroductionPage(), // Show the IntroductionPage or AuthCheck widget to manage auth state
    );
  }
}

class AuthCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen to auth state
      builder: (context, snapshot) {
        // Check if Firebase is still connecting
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } 
        // If the user is signed in, show the Home screen
        else if (snapshot.hasData) {
          return HomeScreen();
        } 
        // If the user is not signed in, show the Login screen
        else {
          return LoginScreen(); // Or SignUpScreen if preferred
        }
      },
    );
  }
}
