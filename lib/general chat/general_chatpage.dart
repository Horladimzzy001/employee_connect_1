import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phidrillsim_connect/general%20chat/display%20general%20messages.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeneralChatPage extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  GeneralChatPage({required this.currentUser});

  @override
  _GeneralChatPageState createState() => _GeneralChatPageState();
}

class _GeneralChatPageState extends State<GeneralChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();
  File? _image;
  final List<String> allowedRoles = ['Manager', 'Supervisors', 'Group Leads'];

Future<void> sendPushNotification(String title, String body, String currentUserDeviceToken) async {
  var url = Uri.parse('https://onesignal.com/api/v1/notifications');
  // im a fine boy
  // Fetch all device tokens except the current user
  QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
  List<String> deviceTokens = [];
  
  usersSnapshot.docs.forEach((doc) {
    String? deviceToken = doc['deviceToken']; // Assuming 'deviceToken' is the field where the token is stored
    if (deviceToken != null && deviceToken != currentUserDeviceToken) { // Exclude the current user's token
      deviceTokens.add(deviceToken);
    }
  });

  var response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json; charset=UTF-8",
      "Authorization": "YOUR_ONESIGNAL_REST_API_KEY",
    },
    body: jsonEncode({
      "app_id": "YOUR_ONESIGNAL_APP_ID",
      "include_player_ids": deviceTokens,  // Use device tokens instead of player IDs
      "headings": {"en": title},
      "contents": {"en": body},
    }),
  );
  
  if (response.statusCode == 200) {
    print('Notification sent successfully');
  } else {
    print('Failed to send notification');
  }
}


  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty || _image != null) {
      // Show loader only if there's an image to upload
      if (_image != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Sending image..."),
              ],
            ),
          ),
        );
      }

      String? imageUrl;
      if (_image != null) {
        // Upload image to Firebase Storage and get the download URL
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images/${DateTime.now().millisecondsSinceEpoch}.png');
        await storageRef.putFile(_image!);
        imageUrl = await storageRef.getDownloadURL();

        // Close the loader after image is uploaded
        Navigator.pop(context);
      }

      // Prepare the message data with or without image URL
      Map<String, dynamic> messageData = {
        'message': _messageController.text.trim(),
        'time': DateTime.now(),
        'sender': '${widget.currentUser['firstName']} ${widget.currentUser['surname']}',
        'profilePictureURL': widget.currentUser['profilePictureURL'] ?? '',
        'status': widget.currentUser['status'],
        'imageUrl': imageUrl, // Add image URL if available
      };

      // Send the message to Firestore
      await FirebaseFirestore.instance.collection('general_messages').add(messageData);

      // Clear message input and image
      _messageController.clear();
      setState(() {
        _image = null; // Clear the image after sending
      });

      // Send a notification for the new message via OneSignal
// await sendPushNotification(
//   'New Message from ${widget.currentUser['firstName']}',
//   _messageController.text.trim(),
//   widget.currentUser['deviceToken'],  // Pass the current user's device token
// );

    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      bool? confirmSend = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Send Image"),
          content: Text("Are you sure you want to send this image?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Send'),
            ),
          ],
        ),
      );

      if (confirmSend == true) {
        setState(() {
          _image = File(pickedFile.path); // Save image file
        });
        _sendMessage();
      }
    }
  }

  Future<void> _deleteAllMessages() async {
    var collection = _firestore.collection('general_messages');
    var snapshots = await collection.get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All messages deleted')));
  }

  bool _canDeleteMessages() {
    String role = widget.currentUser['role'] ?? 'General';
    return allowedRoles.contains(role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set the background to white
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  Text(
                    'General Chat',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  if (_canDeleteMessages())
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.blue),
                      onPressed: () async {
                        bool? confirmDelete = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete All Messages'),
                            content: Text(
                                'Are you sure you want to delete all messages? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmDelete == true) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 20),
                                  Text("Deleting messages...")
                                ],
                              ),
                            ),
                          );
                          await _deleteAllMessages();
                          Navigator.pop(context); // Close the loader dialog
                        }
                      },
                    ),
                ],
              ),
            ),
            // Messages List
            Expanded(
              child: DisplayGenMessages(
                currentUser: widget.currentUser,
              ),
            ),
            // Message Input Field
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image, color: Colors.blue),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
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
}
