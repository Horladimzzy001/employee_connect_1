import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phidrillsim_connect/loading.dart';
import 'package:phidrillsim_connect/screens/auth/login_screen.dart';
import 'package:phidrillsim_connect/screens/home.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers for form fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController(); // Added controller for confirm password
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController accessCodeController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController(); // Added controller for company name
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String _status = 'Employee';
  String _department = 'Software Development';
  final List<String> departments = [
    "Top Management",
    "Software Development",
    "Technical Development",
    "Business Development",
    "Administration",
    "Legal Development",
    "Social Media",
  ];

  // Email validator
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty || !value.contains('@')) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Access code validator
  String? _validateAccessCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an access code';
    }
    return null;
  }

  // Password validator
  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Confirm password validator
  String? _validateConfirmPassword(String? value) {
    if (value == null || value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _tryRegister() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() => _isLoading = true);

  // Show the loading screen when the sign-up process starts
  Navigator.push(
      context, MaterialPageRoute(builder: (context) => Loading()));

  try {
    // Fetch the access code from Firestore to verify if it's valid
    DocumentSnapshot accessCodeDoc = await FirebaseFirestore.instance
        .collection('access_code')
        .doc(accessCodeController.text.trim())
        .get();

    if (!accessCodeDoc.exists) {
      // If the access code does not exist, show an error and stop the sign-up process
      Fluttertoast.showToast(msg: 'Invalid Access Code. Please try again.');
      Navigator.pop(context); // Close the loading screen
      setState(() => _isLoading = false);
      return;
    }

    // Get the role from the access code document
    String role = accessCodeDoc['role'] ?? 'General';

    // Create user with email and password
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    // Get the current user
    User? user = userCredential.user;

    // Send email verification
    if (user != null) {
      await user.sendEmailVerification();
    }

    // Capitalize the first letter of the first name and surname
    String firstName = nameController.text.trim();
    firstName = firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();

    String surname = surnameController.text.trim();
    surname = surname[0].toUpperCase() + surname.substring(1).toLowerCase();

    // Prepare user data to save to Firestore
    print('Status before saving: $_status');
    print('Company Name: ${companyNameController.text}');

    Map<String, dynamic> userData = {
      'firstName': firstName,
      'surname': surname,
      'email': emailController.text.trim(),
      'status': _status,
      'role': role,
    };

    if (_status.trim() == 'Employee') {
      userData['department'] = _department;
      userData['employeeStatus'] = 'Full Employee';
    } else {
      userData['department'] = 'N/A';
    }

    if (_status.trim() == 'Client') {
      userData['companyName'] = companyNameController.text.trim();
    }

    // Save user details to Firestore
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set(userData);
    } catch (e) {
      print('Error saving to Firestore: $e');
      Fluttertoast.showToast(msg: 'Error saving user data. Please try again.');
    }

    Fluttertoast.showToast(
        msg: 'Verification email sent! Please verify your email.');

    // Close the loading screen before navigating away
    Navigator.pop(context);

    // Navigate to the home screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  } catch (e) {
    Fluttertoast.showToast(msg: e.toString());
    Navigator.pop(context); // Close the loading screen if there is an error
  } finally {
    setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(height: 60),
                // Add a logo or header
                Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // First Name Field
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Surname Field
                      TextFormField(
                        controller: surnameController,
                        decoration: InputDecoration(
                          labelText: 'Surname',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Email Field
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: _validateEmail,
                      ),
                      SizedBox(height: 16),
                      // Password Field
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.lock),
                        ),
                        validator: _validatePassword,
                      ),
                      SizedBox(height: 16),
                      // Confirm Password Field
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: _validateConfirmPassword,
                      ),
                      SizedBox(height: 16),
                      // Status Dropdown
                      DropdownButtonFormField(
                        value: _status,
                        items: ['Employee', 'Client', 'Visitor']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _status = newValue!;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Department Dropdown (if Employee)
                      if (_status == 'Employee')
                        Column(
                          children: [
                            DropdownButtonFormField(
                              value: _department,
                              items: departments.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _department = newValue!;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Department',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      // Company Name Field (if Client)
                      if (_status == 'Client')
                        Column(
                          children: [
                            TextFormField(
                              controller: companyNameController,
                              decoration: InputDecoration(
                                labelText: 'Company Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: Icon(Icons.business),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your company name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      // Access Code Field
                      TextFormField(
                        controller: accessCodeController,
                        decoration: InputDecoration(
                          labelText: 'Access Code',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        validator: _validateAccessCode, // Apply the validation here
                      ),
                      SizedBox(height: 24),
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _tryRegister,
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Sign Up',
                                  style: TextStyle(fontSize: 18),
                                ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            backgroundColor: Colors.blueAccent,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Already have an account?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Already have an account?'),
                          TextButton(
                            onPressed: () {
                              // Navigate to login screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => LoginScreen()),
                              );
                            },
                            child: Text('Log in'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
