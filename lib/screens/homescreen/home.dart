import 'package:flutter/material.dart';
import 'package:phidrillsim_connect/screens/authenticate/sign_in.dart';
import 'package:phidrillsim_connect/screens/homescreen/chat.dart';
import 'package:phidrillsim_connect/screens/homescreen/profile.dart';
import 'package:phidrillsim_connect/screens/services/auth.dart'; // For the sign out function
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  final AuthService _auth = AuthService();

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _auth = AuthService();
  int _selectedIndex = 0;

  String? userName = ''; // To store user's name
  String? userEmail = ''; // To store user's email

  // Page list for bottom navigation
  final List<Widget> _pages = [
    GroupsPage(), // Groups page
    DepartmentPage(), // Department page
    UploadPage(), // Upload page
    SettingsPage(), // Settings page
  ];

  @override
  void initState() {
    super.initState();
    _getUserInfo(); // Fetch user information when home page is loaded
  }

  // Function to fetch user data from Firestore
  Future<void> _getUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        userName = userDoc['name'];
        userEmail = userDoc['email'];
      });
    }
  }

  // Function to handle navigation on bottom navigation bar tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Dashboard')),
        backgroundColor: Theme.of(context).primaryColor,
      ),

      // Side Drawer
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    userName ?? 'User Name',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),

            // Drawer Buttons with Optimized Content
            ListTile(
              leading: Icon(Icons.person),
              title: Tooltip(message: "Profile", child: Text('Profile')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(),),);
                // Navigate to Profile Page (to be implemented later)
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Tooltip(message: "Settings", child: Text('Settings')),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = 3; // Navigate to Settings tab
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Tooltip(message: "Help & Support", child: Text('Help & Support')),
              onTap: () {
                Navigator.pop(context);
                // Navigate to Help and Support Page (to be implemented)
              },
            ),

            // Sign Out button
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Tooltip(message: "Sign Out", child: Text('Sign Out')),
              onTap: () async {
                await _auth.signOut();
                Navigator.pop(context);
                // After sign-out, navigate back to login screen
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SignIn()));
              },
            ),
          ],
        ),
      ),

      // Body: Show the selected page
      body: SingleChildScrollView(child: _pages[_selectedIndex]),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment),
            label: 'Department',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Future Groups Page Implementation
class GroupsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Groups Page - To Be Implemented'),
    );
  }
}

// Future Department Page Implementation
class DepartmentPage extends StatefulWidget {
  @override
  _DepartmentPageState createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? departmentName; // Variable to hold the department name
  bool loading = true;    // Loading state

  @override
  void initState() {
    super.initState();
    _getUserDepartment(); // Fetch the user's department when the page loads
  }

  // Function to fetch the department of the current user
  Future<void> _getUserDepartment() async {
    try {
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        setState(() {
          departmentName = userDoc['department']; // Get the department from Firestore
          loading = false; // Set loading to false when data is fetched
        });
      }
    } catch (e) {
      print("Error fetching department: $e");
      setState(() => loading = false); // Stop loading even if there's an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Center(child: CircularProgressIndicator()) // Show a loading indicator while fetching
        : Scaffold(
            appBar: AppBar(
              title: Text(departmentName != null ? '$departmentName Chat' : 'Department Chat'),
            ),
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  if (departmentName != null) {
                    // Navigate to ChatScreen with the fetched departmentName
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(departmentName: departmentName!),
                      ),
                    );
                  }
                },
                child: Text('Go to Department Chat'),
              ),
            ),
          );
  }
}


// Future Upload Page Implementation
class UploadPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Upload Page - To Be Implemented'),
    );
  }
}

// Future Settings Page Implementation
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Settings Page - To Be Implemented'),
    );
  }
}
