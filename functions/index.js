const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendMessageNotification = functions.firestore
  .document('general_messages/{messageId}')
  .onCreate(async (snap, context) => {
    const messageData = snap.data();
    const senderName = messageData.sender;
    const recipientToken = messageData.recipientToken; // Get recipient token

    if (!recipientToken) {
      console.log('No recipient token found');
      return null;
    }

    const payload = {
      notification: {
        title: `New message from ${senderName}`,
        body: messageData.message || 'You have a new message!',
      },
      token: recipientToken,
    };

    try {
      await admin.messaging().send(payload);
      console.log('Notification sent');
    } catch (error) {
      console.error('Error sending notification:', error);
    }
  });
