import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phidrillsim_connect/chat/display_messages.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> currentUser; // Current user data
  final Map<String, dynamic> selectedUser; // Selected user data

  ChatPage({required this.currentUser, required this.selectedUser});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // Text editing controller for the message input
  final TextEditingController _messageController = TextEditingController();

  // FirebaseFirestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FirebaseAuth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to send a message
  void _sendMessage() async {
    // Check if the message is not empty
    if (_messageController.text.trim().isNotEmpty) {
      // Set the message into the Firestore collection
      await _firestore.collection('messages').doc().set({
        'message': _messageController.text.trim(), // Message text
        'time': DateTime.now(), // Current timestamp
        'sender':
            '${widget.currentUser['firstName']} ${widget.currentUser['surname']}', // Sender's name
        'receiver':
            '${widget.selectedUser['firstName']} ${widget.selectedUser['surname']}', // Receiver's name
      });

      // Clear the message input field after sending
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.blue),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      widget.selectedUser['firstName'].isNotEmpty
                          ? widget.selectedUser['firstName'][0]
                          : '',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '${widget.selectedUser['firstName']} ${widget.selectedUser['surname']}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            // Display messages above the text field
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: DisplayMessages(
                  currentUser: widget.currentUser, // Pass current user
                  selectedUser: widget.selectedUser, // Pass selected user
                ), // Your custom widget for displaying messages
              ),
            ),
            // Message input field at the bottom
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _messageController, // Assign controller
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
                    onPressed: _sendMessage, // Call _sendMessage on button press
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose the message controller when the widget is destroyed
    _messageController.dispose();
    super.dispose();
  }
}
