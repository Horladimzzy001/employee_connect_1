import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phidrillsim_connect/loading.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAvailabilityPage extends StatefulWidget {
  final String userEmail;
  final String userId; // The ID of the user whose availability we're viewing

  UserAvailabilityPage({required this.userEmail, required this.userId});

  @override
  _UserAvailabilityPageState createState() => _UserAvailabilityPageState();
}

class _UserAvailabilityPageState extends State<UserAvailabilityPage> {
  List<Map<String, dynamic>> availableDates = [];
  List<Map<String, dynamic>> availableTimes = [];
  DateTime? selectedDate;
  String meetingPurpose = '';
  String meetingTitle = '';
  bool isLoading = true;

  User? currentUser;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
    _fetchAvailability();
  }

  void _fetchCurrentUser() {
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _fetchAvailability() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('availability')
          .doc(widget.userId)
          .collection('dates')
          .where('isBooked', isEqualTo: false)
          .get();

      setState(() {
        availableDates = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'start_time': (doc['start_time'] as Timestamp).toDate(),
            'end_time': (doc['end_time'] as Timestamp).toDate(),
            'time_zone': doc['time_zone'],
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      // Handle exceptions
      print('Error fetching availability: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _getAvailableTimesForSelectedDate(DateTime date) {
    setState(() {
      availableTimes = availableDates.where((availability) {
        return DateFormat('yyyy-MM-dd').format(availability['start_time']) ==
            DateFormat('yyyy-MM-dd').format(date);
      }).toList();
    });
  }

  Future<void> _bookMeeting(String docId, Map<String, dynamic> availability) async {
    if (meetingTitle.isNotEmpty && meetingPurpose.isNotEmpty) {
      try {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;

        await firestore.runTransaction((transaction) async {
          DocumentReference availabilityRef = firestore
              .collection('availability')
              .doc(widget.userId)
              .collection('dates')
              .doc(docId);

          DocumentSnapshot snapshot = await transaction.get(availabilityRef);

          if (snapshot['isBooked'] == false) {
            // Mark the availability slot as booked
            transaction.update(availabilityRef, {'isBooked': true});

            // Store the meeting details in a 'meetings' collection
            await firestore.collection('meetings').add({
              'title': meetingTitle,
              'description': meetingPurpose,
              'start_time': availability['start_time'],
              'end_time': availability['end_time'],
              'time_zone': availability['time_zone'],
              'with_user_id': widget.userId,
              'with_user_email': widget.userEmail,
              'booked_by_user_id': currentUser?.uid,
              'booked_by_user_email': currentUser?.email,
              'created_at': FieldValue.serverTimestamp(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Meeting successfully booked!')),
            );

            // Send email notifications (implement this function according to your needs)
            await _sendEmailNotification(availability);

            // Trigger a local notification
            await _showLocalNotification('Meeting Booked', 'Your meeting has been scheduled.');

            // Optionally, navigate back or update the UI as needed
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('This time has already been booked.')),
            );
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking meeting: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter meeting title and purpose.')),
      );
    }
  }

  Future<void> _sendEmailNotification(Map<String, dynamic> availability) async {
    // Implement your email sending logic here.
    // For example, you can use a backend service or Firebase Cloud Functions to send emails.
  }

  Future<void> _showLocalNotification(String title, String body) async {
    // Implement your local notification code here
    // For example, using flutter_local_notifications package
  }

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = Colors.lightBlueAccent;

    if (isLoading) {
      return Loading();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20), // Add vertical padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Schedule Meeting',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: buttonColor,
                  ),
                ),
                SizedBox(height: 20),
                if (availableDates.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No availability set by this user.',
                        style: TextStyle(fontSize: 16, color: Colors.redAccent),
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TableCalendar(
                          focusedDay: DateTime.now(),
                          firstDay: DateTime.now(),
                          lastDay: DateTime.utc(2030, 12, 31),
                          enabledDayPredicate: (date) {
                            return availableDates.any((availability) {
                              return DateFormat('yyyy-MM-dd')
                                      .format(availability['start_time']) ==
                                  DateFormat('yyyy-MM-dd').format(date);
                            });
                          },
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              selectedDate = selectedDay;
                              meetingTitle = '';
                              meetingPurpose = '';
                            });
                            _getAvailableTimesForSelectedDate(selectedDay);
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: buttonColor.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: buttonColor,
                              shape: BoxShape.circle,
                            ),
                            disabledTextStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      if (selectedDate != null && availableTimes.isNotEmpty)
                        Column(
                          children: [
                            Text(
                              'Available Times:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: buttonColor,
                              ),
                            ),
                            SizedBox(height: 10),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: availableTimes.length,
                              itemBuilder: (context, index) {
                                final time = availableTimes[index];
                                DateTime startTime = time['start_time'];
                                DateTime endTime = time['end_time'];
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      '${DateFormat.jm().format(startTime)} - ${DateFormat.jm().format(endTime)}',
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () {
                                        _bookMeeting(time['id'], time);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: buttonColor,
                                      ),
                                      child: Text('Book'),
                                    ),
                                  ),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  TextField(
                                    decoration:
                                        InputDecoration(labelText: 'Meeting Title'),
                                    onChanged: (value) {
                                      setState(() {
                                        meetingTitle = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 10),
                                  TextField(
                                    decoration: InputDecoration(
                                        labelText: 'Meeting Description'),
                                    onChanged: (value) {
                                      setState(() {
                                        meetingPurpose = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              selectedDate == null
                                  ? 'Select a date to see available times.'
                                  : 'No available times on this date.',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.redAccent),
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
