import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phidrillsim_connect/screens/auth/signup_screen.dart';
import 'package:phidrillsim_connect/screens/home.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for form fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Loading state indicator
  bool _isLoading = false;

  // Video player controller
  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoPlayerFuture;

  // Initialize the video controller
  @override
  void initState() {
    super.initState();

    // Initialize the video player controller with a local asset
    _videoController = VideoPlayerController.asset('assets/images/Logodrillvid.mp4');

    // Initialize the controller and store the Future for later use
    _initializeVideoPlayerFuture = _videoController.initialize().then((_) {
      // Ensure the first frame is shown after the video is initialized
      setState(() {});
    });

    // // Optionally, set the video to loop
    // _videoController.setLooping(true);

    // Start playing the video automatically
    _videoController.play();
  }

  // Dispose of the video controller
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  // Function to handle sign-in (unchanged)
  void _signIn() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Get the user ID
      String userId = userCredential.user!.uid;

      // Get the Firebase Messaging token
      String? token = await _firebaseMessaging.getToken();

      // Update the user's document with the token
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'deviceToken': token,
        });
      }

      // Handle navigation to a new screen after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      // Handle errors or show an alert to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to sign in: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the screen is large
    bool isLargeScreen = MediaQuery.of(context).size.width > 800;
    double horizontalPadding = isLargeScreen ? 100 : 24.0;
    double videoWidth =
        isLargeScreen ? 300 : MediaQuery.of(context).size.width * 0.5;
    double fontSize =
        isLargeScreen ? 32 : MediaQuery.of(context).size.width * 0.05;

    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: MediaQuery.of(context).size.height * 0.05,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Column(
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),

                // Video Player Widget
                FutureBuilder(
                  future: _initializeVideoPlayerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: videoWidth,
                          height: videoWidth * (9 / 16), // Maintain aspect ratio
                          child: VideoPlayer(_videoController),
                        ),
                      );
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                // Header Text
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 30),
                // Email Field
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Password Field
                SizedBox(
                  width: double.infinity,
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Sign In Button or Loading Indicator
                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _signIn,
                          child: Text(
                            'Sign In',
                            style: TextStyle(fontSize: 18),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                        ),
                ),
                SizedBox(height: 16),
                // Sign Up Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignUpScreen()),
                        );
                      },
                      child: Text('Sign Up'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
