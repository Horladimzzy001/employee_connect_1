import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phidrillsim_connect/bookings/user_selection.dart/user_avail.dart';
import 'package:phidrillsim_connect/loading.dart';

class UserSelectionPage extends StatefulWidget {
  @override
  _UserSelectionPageState createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  List<Map<String, dynamic>> users = [];
  String searchQuery = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      users = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = Colors.lightBlueAccent;

    if (isLoading) {
      return Loading();
    }

    List<Map<String, dynamic>> filteredUsers = users.where((user) {
      final String firstName = user['firstName'] ?? '';
      final String surname = user['surname'] ?? '';
      final String department = user['department'] ?? '';

      return firstName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          surname.toLowerCase().contains(searchQuery.toLowerCase()) ||
          department.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              'Select User',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: buttonColor),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search users by name or department',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: filteredUsers.isNotEmpty
                  ? ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        String departmentDisplay =
                            user['department'] != null &&
                                    user['department'] != 'N/A'
                                ? user['department']
                                : user['status'] == 'Client'
                                    ? 'Client'
                                    : 'Visitor';

                        return Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.person,
                              color: buttonColor,
                              size: 40,
                            ),
                            title: Text(
                              '${user['firstName'] ?? 'No First Name'} ${user['surname'] ?? 'No Surname'}',
                              style: TextStyle(fontSize: 18),
                            ),
                            subtitle: Text('Department: $departmentDisplay'),
                            onTap: () {
                              if (user['email'] != null &&
                                  user['email'] is String) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserAvailabilityPage(
                                        userEmail: user['email'],
                                        userId: user['id']),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'User email is missing or invalid.')));
                              }
                            },
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        'No users found.',
                        style:
                            TextStyle(fontSize: 16, color: Colors.redAccent),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
