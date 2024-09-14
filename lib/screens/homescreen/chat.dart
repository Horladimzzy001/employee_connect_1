import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String departmentName; // The user's department
  ChatScreen({required this.departmentName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  String? selectedChat = 'General Chat'; // Default to general chat

  // Send message to Firestore
  Future<void> _sendMessage(String message) async {
  if (message.trim().isEmpty) return;

  User? currentUser = _auth.currentUser;
  if (currentUser != null) {
    try {
      String collectionPath = selectedChat == 'General Chat'
          ? 'general_chat'
          : 'department_chat/${widget.departmentName}';

      await FirebaseFirestore.instance.collection(collectionPath).add({
        'sender': currentUser.uid,
        'message': message,
        'timestamp': Timestamp.now(),
      });

      _messageController.clear(); // Clear the input field after sending
    } catch (e) {
      print("Error sending message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message. Please try again.')),
      );
    }
  }
}


  // Widget to build the chat messages stream
  Widget _buildMessagesStream() {
  User? currentUser = _auth.currentUser;  // Fetch the current user
  
  String collectionPath = selectedChat == 'General Chat'
      ? 'general_chat'
      : 'department_chat/${widget.departmentName}';

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection(collectionPath)
        .orderBy('timestamp')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return Center(child: CircularProgressIndicator());
      }

      List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

      return ListView.builder(
        itemCount: docs.length,
        itemBuilder: (context, index) {
          var data = docs[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage('https://example.com/user-avatar.png'), // Placeholder or dynamic user image
            ),
            title: Text(data['message']),
            subtitle: Text(
              'Sent by: ${data['sender']}\n${DateFormat('hh:mm a').format(data['timestamp'].toDate())}', // Formatting timestamp
            ),
            trailing: currentUser != null && currentUser.uid == data['sender']
                ? Icon(Icons.check_circle, color: Colors.green) // Example for marking user's own messages
                : null,
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedChat!),
        actions: [
          DropdownButton<String>(
            value: selectedChat,
            items: [
              DropdownMenuItem(value: 'General Chat', child: Text('General Chat')),
              DropdownMenuItem(value: 'Department Chat', child: Text('${widget.departmentName} Chat')),
            ],
            onChanged: (value) {
              setState(() {
                selectedChat = value!;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
  child: Column(
    children: [
      Expanded(child: _buildMessagesStream()), // Displays chat messages
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Enter your message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (message) => _sendMessage(message), // Also send message on 'Enter' key
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () => _sendMessage(_messageController.text),
            ),
          ],
        ),
      ),
    ],
  ),
),

    );
  }
}
