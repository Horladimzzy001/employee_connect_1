import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();

  User? currentUser;
  String name = '';
  String surname = '';
  String email = '';
  String username = '';
  String phone = '';
  String? profileImageUrl;
  File? _image;

  @override
  void initState() {
    super.initState();
    _getUserDetails();
  }

  // Fetch user details from Firestore
  Future<void> _getUserDetails() async {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(currentUser!.uid).get();
      setState(() {
        name = userDoc['name'];
        surname = userDoc['surname'];
        email = currentUser!.email!;
        phone = userDoc['phone'] ?? '';
        username = userDoc['username'] ?? '';
        profileImageUrl = userDoc['profileImageUrl'];
      });
    }
  }

  // Image picker to allow user to change profile picture
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  // Upload image to Firebase Storage and update Firestore
  Future<void> _uploadImage() async {
    if (_image != null) {
      try {
        String filePath = 'profile_images/${currentUser!.uid}.png';
        UploadTask uploadTask = _storage.ref().child(filePath).putFile(_image!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update user's profile image URL in Firestore
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'profileImageUrl': downloadUrl,
        });

        // Update state with new profile image URL
        setState(() {
          profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile picture updated!')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
    }
  }

  // Save updated profile details to Firestore
  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'username': username,
        'phone': phone,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Picture
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : (profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : AssetImage('assets/images/default_profile.png')) as ImageProvider,
                  child: _image == null && profileImageUrl == null
                      ? Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Upload Image'),
                ),
              ),
              SizedBox(height: 20),

              // Name (read-only)
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(labelText: 'Name'),
                readOnly: true,
              ),
              SizedBox(height: 10),

              // Surname (read-only)
              TextFormField(
                initialValue: surname,
                decoration: InputDecoration(labelText: 'Surname'),
                readOnly: true,
              ),
              SizedBox(height: 10),

              // Email (read-only)
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(labelText: 'Email'),
                readOnly: true,
              ),
              SizedBox(height: 10),

              // Username (editable)
              TextFormField(
                initialValue: username,
                decoration: InputDecoration(labelText: 'Username'),
                validator: (val) => val!.isEmpty ? 'Enter your username' : null,
                onChanged: (val) => setState(() => username = val),
              ),
              SizedBox(height: 10),

              // Phone Number (editable)
              TextFormField(
                initialValue: phone,
                decoration: InputDecoration(labelText: 'Phone Number'),
                onChanged: (val) => setState(() => phone = val),
              ),
              SizedBox(height: 20),

              // Save Profile button
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
