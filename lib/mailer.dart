import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Firestore for fetching users
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// Function to send email
Future<void> sendEmailOnMeetingCreation(Map<String, dynamic> meetingData) async {
  String username = 'your-email@gmail.com';
  String password = 'your-email-password';  // Use an App Password if 2FA is enabled

  // Configure SMTP server
  final smtpServer = SmtpServer(
    'smtp.gmail.com',
    port: 587,
    ssl: false,
    username: username,
    password: password,
    // heloName is not supported, so we omit it
  );

  // Fetch all users from Firestore
  QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

  // Loop through users and send emails
  for (var doc in usersSnapshot.docs) {
    final userData = doc.data() as Map<String, dynamic>;
    final userName = '${userData['firstName']} ${userData['surname']}';
    final userEmail = userData['email'];

    // Determine organizer's department or status
    String organizerDepartment = meetingData['organizerDepartment'] ?? 'N/A';
    if (organizerDepartment == 'N/A') {
      organizerDepartment = meetingData['organizerStatus'] == 'Visitor' || meetingData['organizerStatus'] == 'Client'
        ? meetingData['organizerStatus']
        : 'Employee';
    }

    // Create email content
    final message = Message()
      ..from = Address(username, 'Your App Name')
      ..recipients.add(userEmail)  // Recipients email
      ..subject = 'New Meeting: ${meetingData['title']}'  // Email subject
      ..html = '''
        <p>Dear $userName,</p>
        <p>A new meeting has been scheduled:</p>
        <p><strong>Title:</strong> ${meetingData['title']}</p>
        <p><strong>Description:</strong> ${meetingData['description']}</p>
        <p><strong>Date:</strong> ${meetingData['date']}</p>
        <p><strong>Organizer:</strong> ${meetingData['organizer']} ($organizerDepartment)</p>
        <p>Best regards,<br>Your Team</p>
      ''';

    // Try to send the email
    try {
      final sendReport = await send(message, smtpServer);
      print('Email sent to $userEmail: ${sendReport.toString()}');
    } on MailerException catch (e) {
      print('Message not sent to $userEmail. Error: $e');
    }
  }
}
