import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class AccessCodeManagementPage extends StatefulWidget {
  @override
  _AccessCodeManagementPageState createState() =>
      _AccessCodeManagementPageState();
}

class _AccessCodeManagementPageState extends State<AccessCodeManagementPage> {
  final _firestore = FirebaseFirestore.instance;
  bool _codesVisible = false; // Controls whether access codes are visible

  // Function to generate a new access code
  String _generateAccessCode() {
    // Generates a random 6-digit number
    var random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Function to reset an access code
  Future<void> _resetAccessCode(String oldCode, Map<String, dynamic> data) async {
    TextEditingController codeController = TextEditingController();

    // Show dialog to enter a new access code or generate one
    String? newCode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Access Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter a new access code or generate one.'),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'New Access Code',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                String generatedCode = _generateAccessCode();
                codeController.text = generatedCode;
              },
              child: Text('Generate Code'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (codeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Please enter or generate a new access code.')),
                );
                return;
              }
              Navigator.pop(context, codeController.text.trim());
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (newCode != null && newCode.isNotEmpty) {
      // Delete the old access code document
      await _firestore.collection('access_code').doc(oldCode).delete();

      // Add the new access code document with the same data
      await _firestore.collection('access_code').doc(newCode).set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Access code "$oldCode" has been reset to "$newCode".')),
      );
    }
  }

  // Function to toggle the visibility of access codes
  void _toggleCodesVisibility() {
    setState(() {
      _codesVisible = !_codesVisible;
    });
  }

  // Function to add a new access code
  Future<void> _addAccessCode() async {
    TextEditingController codeController = TextEditingController();
    TextEditingController roleController = TextEditingController();
    TextEditingController departmentController = TextEditingController();

    // Show dialog to input new access code details
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Access Code'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Access Code',
                ),
              ),
              TextField(
                controller: roleController,
                decoration: InputDecoration(
                  labelText: 'Role',
                ),
              ),
              TextField(
                controller: departmentController,
                decoration: InputDecoration(
                  labelText: 'Department',
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  String generatedCode = _generateAccessCode();
                  codeController.text = generatedCode;
                },
                child: Text('Generate Code'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (codeController.text.trim().isEmpty ||
                  roleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Access Code and Role are required.')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      String newCode = codeController.text.trim();
      Map<String, dynamic> data = {
        'role': roleController.text.trim(),
        'department': departmentController.text.trim(),
      };

      // Add the new access code document
      await _firestore.collection('access_code').doc(newCode).set(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access code "$newCode" has been added.')),
      );
    }
  }

  // Function to delete an access code
  Future<void> _deleteAccessCode(String code) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Access Code'),
        content:
            Text('Are you sure you want to delete the access code "$code"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Cancel
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Confirm
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Delete the access code document
      await _firestore.collection('access_code').doc(code).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Access code "$code" has been deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Access Codes'),
        actions: [
          IconButton(
            icon: Icon(_codesVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: _toggleCodesVisibility,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addAccessCode,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('access_code').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No access codes found.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              String code = doc.id;
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(_codesVisible
                    ? 'Access Code: $code'
                    : 'Access Code: ******'),
                subtitle: Text(
                    'Role: ${data['role']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () => _resetAccessCode(code, data),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteAccessCode(code),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
