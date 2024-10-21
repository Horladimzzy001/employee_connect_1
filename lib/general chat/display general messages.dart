import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phidrillsim_connect/loading.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:phidrillsim_connect/general%20chat/utils.dart'; // Adjust the path as necessary

import 'package:cached_network_image/cached_network_image.dart';
import 'package:phidrillsim_connect/screens/profile_screen.dart';
import 'package:phidrillsim_connect/screens/full_screen_image.dart';

class DisplayGenMessages extends StatefulWidget {
  final Map<String, dynamic> currentUser; // Current user

  const DisplayGenMessages({Key? key, required this.currentUser})
      : super(key: key);

  @override
  State<DisplayGenMessages> createState() => _DisplayGenMessagesState();
}

class _DisplayGenMessagesState extends State<DisplayGenMessages> {
  Map<String, Map<String, dynamic>>? _userCache;
  final ScrollController _scrollController = ScrollController();

  final Stream<QuerySnapshot> _generalMessageStream = FirebaseFirestore.instance
      .collection('general_messages')
      .orderBy('time', descending: false)
      .snapshots();

  final List<String> allowedRoles = ['Manager', 'Supervisors', 'Group Leads'];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

// Fetch users and store in _userCache
Future<void> _fetchUsers() async {
  QuerySnapshot usersSnapshot =
      await FirebaseFirestore.instance.collection('users').get();
  setState(() {
    _userCache = {
      for (var doc in usersSnapshot.docs)
        doc.id: doc.data() as Map<String, dynamic>
    };
  });
  }
    // Function to determine the status color
  Color _getUserStatusColor(Map<String, dynamic> userData) {
    String? employeeStatus = userData['employeeStatus'];
    String? status = userData['status'];

    if (employeeStatus != null && employeeStatus.isNotEmpty) {
      // If the user is an employee, use the employeeStatus
      return getStatusColor(employeeStatus);
    } else if (status != null && status.isNotEmpty) {
      // If the user is not an employee, use the status (e.g., Client or Visitor)
      return getStatusColor(status);
    }
    return Colors.grey; // Default color if no status is found
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the controller when no longer needed
    super.dispose();
  }

  // Function to get initials from sender name
  String getInitials(String name) {
    List<String> nameParts = name.split(' ');
    String initials = '';
    if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      initials += nameParts[0][0];
    }
    if (nameParts.length > 1 && nameParts[1].isNotEmpty) {
      initials += nameParts[1][0];
    }
    return initials.toUpperCase();
  }

  // Function to handle avatar tap
// Function to handle avatar tap
void _onAvatarTap(String senderId) async {
  // Fetch user data with privacy considerations
  DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(senderId)
      .get();
  
  if (userSnapshot.exists) {
    var userData = userSnapshot.data() as Map<String, dynamic>;
    String profilePictureURL = userData['profilePictureURL'] ?? '';

    if (profilePictureURL.isNotEmpty) {
      // Navigate to full screen image directly
      _showFullScreenImage(profilePictureURL);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No profile picture available')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User not found')),
    );
  }
}

  // Function to check if user can delete messages
  bool _canDeleteMessages() {
    String role = widget.currentUser['role'] ?? 'General';
    return allowedRoles.contains(role);
  }

  // Function to handle message long-press options
  void _onMessageLongPress(Map<String, dynamic> messageData,
      bool isSentByCurrentUser, String messageId) {
    List<Widget> actions = [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          Clipboard.setData(
              ClipboardData(text: messageData['message'] ?? ''));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Message copied to clipboard')),
          );
        },
        child: Text('Copy Text'),
      ),
      TextButton(
        onPressed: () async {
          Navigator.of(context).pop();
          if (isSentByCurrentUser || _canDeleteMessages()) {
            await _deleteMessage(messageId);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You cannot delete this message')),
            );
          }
        },
        child: Text('Delete', style: TextStyle(color: Colors.red)),
      ),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message Options'),
        content: Text('What would you like to do?'),
        actions: actions,
      ),
    );
  }

  // Function to delete message
  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection('general_messages')
        .doc(messageId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Message deleted')),
    );
  }

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
    if (_userCache == null) {
      return Loading();
    }
    return Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/dimeji26.jpg'),
              fit: BoxFit.cover)),
      child: StreamBuilder<QuerySnapshot>(
        stream: _generalMessageStream,
        builder:
            (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
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

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });

          return ListView.builder(
            controller: _scrollController, // Attach the ScrollController
            itemCount: messages.length,
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            itemBuilder: (context, index) {
              var messageDoc = messages[index];
              var messageData = messageDoc.data() as Map<String, dynamic>;
              String messageId = messageDoc.id;

              String messageText = messageData['message'] ?? 'No message';
              String senderName = messageData['sender'] ?? 'Unknown sender';
              String senderEmail = messageData['senderEmail'] ?? '';
              Timestamp? timestamp = messageData['time'];
              DateTime messageTime = timestamp != null
                  ? timestamp.toDate()
                  : DateTime.now();
              String senderId = messageData['senderId'] ?? '';


// Fetch sender's data from _userCache using senderId
Map<String, dynamic>? senderData = senderId.isNotEmpty
    ? _userCache![senderId]
    : null;

// Debugging
if (senderData == null) {
  print('senderData is null for senderId: $senderId');
} else {
  print('senderData found for senderId: $senderId');
}

              

            // Get profilePictureURL and status from senderData
            String profilePictureURL =
                senderData?['profilePictureURL'] ?? '';
            String status = '';
            if (senderData != null) {
              if (senderData['employeeStatus'] != null && senderData['employeeStatus'] != '') {
                status = senderData['employeeStatus'];
              } else if (senderData['status'] != null && senderData['status'] != '') {
                status = senderData['status'];
              } else {
                status = 'Unknown status';
              }
            }

            bool isSentByCurrentUser =
                senderId == widget.currentUser['userId'];

            Alignment messageAlignment = isSentByCurrentUser
                ? Alignment.centerRight
                : Alignment.centerLeft;
            Color messageColor = isSentByCurrentUser
                ? Colors.blue[100]!
                : Colors.grey[200]!;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Align(
                  alignment: messageAlignment,
                  child: GestureDetector(
                    onLongPress: () {
                      _onMessageLongPress(
                          messageData, isSentByCurrentUser, messageId);
                    },
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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    _onAvatarTap(senderId);
                                  },
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.blue[100],
                                    backgroundImage:
                                        profilePictureURL.isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                profilePictureURL)
                                            : null,
                                    child: profilePictureURL.isEmpty
                                        ? Text(
                                            getInitials(senderName),
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        senderName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      CircleAvatar(
                                        radius: 5,
                                        backgroundColor:
                                            getStatusColor(status),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.0),
                            // Message content (text or image)
                            if (messageData['imageUrl'] != null &&
                                (messageData['imageUrl'] as String).isNotEmpty)
                              GestureDetector(
                                onTap: () => _showFullScreenImage(
                                    messageData['imageUrl']),
                                child: CachedNetworkImage(
                                  imageUrl: messageData['imageUrl'],
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              )
                            else
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
