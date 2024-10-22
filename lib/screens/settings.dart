import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:phidrillsim_connect/loading.dart';
import 'package:phidrillsim_connect/screens/privacy.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  User? user;
  String? imageUrl;
  File? _imageFile;

  TextEditingController homeAddressController = TextEditingController();
  TextEditingController telephoneController = TextEditingController();
  TextEditingController hobbiesController = TextEditingController();
  TextEditingController favouriteQuoteController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      user = _auth.currentUser;
      if (user != null) {
        // Fetch data from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user!.uid).get();
        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>;
            homeAddressController.text = userData?['homeAddress'] ?? '';
            telephoneController.text = userData?['telephone'] ?? '';
            hobbiesController.text = userData?['hobbies'] ?? '';
            favouriteQuoteController.text = userData?['favouriteQuote'] ?? '';
            imageUrl = userData?['profilePictureURL'] ?? '';
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Error fetching user data: $e');
    }
  }

  Future<void> updateUserData() async {
    if (user != null) {
      await _firestore.collection('users').doc(user!.uid).update({
        'homeAddress': homeAddressController.text,
        'telephone': telephoneController.text,
        'hobbies': hobbiesController.text,
        'favouriteQuote': favouriteQuoteController.text,
      });
      // Clear input fields after update
      homeAddressController.clear();
      telephoneController.clear();
      hobbiesController.clear();
      favouriteQuoteController.clear();
      Fluttertoast.showToast(msg: 'User data updated successfully!');
    }
  }

  Future<void> resetPassword() async {
    if (user != null && user!.email != null) {
      await _auth.sendPasswordResetEmail(email: user!.email!);
      Fluttertoast.showToast(msg: 'Password reset email sent.');
    }
  }

  void _showResetPasswordConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Password Reset'),
          content: Text('Are you sure you want to reset your password?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                resetPassword();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> uploadPicture(ImageSource source) async {
    setState(() {
      _isLoading = true; // Show loading while uploading
    });

    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);

        String fileName = 'profile_${user!.uid}.png';
        Reference firebaseStorageRef =
            FirebaseStorage.instance.ref().child('profile_pictures/$fileName');

        UploadTask uploadTask = firebaseStorageRef.putFile(_imageFile!);
        TaskSnapshot taskSnapshot = await uploadTask;

        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        imageUrl = downloadUrl;

        await _firestore.collection('users').doc(user!.uid).update({
          'profilePictureURL': downloadUrl,
        });

        Fluttertoast.showToast(msg: 'Profile picture updated successfully!');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error uploading picture: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading once done
      });
    }
  }

  void _showPictureOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Colors.white,
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.blue),
              title: Text('Take a Picture'),
              onTap: () {
                Navigator.pop(context);
                uploadPicture(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                uploadPicture(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Loading();
    }

    // Determine if the screen is large
    bool isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLargeScreen ? _buildLargeScreenLayout() : _buildSmallScreenLayout(),
      ),
    );
  }

  Widget _buildSmallScreenLayout() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          SizedBox(height: 20),
          _buildProfileImage(),
          SizedBox(height: 16),
          _buildUploadPictureButton(),
          SizedBox(height: 24),
          _buildUserInfo(),
          SizedBox(height: 24),
          _buildTextFields(),
          SizedBox(height: 24),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _buildProfileImage(),
                    SizedBox(height: 16),
                    _buildUploadPictureButton(),
                  ],
                ),
              ),
              SizedBox(width: 40),
              // Right Column
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfo(),
                    SizedBox(height: 24),
                    _buildTextFields(),
                    SizedBox(height: 24),
                    _buildButtons(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    // Determine screen size
    bool isLargeScreen = MediaQuery.of(context).size.width > 800;
    double avatarRadius = isLargeScreen ? 80 : 60;
    double iconSize = isLargeScreen ? 80 : 60;

    return GestureDetector(
      onTap: () {
        if (imageUrl != null && imageUrl!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImage(imageUrl: imageUrl!),
            ),
          );
        }
      },
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundImage:
            imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
        backgroundColor: Colors.blue[100],
        child: imageUrl == null || imageUrl!.isEmpty
            ? Icon(Icons.person, size: iconSize, color: Colors.blue)
            : null,
      ),
    );
  }

  Widget _buildUploadPictureButton() {
    return TextButton.icon(
      onPressed: _showPictureOptions,
      icon: Icon(Icons.camera_alt, color: Colors.blue),
      label: Text(
        'Upload Picture',
        style: TextStyle(color: Colors.blue),
      ),
    );
  }

  Widget _buildUserInfo() {
    bool isLargeScreen = MediaQuery.of(context).size.width > 800;
    double nameFontSize = isLargeScreen ? 32 : 28;
    double infoFontSize = isLargeScreen ? 18 : 16;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${userData?['firstName'] ?? ''} ${userData?['surname'] ?? ''}',
          style: TextStyle(
              fontSize: nameFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.blue),
        ),
        SizedBox(height: 8),
        Text(
          '${userData?['email'] ?? ''}',
          style: TextStyle(fontSize: infoFontSize, color: Colors.grey[700]),
        ),
        SizedBox(height: 8),
        Text(
          'Department: ${userData?['department'] ?? ''}',
          style: TextStyle(fontSize: infoFontSize, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        _buildTextField(
          controller: homeAddressController,
          labelText: 'Home Address',
          icon: Icons.home,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: telephoneController,
          labelText: 'Telephone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: hobbiesController,
          labelText: 'Hobbies',
          icon: Icons.favorite,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: favouriteQuoteController,
          labelText: 'Favourite Quote',
          icon: Icons.format_quote,
        ),
      ],
    );
  }

  Widget _buildButtons() {
    bool isLargeScreen = MediaQuery.of(context).size.width > 800;
    return Column(
      children: [
        SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 600 : double.infinity,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacySettingsPage()),
                );
              },
              child: Text(
                'Privacy Settings',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 600 : double.infinity,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: updateUserData,
              child: Text(
                'Update Info',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isLargeScreen ? 600 : double.infinity,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showResetPasswordConfirmation,
              child: Text(
                'Reset Password',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    bool isLargeScreen = MediaQuery.of(context).size.width > 800;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isLargeScreen ? 600 : double.infinity,
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          filled: true,
          fillColor: Colors.grey[100],
          prefixIcon: Icon(icon, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
