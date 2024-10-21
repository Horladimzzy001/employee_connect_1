// profile_screen.dart
import 'package:flutter/material.dart';
import 'full_screen_image.dart';


class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  ProfileScreen({required this.user});

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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16), // Add padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
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
                    'Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              // User Avatar
              Center(
                  child: GestureDetector(
    onTap: () {
      if (user['profilePictureURL'].isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (_) {
          return FullScreenImage(imageUrl: user['profilePictureURL']);
        }));
      }
    },

                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: user['profilePictureURL'].isNotEmpty
                      ? NetworkImage(user['profilePictureURL'])
                      : null,
                  child: user['profilePictureURL'].isEmpty
                      ? Text(
                          getInitials(user['firstName'], user['surname']),
                          style: TextStyle(fontSize: 50, color: Colors.blue),
                        )
                      : null,
                ),
              ),
              ),
              SizedBox(height: 20),
              // User Details
              Center(
                child: Text(
                  '${user['firstName']} ${user['surname']}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  'Email: ${user['email']}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  'Department: ${user['department']}',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
              ),
              SizedBox(height: 20),
              // Additional User Details
              if (user['telephone'].isNotEmpty) ...[
                Text(
                  'Telephone:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  user['telephone'],
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 10),
              ],
              if (user['hobbies'].isNotEmpty) ...[
                Text(
                  'Hobbies:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  user['hobbies'],
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 10),
              ],
              if (user['favouriteQuote'].isNotEmpty) ...[
                Text(
                  'Favourite Quote:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '"${user['favouriteQuote']}"',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
