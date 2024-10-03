import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phidrillsim_connect/loading.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:phidrillsim_connect/screens/colleagues.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:clipboard/clipboard.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class DisplayGenMessages extends StatefulWidget {
  final Map<String, dynamic> currentUser; // Current user

  const DisplayGenMessages({Key? key, required this.currentUser})
      : super(key: key);

  @override
  State<DisplayGenMessages> createState() => _DisplayGenMessagesState();
}

class _DisplayGenMessagesState extends State<DisplayGenMessages> {
  final ScrollController _scrollController = ScrollController();

  final Stream<QuerySnapshot> _generalMessageStream = FirebaseFirestore.instance
      .collection('general_messages')
      .orderBy('time', descending: false)
      .snapshots();

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the controller when no longer needed
    super.dispose();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Full Employee':
        return Colors.green; // 🟢
      case 'Contract Employee':
        return Colors.yellow; // 🟡
      case 'Intern Employee':
        return Colors.blue; // 🔵
      case 'Mentor/Advisor':
        return Colors.purple; // 🟣
      case 'Former Employee':
        return Colors.black; // ⚫
      case 'Fired Employee':
        return Colors.red; // 🔴
      default:
        return Colors.grey; // Default color for unknown status
    }
  }
// dimeji will remove sendpushnotifications for ne signal below


Future<void> sendPushNotification(String title, String body, String currentUserDeviceToken) async {
  var url = Uri.parse('https://onesignal.com/api/v1/notifications');
  
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
      "Authorization": "MzQ1ZjU5OTEtYzVhZC00NzE1LThiZGUtNjE1Yzk0MDI1NjI4",
    },
    body: jsonEncode({
      "app_id": "fccf0d7c-8243-46dd-af70-1b359d1ec095",
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


// where it stops dim

  // Function to show full-screen image
  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/dimeji26.jpg'),
        fit: BoxFit.cover)
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _generalMessageStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
      
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Loading();
          }
      
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No messages yet! Start the conversation.'),
            );
          }
      
          List<QueryDocumentSnapshot> messages = snapshot.data!.docs;
          String currentUserName =
              '${widget.currentUser['firstName']} ${widget.currentUser['surname']}';
      
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
      
          return ListView.builder(
            controller: _scrollController, // Attach the ScrollController
            itemCount: messages.length,
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            itemBuilder: (context, index) {
              var messageData = messages[index].data() as Map<String, dynamic>;
              String messageText = messageData['message'] ?? 'No message';
              String senderName = messageData['sender'] ?? 'Unknown sender';
              String profilePictureURL = messageData['profilePictureURL'] ?? '';
              String status = messageData['status'] ?? 'Unknown status';
              String? imageUrl = messageData['imageUrl']; // Image URL if available
              Timestamp? timestamp = messageData['time'];
              DateTime messageTime = timestamp != null
                  ? timestamp.toDate()
                  : DateTime.now();
      
              bool isSentByCurrentUser = senderName == currentUserName;
              Alignment messageAlignment = isSentByCurrentUser
                  ? Alignment.centerRight
                  : Alignment.centerLeft;
              Color messageColor = isSentByCurrentUser
                  ? Colors.blue[100]!
                  : Colors.grey[200]!;
      
              // Gesture to view profile
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Align(
                  alignment: messageAlignment,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: messageColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          topRight: Radius.circular(12.0),
                          bottomLeft: isSentByCurrentUser
                              ? Radius.circular(12.0)
                              : Radius.circular(0),
                          bottomRight: isSentByCurrentUser
                              ? Radius.circular(0)
                              : Radius.circular(12.0),
                        ),
                      ),
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: isSentByCurrentUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              //  god abeg
                              
      // god abeg
      
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 5,
                                    backgroundColor: getStatusColor(status),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 6.0),
                          GestureDetector(
                            onLongPress: () {
                              FlutterClipboard.copy(messageText).then((value) =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Message copied to clipboard!'))));
                            },
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? GestureDetector(
        onTap: () => _showFullScreenImage(imageUrl),
        child: CachedNetworkImage(
      imageUrl: imageUrl,
      height: 100,
      width: 100, // Set reduced size
      fit: BoxFit.cover,
      placeholder: (context, url) => CircularProgressIndicator(), // Loading spinner while image loads
      errorWidget: (context, url, error) => Icon(Icons.error), // Error icon if image fails to load
        ),
      )
                                : 
                                // here 1
                                Linkify(
                                    onOpen: (link) async {
                                      final Uri url = Uri.parse(link.url);
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(url);
                                      } else {
                                        throw 'Could not launch ${link.url}';
                                      }
                                    },
                                    text: messageText,
                                    style: TextStyle(fontSize: 16.0),
                                    linkStyle: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline),
                                  ),
      
                                  // here 2
                          ),
                          SizedBox(height: 6.0),
                          Text(
                            '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')} - ${messageTime.day}/${messageTime.month}/${messageTime.year}',
                            style: TextStyle(
                                fontSize: 12.0, color: Colors.grey[600]),
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
    );
  }
}

// Full-Screen Image Widget
class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Image View', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.pop(context); // Close full-screen view on tap
          },
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain, // Display image with proper aspect ratio
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}

                    
             
// come back here when youre