import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DisplayMessages extends StatefulWidget {
  final Map<String, dynamic> currentUser; // Current user
  final Map<String, dynamic> selectedUser; // Selected user

  const DisplayMessages({
    Key? key,
    required this.currentUser,
    required this.selectedUser,
  }) : super(key: key);

  @override
  State<DisplayMessages> createState() => _DisplayMessagesState();
}

class _DisplayMessagesState extends State<DisplayMessages> {
  // Stream for the Firestore message collection
  final Stream<QuerySnapshot> _messageStream = FirebaseFirestore.instance
      .collection('messages')
      .orderBy('time', descending: true)
      .snapshots(); // Stream that listens to changes in the 'messages' collection

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _messageStream, // The stream to listen to
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        // Handle errors during data fetching
        if (snapshot.hasError) {
          return Center(
            child: Text('Something went wrong: ${snapshot.error}'),
          );
        }

        // Display a loading spinner while the data is loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ));
        }

        // If no messages are present, display a friendly message
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No messages yet! Start the conversation.'),
          );
        }

        // Extract the messages from the snapshot
        List<QueryDocumentSnapshot> messages = snapshot.data!.docs;

        // Build the list of messages
        return ListView.builder(
          itemCount: messages.length, // Number of messages to display
          shrinkWrap: true,
          reverse: true, // To show the latest message at the bottom
          physics: BouncingScrollPhysics(), // Smooth scrolling effect
          itemBuilder: (context, index) {
            // Extract individual message details
            var messageData = messages[index].data() as Map<String, dynamic>;
            String messageText = messageData['message'] ?? 'No message';
            String senderName = messageData['sender'] ?? 'Unknown sender';
            String receiverName = messageData['receiver'] ?? 'Unknown receiver';
            Timestamp timestamp = messageData['time'] ?? Timestamp.now();
            DateTime messageTime = timestamp.toDate();

            // Filter messages to show only between the current user and the selected user
            if ((senderName ==
                        '${widget.currentUser['firstName']} ${widget.currentUser['surname']}' &&
                    receiverName ==
                        '${widget.selectedUser['firstName']} ${widget.selectedUser['surname']}') ||
                (senderName ==
                        '${widget.selectedUser['firstName']} ${widget.selectedUser['surname']}' &&
                    receiverName ==
                        '${widget.currentUser['firstName']} ${widget.currentUser['surname']}')) {
              // Determine if the message was sent by the current user
              bool isSentByCurrentUser = senderName ==
                  '${widget.currentUser['firstName']} ${widget.currentUser['surname']}';

              return Align(
                alignment: isSentByCurrentUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  padding: EdgeInsets.all(12.0),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isSentByCurrentUser ? Colors.blue : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    crossAxisAlignment: isSentByCurrentUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        messageText, // Display the message text
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
              );
            } else {
              // Return an empty container if the message doesn't match the current user and selected user
              return SizedBox.shrink();
            }
          },
        );
      },
    );
  }
}
