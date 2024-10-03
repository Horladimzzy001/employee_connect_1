import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubmissionsPage extends StatefulWidget {
  @override
  _SubmissionsPageState createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  User? user;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  // Method to fetch assigned user names
  Future<List<String>> _getAssignedUserNames(List<dynamic> userIds) async {
    List<String> userNames = [];
    for (String userId in userIds) {
      try {
        DocumentSnapshot userDoc =
            await firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String firstName = userData['firstName'] ?? '';
          String surname = userData['surname'] ?? '';
          userNames.add('$firstName $surname');
        }
      } catch (e) {
        // Handle error
      }
    }
    return userNames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removed AppBar as per your request
      backgroundColor: Colors.white,
      body: user == null
          ? Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('fileAssignments')
                  .where('uploadedBy', isEqualTo: user!.uid)
                  // Removed orderBy to avoid needing an index
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // Display the error message
                  return Center(
                    child: Text(
                        'Error fetching submissions: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("You haven't made any submissions yet."),
                  );
                }
                List<DocumentSnapshot> docs = snapshot.data!.docs;

                // Sort documents by timestamp descending
                docs.sort((a, b) {
                  Map<String, dynamic> aData = a.data() as Map<String, dynamic>;
                  Map<String, dynamic> bData = b.data() as Map<String, dynamic>;
                  Timestamp aTimestamp = aData['timestamp'] ?? Timestamp.now();
                  Timestamp bTimestamp = bData['timestamp'] ?? Timestamp.now();
                  return bTimestamp.compareTo(aTimestamp);
                });

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = docs[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                    String fileName = data['fileName'] ?? '';
                    List<dynamic> assignedTo = data['assignedTo'] ?? [];
                    bool isLocked = data.containsKey('locked') ? data['locked'] : false;
                    Timestamp timestamp = data['timestamp'] ?? Timestamp.now();

                    DateTime dateTime = timestamp.toDate();
                    String formattedDate =
                        '${dateTime.day}/${dateTime.month}/${dateTime.year}';

                    return Card(
                      margin:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Icon(
                          Icons.insert_drive_file,
                          color: Colors.blue,
                          size: 40,
                        ),
                        title: Text(
                          fileName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: FutureBuilder<List<String>>(
                          future: _getAssignedUserNames(assignedTo),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              String assignedNames =
                                  snapshot.data!.join(', ');
                              return Text(
                                'Assigned to: $assignedNames',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            } else if (snapshot.hasError) {
                              return Text('Error fetching assigned users');
                            } else {
                              return Text('Loading assigned users...');
                            }
                          },
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLocked)
                              Icon(Icons.lock, color: Colors.red),
                            SizedBox(height: 5),
                            Text(
                              formattedDate,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Optionally implement actions on tap
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
