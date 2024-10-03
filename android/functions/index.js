// const functions = require('firebase-functions');  // Firebase v1 API
// const admin = require('firebase-admin');
// const nodemailer = require('nodemailer');

// // Initialize Firebase Admin SDK
// admin.initializeApp();

// // Configure nodemailer with your email provider
// let transporter = nodemailer.createTransport({
//   service: 'gmail',
//   auth: {
//     user: 'your-email@gmail.com',
//     pass: 'your-email-password',  // Use Gmail App Password if using 2FA
//   },
// });

// // Firestore trigger for when a new meeting is created
// exports.sendEmailOnMeetingCreation = functions.firestore
//   .document('meetings/{meetingId}')
//   .onCreate(async (snap, context) => {
//     const meetingData = snap.data();

//     // Fetch all users from Firestore
//     const usersSnapshot = await admin.firestore().collection('users').get();
    
//     // Send emails to all users
//     const promises = usersSnapshot.docs.map(async (doc) => {
//       const userData = doc.data();
//       const userName = `${userData.firstName} ${userData.surname}`;
//       const userEmail = userData.email;

//       // Determine organizer's department or status (Client/Visitor)
//       let organizerDepartment = meetingData.organizerDepartment || 'N/A';
//       if (organizerDepartment === 'N/A') {
//         organizerDepartment = meetingData.organizerStatus === 'Visitor' || meetingData.organizerStatus === 'Client'
//           ? meetingData.organizerStatus
//           : 'Employee';
//       }

//       // Prepare the email content for each user
//       const mailOptions = {
//         from: 'your-email@gmail.com',
//         to: userEmail,
//         subject: `New Meeting: ${meetingData.title}`,
//         html: `
//           <p>Dear ${userName},</p>
//           <p>A new meeting has been scheduled:</p>
//           <p><strong>Title:</strong> ${meetingData.title}</p>
//           <p><strong>Description:</strong> ${meetingData.description}</p>
//           <p><strong>Date:</strong> ${meetingData.date}</p>
//           <p><strong>Organizer:</strong> ${meetingData.organizer} (${organizerDepartment})</p>
//           <p>Best regards,<br>Your Team</p>
//         `,
//       };

//       // Send the email
//       try {
//         await transporter.sendMail(mailOptions);
//         console.log(`Email sent to ${userEmail}`);
//       } catch (error) {
//         console.error(`Error sending email to ${userEmail}:`, error);
//       }
//     });

//     // Wait for all email sending promises to complete
//     await Promise.all(promises);
//     console.log('Emails sent to all users.');
//   });
