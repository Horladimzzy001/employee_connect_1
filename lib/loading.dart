import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Center(
        child: SpinKitCircle(
          color: Colors.blue, // Set spinner color to blue
          size: 70.0,
        ),
      ),
    );
  }
}
