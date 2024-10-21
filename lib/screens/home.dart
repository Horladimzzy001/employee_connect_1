import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phidrillsim_connect/bookings/bookings.dart';
import 'package:phidrillsim_connect/chat/private_chat';

import 'package:phidrillsim_connect/departmental_chat/department_chat.dart';
import 'package:phidrillsim_connect/general%20chat/general_chatpage.dart';
import 'package:phidrillsim_connect/screens/auth/login_screen.dart';
import 'package:phidrillsim_connect/screens/calendar';

import 'package:phidrillsim_connect/screens/colleagues.dart';
import 'package:phidrillsim_connect/screens/manager.dart';
import 'package:phidrillsim_connect/screens/settings.dart';
import 'package:phidrillsim_connect/screens/submissions.dart';
import 'package:phidrillsim_connect/screens/supervisor.dart';
import 'package:phidrillsim_connect/upload/upload_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _firstName = '';
  String _surname = '';
  String _department = '';
  String _status = '';
  String _role = '';
  String _profilePictureURL = '';
  bool _isEmailVerified = false;
  String _userId = ''; // Add this line to store the userId
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // To control the sidebar

  

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      var userData =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userData.exists) {
        setState(() {
          _firstName = userData['firstName'] ?? '';
          _surname = userData['surname'] ?? '';
          _department = userData['department'] ?? 'N/A';
          _status = userData['status'] ?? 'N/A';
          _role = userData['role'] ?? 'General';
          _profilePictureURL = userData['profilePictureURL'] ?? '';
          _isEmailVerified = user.emailVerified;
          _userId = user.uid; // Store the userId
          
        });
      }
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Navigating to LoginScreen
    );
  }

  int _currentIndex = 0; // For BottomNavigationBar

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      key: _scaffoldKey, // Key to control the sidebar
      backgroundColor: Colors.white, // Set background color to white
      drawer: Drawer(
        // Sidebar drawer
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 30),
              // User Avatar and Info
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue[100],
                backgroundImage: _profilePictureURL.isNotEmpty
                    ? NetworkImage(_profilePictureURL)
                    : null,
                child: _profilePictureURL.isEmpty
                    ? Text(
                        _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '',
                        style: TextStyle(fontSize: 40, color: Colors.blue),
                      )
                    : null,
              ),
              SizedBox(height: 10),
              Text(
                '$_firstName $_surname',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                _status == 'Visitor'
                    ? 'Visitor'
                    : _status == 'Client'
                        ? 'Client'
                        : _department,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 20),
              if (_isEmailVerified)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Email is Verified',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Email is not verified',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              Spacer(), // Push Sign Out to the bottom
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Sign Out'),
                onTap: _signOut,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Toggle button to open the sidebar
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu, color: Colors.blue),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                Text(
                  'Home',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            // Centered Welcome Message
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'Hello, $_firstName!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // Grid of Features
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: EdgeInsets.all(16),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: _buildHomeTiles(),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue, // Active icon color
        unselectedItemColor: Colors.grey, // Inactive icon color
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Navigate to respective screens
          switch (index) {
            case 0:
              // Already on HomeScreen
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadPage()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHomeTiles() {
    List<Widget> tiles = [];

    if (_status != 'Visitor' && _status != 'Client') {
      tiles.add(_buildHomeTile(Icons.chat, 'Department Chat', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DepartmentChatScreen()),
        );
      }));
    }

    // Add Manager-specific tile
    if (_role == 'Manager') {
      tiles.add(_buildHomeTile(Icons.admin_panel_settings, 'Manager Dashboard', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ManagerPage()),
        );
      }));
    }

    // Add Supervisor-specific tile
    if (_role == 'Supervisors') {
      tiles.add(_buildHomeTile(Icons.supervisor_account, 'Supervisor Dashboard', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SupervisorPage()),
        );
      }));
    }

    tiles.addAll([
      _buildHomeTile(Icons.forum, 'General Chat', () {
        Map<String, dynamic> currentUser = {
          'firstName': _firstName,
          'surname': _surname,
          'department': _department,
          'status': _status,
          'role': _role, // Make sure to include the role
          'userId': _userId, // Include the userId here
          'profilePictureURL': _profilePictureURL, // Include profile picture URL if needed
         'deviceToken': '', // Include deviceToken if you have it
        };

        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => GeneralChatPage(currentUser: currentUser)),
        );
      }),
      _buildHomeTile(Icons.message, 'Private Chat', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PrivateChat()),
        );
      }),
      _buildHomeTile(Icons.group, 'Colleagues', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ColleaguesScreen()),
        );
      }),
      _buildHomeTile(Icons.calendar_today, 'Calendar', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CalendarPage()),
        );
      }),
      
      _buildHomeTile(Icons.assignment, 'Submissions', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SubmissionsPage()),
        );
      }),
      
      _buildHomeTile(Icons.date_range, 'Bookings', () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookingsPage()),
        );
      }),
      // Add more features if needed
    ]);

    return tiles;
  }

  Widget _buildHomeTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white, // White background
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              SizedBox(height: 10),
              Text(
                label,
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Match the app's theme
      backgroundColor: Colors.white,
      body: Center(child: Text('No New Notifications to Display')),
    );
  }
}
