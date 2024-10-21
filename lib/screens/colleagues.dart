import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phidrillsim_connect/chat/chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For current user info
import 'package:phidrillsim_connect/general%20chat/display%20general%20messages.dart';
import 'package:phidrillsim_connect/general%20chat/utils.dart';
import 'package:phidrillsim_connect/loading.dart'; // Import your Loading widget
import 'package:phidrillsim_connect/screens/profile_screen.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ColleaguesScreen extends StatefulWidget {
  @override
  _ColleaguesScreenState createState() => _ColleaguesScreenState();
}

class _ColleaguesScreenState extends State<ColleaguesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth for current user

Future<List<Map<String, dynamic>>> fetchUsers() async {
  if (_cachedUsers != null) {
    return _cachedUsers!;
  }

  QuerySnapshot snapshot = await _firestore.collection('users').get();
  List<Map<String, dynamic>> users = snapshot.docs.map((doc) {
    var data = doc.data() as Map<String, dynamic>;

    bool concealAll = data['concealAll'] ?? false;

    // Always show first name and surname, even if concealAll is true
    return {
      'firstName': data['firstName'] ?? 'No First Name',
      'surname': data['surname'] ?? 'No Surname',
      'userId': doc.id,
      'email': concealAll || !(data['showEmail'] ?? true) ? 'Hidden' : (data['email'] ?? 'No Email'),
      'employeeStatus': data['employeeStatus'] ?? 'Unknown',
      'department': data['department'] ?? 'No Department', // Always show department
      'profilePictureURL': data['profilePictureURL'] ?? '',
      'telephone': concealAll || !(data['showTelephone'] ?? true) ? 'Hidden' : (data['telephone'] ?? 'No Telephone'),
      'hobbies': concealAll || !(data['showHobbies'] ?? true) ? 'Hidden' : (data['hobbies'] ?? 'No Hobbies'),
      'favouriteQuote': concealAll || !(data['showFavouriteQuote'] ?? true) ? 'Hidden' : (data['favouriteQuote'] ?? 'No Favourite Quote'),
    };
  }).toList();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString('cachedUsers', jsonEncode(users));

  _cachedUsers = users;
  return users;
}


@override
void initState() {
  super.initState();
  _loadCachedUsers();
}

Future<void> _loadCachedUsers() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? cachedData = prefs.getString('cachedUsers');

  if (cachedData != null) {
    setState(() {
      _cachedUsers = List<Map<String, dynamic>>.from(jsonDecode(cachedData));
    });
  }
}


  List<Map<String, dynamic>>? _cachedUsers; // To cache the colleagues' details



  void _showUserOptions(BuildContext context, Map<String, dynamic> selectedUser) async {
    // Get current user information
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      // Handle the case where the current user is not logged in (optional)
      return;
    }

    DocumentSnapshot currentUserSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();
    var currentUserData = currentUserSnapshot.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select an action'),
          content: Text(
              'Do you want to view the profile or message ${selectedUser['firstName']} ${selectedUser['surname']}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    // Navigate to profile screen with user details
                    return ProfileScreen(user: selectedUser);
                  }),
                );
              },
              child: Text('View Profile'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    // Pass both currentUserData and selectedUser to ChatPage
                    return ChatPage(
                      currentUser: currentUserData, // Pass current user's data
                      selectedUser: selectedUser, // Pass selected user's data
                    );
                  }),
                );
              },
              child: Text('Message'),
            ),
          ],
        );
      },
    );
  }

  String getInitials(String firstName, String surname) {
    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName[0];
    }
    if (surname.isNotEmpty) {
      initials += surname[0];
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: SafeArea(
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.blue),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Text(
                  'Colleagues',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Use your custom Loading class
                    return Loading();
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error fetching users'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No users found'));
                  }

                  // Display the list of users
                  List<Map<String, dynamic>> users = snapshot.data!;
                  return ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      var user = users[index];
                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blue[100],
                              backgroundImage: user['profilePictureURL'].isNotEmpty
                                  ? NetworkImage(user['profilePictureURL'])
                                  : null,
                              child: user['profilePictureURL'].isEmpty
                                  ? Text(
                                      getInitials(
                                          user['firstName'], user['surname']),
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: getStatusColor(user['employeeStatus']),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          '${user['firstName']} ${user['surname']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          // Show dialog for profile or message options with user details
                          _showUserOptions(context, user);
                        },
                      );
                    },
                  );
                }
                
                , 


                // dim stop here
              ),
            ),
          ],
        ),
      ),
    );
  }
}


