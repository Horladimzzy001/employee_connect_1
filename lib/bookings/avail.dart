import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phidrillsim_connect/loading.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class AvailabilityScreen extends StatefulWidget {
  @override
  _AvailabilityScreenState createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  User? currentUser;
  List<Map<String, dynamic>> userAvailability = [];
  List<DateTime> selectedDates = [];
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  String? selectedTimeZone;
  List<String> timeZones = tz.timeZoneDatabase.locations.keys.toList();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _fetchCurrentUser();
    _fetchAvailability();
    _loadTimeZone();
  }

  void _fetchCurrentUser() async {
    currentUser = FirebaseAuth.instance.currentUser;
    setState(() {});
  }

  void _loadTimeZone() {
    setState(() {
      selectedTimeZone = tz.local.name;
    });
  }

  Future<void> _fetchAvailability() async {
    try {
      if (currentUser != null) {
        final userId = currentUser!.uid;
        final userAvailabilityRef = FirebaseFirestore.instance
            .collection('availability')
            .doc(userId)
            .collection('dates');

        QuerySnapshot snapshot = await userAvailabilityRef.get();
        setState(() {
          userAvailability = snapshot.docs.map((doc) {
            return {
              'id': doc.id,
              'start_time': (doc['start_time'] as Timestamp).toDate(),
              'end_time': (doc['end_time'] as Timestamp).toDate(),
              'time_zone': doc['time_zone'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      // Handle exceptions
      print('Error fetching availability: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _uploadAvailability() async {
    if (currentUser != null &&
        selectedStartTime != null &&
        selectedEndTime != null &&
        selectedDates.isNotEmpty &&
        selectedTimeZone != null) {
      final userId = currentUser!.uid;
      final userAvailabilityRef = FirebaseFirestore.instance
          .collection('availability')
          .doc(userId)
          .collection('dates');

      for (DateTime date in selectedDates) {
        final startDateTime = DateTime(
            date.year, date.month, date.day, selectedStartTime!.hour, selectedStartTime!.minute);
        final endDateTime = DateTime(
            date.year, date.month, date.day, selectedEndTime!.hour, selectedEndTime!.minute);

        await userAvailabilityRef.add({
          'start_time': startDateTime,
          'end_time': endDateTime,
          'created_at': FieldValue.serverTimestamp(),
          'time_zone': selectedTimeZone,
          'isBooked': false,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Availability uploaded successfully!')),
      );
      _fetchAvailability(); // Refresh the availability list after uploading

      // Trigger a local notification to inform the user that availability has been set
      _showLocalNotification('Availability Set', 'Your availability has been updated.');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select time, date, and timezone.')),
      );
    }
  }

  Future<void> _deleteAvailability(String docId) async {
    if (currentUser != null) {
      final userId = currentUser!.uid;
      final userAvailabilityRef = FirebaseFirestore.instance
          .collection('availability')
          .doc(userId)
          .collection('dates');

      await userAvailabilityRef.doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Availability deleted successfully!')),
      );
      _fetchAvailability(); // Refresh the availability list after deletion
    }
  }

  Future<void> _showLocalNotification(String title, String body) async {
    // Implement your local notification code here
    // For example, using flutter_local_notifications package
  }

  Future<void> _selectTimeRange(BuildContext context) async {
    final TimeOfDay? pickedStartTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedStartTime != null) {
      final TimeOfDay? pickedEndTime = await showTimePicker(
        context: context,
        initialTime: pickedStartTime,
      );
      if (pickedEndTime != null) {
        setState(() {
          selectedStartTime = pickedStartTime;
          selectedEndTime = pickedEndTime;
        });
      }
    }
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Set Your Availability',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: buttonColor),
                ),
                SizedBox(height: 20),
                // Timezone dropdown
                DropdownButton<String>(
                  value: selectedTimeZone,
                  hint: Text("Select Time Zone"),
                  items: timeZones.map((String timeZone) {
                    return DropdownMenuItem<String>(
                      value: timeZone,
                      child: Text(timeZone),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedTimeZone = newValue;
                    });
                  },
                ),
                SizedBox(height: 20),
                TableCalendar(
                  focusedDay: DateTime.now(),
                  firstDay: DateTime.utc(2022, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  selectedDayPredicate: (day) {
                    return selectedDates.any((selectedDay) => isSameDay(selectedDay, day));
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      if (selectedDates.any((date) => isSameDay(date, selectedDay))) {
                        selectedDates.removeWhere((date) => isSameDay(date, selectedDay));
                      } else {
                        selectedDates.add(selectedDay);
                      }
                    });
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
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _selectTimeRange(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text(
                    selectedStartTime == null || selectedEndTime == null
                        ? 'Select Time Range'
                        : 'Selected Time: ${selectedStartTime?.format(context)} - ${selectedEndTime?.format(context)}',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: selectedDates.isEmpty ||
                          selectedTimeZone == null ||
                          selectedStartTime == null ||
                          selectedEndTime == null
                      ? null
                      : _uploadAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (selectedDates.isEmpty ||
                            selectedTimeZone == null ||
                            selectedStartTime == null ||
                            selectedEndTime == null)
                        ? Colors.grey
                        : buttonColor,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text(
                    'Submit Availability',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 30),
                Divider(),
                SizedBox(height: 10),
                if (userAvailability.isNotEmpty) ...[
                  Text(
                    'Your Available Times:',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: buttonColor),
                  ),
                  SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: userAvailability.length,
                    itemBuilder: (context, index) {
                      final availability = userAvailability[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            'From: ${DateFormat.yMMMd().add_jm().format(availability['start_time'])}\nTo: ${DateFormat.yMMMd().add_jm().format(availability['end_time'])}\nTime Zone: ${availability['time_zone']}',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAvailability(availability['id']),
                          ),
                        ),
                      );
                    },
                  ),
                ] else
                  Text(
                    'No available time set.',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
