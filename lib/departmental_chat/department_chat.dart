import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phidrillsim_connect/loading.dart';
import 'package:firebase_messaging/firebase_messaging.dart';



class DepartmentChatScreen extends StatefulWidget {
  @override
  _DepartmentChatScreenState createState() => _DepartmentChatScreenState();
}

class _DepartmentChatScreenState extends State<DepartmentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentUserName;
  String? _currentUserDepartment;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUserData();
  }

  Future<void> _getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      var userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _currentUserName = '${userData['firstName']} ${userData['surname']}';
        _currentUserDepartment = userData['department'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
  if (_messageController.text.trim().isNotEmpty && _currentUserDepartment != null) {
    await _firestore.collection('department_chats').doc(_currentUserDepartment).collection('messages').add({
      'message': _messageController.text.trim(),
      'sender': _currentUserName,
      'time': FieldValue.serverTimestamp(),
    });

    _messageController.clear();

    // Send notification
    FirebaseMessaging.instance.sendMessage(
      data: {
        'title': 'New Department Message',
        'body': '$_currentUserName sent a message in your department',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }
}


  Future<void> _deleteAllMessages() async {
    if (_currentUserDepartment != null) {
      QuerySnapshot messagesSnapshot = await _firestore
          .collection('department_chats')
          .doc(_currentUserDepartment)
          .collection('messages')
          .get();

      for (DocumentSnapshot doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Loading(); // Use your custom Loading class
    }

    if (_currentUserDepartment == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Error: Department not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: SafeArea(
        child: Column(
          children: [
            // Header Row without back arrow
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  Text(
                    '${_currentUserDepartment ?? 'Department'} Chat',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Spacer(),
                  // All department members can delete messages
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('department_chats')
                    .doc(_currentUserDepartment)
                    .collection('messages')
                    .orderBy('time', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            'Error loading messages: ${snapshot.error}'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Loading(); // Use your custom Loading class
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No messages here yet'));
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var messageData = snapshot.data!.docs[index].data()
                          as Map<String, dynamic>;
                      String messageText = messageData['message'] ?? '';
                      String senderName = messageData['sender'] ?? 'Unknown';
                      Timestamp? timestamp = messageData['time'];
                      DateTime messageTime = timestamp != null
                          ? timestamp.toDate()
                          : DateTime.now();

                      bool isSentByCurrentUser = senderName == _currentUserName;

                      return Container(
                        alignment: isSentByCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Card(
                            color: isSentByCurrentUser
                                ? Colors.blue
                                : Colors.grey[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            margin: EdgeInsets.symmetric(vertical: 4.0),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: isSentByCurrentUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: isSentByCurrentUser
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 4.0),
                                  Text(
                                    messageText,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: isSentByCurrentUser
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 6.0),
                                  Text(
                                    '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      color: isSentByCurrentUser
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Message Input Field
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 20.0,
                        ),
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete All Messages'),
        content:
            Text('Are you sure you want to delete all messages in this department?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteAllMessages();
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
