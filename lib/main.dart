import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core
import 'package:phidrillsim_connect/screens/intro.dart'; // Import your intro screen
import 'package:provider/provider.dart';
import 'package:phidrillsim_connect/models/user.dart';
import 'package:phidrillsim_connect/screens/services/auth.dart';
import 'package:phidrillsim_connect/shared/loading.dart'; // Import your custom loading indicator

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await Firebase.initializeApp(); // Initialize Firebase

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _precacheImages(BuildContext context) async {
    // Pre-cache all images before the app starts
    await precacheImage(AssetImage('assets/images/drill.jpg'), context);
    await precacheImage(AssetImage('assets/images/hands.jpg'), context);
    await precacheImage(AssetImage('assets/images/intropic_one.jpg'), context);
  }

  @override
  Widget build(BuildContext context) {
    return StreamProvider<CustomUser?>.value(
      value: AuthService().user,
      initialData: null,
      child: MaterialApp(
        home: FutureBuilder(
          future: _precacheImages(context),
          builder: (context, snapshot) {
            // Show your custom loading indicator while pre-caching is in progress
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Loading(); // Use your custom loading widget
            } else {
              // Once images are pre-cached, navigate to the IntroductionPage
              return IntroductionPage();
            }
          },
        ),
      ),
    );
  }
}
