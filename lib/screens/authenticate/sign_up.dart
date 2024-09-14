import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phidrillsim_connect/screens/homescreen/home.dart';
import 'package:phidrillsim_connect/shared/loading.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  bool loading = false;

  String name = '';
  String surname = '';
  String email = '';
  String department = 'Software Department';
  String accessCode = '';
  String password = '';
  String confirmPassword = '';

  final List<String> departments = [
    "Legal Department",
    "Technical Department",
    "Admin Department",
    "Software Department",
  ];

  Future<void> _registerUser() async {
    try {
      setState(() => loading = true);

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      if (userCredential == null) {
        setState(() {
          loading = false;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please supply a valid email!'),
          ));
        });
        return;
      }

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name,
        'surname': surname,
        'email': email,
        'department': department,
        'role': accessCode == '111admin' ? 'admin' : 'user',
      });

      await userCredential.user?.sendEmailVerification();

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Verification email sent to $name! Please check your email.'),
      ));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Home(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);

      String message;
      if (e.code == 'email-already-in-use') {
        message = 'This email is already in use. Please use another email.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak. Please use a stronger password.';
      } else {
        message = 'Registration failed. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
      ));
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading() // Replacing CircularProgressIndicator with the Loading widget
        : Scaffold(
            appBar: AppBar(
  title: const Text('Sign Up'),
  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue, Colors.purple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
  centerTitle: true, // Center the title
  elevation: 0, // Optional: Remove the shadow for a flatter look
),

            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            // First Name
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (val) => val!.isEmpty ? 'Enter your first name' : null,
                              onChanged: (val) => setState(() => name = val),
                            ),
                            const SizedBox(height: 15),

                            // Last Name
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (val) => val!.isEmpty ? 'Enter your surname' : null,
                              onChanged: (val) => setState(() => surname = val),
                            ),
                            const SizedBox(height: 15),

                            // Email
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                              onChanged: (val) => setState(() => email = val),
                            ),
                            const SizedBox(height: 15),

                            // Password
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              obscureText: true,
                              validator: (val) => val!.length < 6 ? 'Password must be 6+ characters' : null,
                              onChanged: (val) => setState(() => password = val),
                            ),
                            const SizedBox(height: 15),

                            // Confirm Password
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              obscureText: true,
                              validator: (val) => val != password ? 'Passwords do not match' : null,
                              onChanged: (val) => setState(() => confirmPassword = val),
                            ),
                            const SizedBox(height: 15),

                            // Department Dropdown
                            DropdownButtonFormField(
                              value: department,
                              items: departments.map((dept) {
                                return DropdownMenuItem(
                                  value: dept,
                                  child: Text(dept),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => department = val.toString()),
                              decoration: InputDecoration(
                                labelText: 'Department',
                                prefixIcon: Icon(Icons.business),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Access Code
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Access Code',
                                prefixIcon: Icon(Icons.lock_open),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              validator: (val) => val!.isEmpty ? 'Enter access code' : null,
                              onChanged: (val) => setState(() => accessCode = val),
                            ),
                            const SizedBox(height: 20),

                            // Sign Up Button
                            ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(40),
    ),
    backgroundColor: Theme.of(context).primaryColor, // Button background color
    foregroundColor: Colors.white, // Ensure text is white or another contrasting color
  ),
  child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
  onPressed: () {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);
      _registerUser();
    }
  },
),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
