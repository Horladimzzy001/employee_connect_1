import 'package:flutter/material.dart';
import 'package:phidrillsim_connect/models/user.dart';
import 'package:phidrillsim_connect/screens/authenticate/authenticate.dart';
import 'package:phidrillsim_connect/screens/homescreen/home.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final customUser = Provider.of<CustomUser?>(context); // Correct way to use Provider

    // Return either Home or Authenticate widget based on user's auth status
    if (customUser == null) {
      return Authenticate();
    } else {
      return Home(); // Replace Home with your actual home screen widget
    }
  }
}
