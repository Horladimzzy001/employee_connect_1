import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const sendMessageNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const messageData = snapshot.data();

    const sender = messageData.sender;
    const receiver = messageData.receiver;

    // Do not send a notification to the sender
    if (sender === receiver) {
      return null;
    }

    // Get the receiver's FCM token
    const userDoc = await admin.firestore().collection('users')
      .where('firstName', '==', receiver.split(' ')[0])
      .where('surname', '==', receiver.split(' ')[1])
      .get();

    if (userDoc.empty) {
      console.log('No matching user found for receiver');
      return null;
    }

    const receiverData = userDoc.docs[0].data();
    const fcmToken = receiverData.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token for receiver');
      return null;
    }

    // Send notification
    const payload = {
      notification: {
        title: `New message from ${sender}`,
        body: messageData.message,
      },
      data: {
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
        sender: sender,
      },
    };

    await admin.messaging().sendToDevice(fcmToken, payload);
    return null;
  });
