import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsPage extends StatefulWidget {
  @override
  _PrivacySettingsPageState createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _showEmail = false;
  bool _showPhoneNumber = false;
  bool _showHobbies = false;
  bool _concealAll = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
          setState(() {
            _showEmail = data?['showEmail'] ?? false;
            _showPhoneNumber = data?['showPhoneNumber'] ?? false;
            _showHobbies = data?['showHobbies'] ?? false;
            _concealAll = data?['concealAll'] ?? false;
          });
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error loading privacy settings');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Privacy Settings"),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select what you want to display to others:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  SwitchListTile(
                    activeColor: Colors.blue,
                    title: Text("Show Email"),
                    value: _concealAll ? false : _showEmail,
                    onChanged: (value) {
                      if (!_concealAll) {
                        setState(() {
                          _showEmail = value;
                        });
                      }
                    },
                  ),
                  SwitchListTile(
                    activeColor: Colors.blue,
                    title: Text("Show Phone Number"),
                    value: _concealAll ? false : _showPhoneNumber,
                    onChanged: (value) {
                      if (!_concealAll) {
                        setState(() {
                          _showPhoneNumber = value;
                        });
                      }
                    },
                  ),
                  SwitchListTile(
                    activeColor: Colors.blue,
                    title: Text("Show Hobbies"),
                    value: _concealAll ? false : _showHobbies,
                    onChanged: (value) {
                      if (!_concealAll) {
                        setState(() {
                          _showHobbies = value;
                        });
                      }
                    },
                  ),
                  Divider(height: 40),
                  SwitchListTile(
                    activeColor: Colors.blue,
                    title: Text(
                        "Conceal All Information (only show Name & Surname)"),
                    value: _concealAll,
                    onChanged: (value) {
                      setState(() {
                        _concealAll = value;
                        if (_concealAll) {
                          _showEmail = false;
                          _showPhoneNumber = false;
                          _showHobbies = false;
                        }
                      });
                    },
                  ),
                  Spacer(),
                  Center(
                    child: ElevatedButton(
                      onPressed: _savePrivacySettings,
                      child: Text('Save Privacy Settings'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        textStyle: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _savePrivacySettings() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'showEmail': _showEmail,
        'showPhoneNumber': _showPhoneNumber,
        'showHobbies': _showHobbies,
        'concealAll': _concealAll,
      });

      // Clear cache after updating
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('cachedUsers');

      Fluttertoast.showToast(msg: 'Privacy settings updated!');
      Navigator.pop(context);
    }
  }
}
