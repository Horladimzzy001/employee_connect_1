import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  String? _userRole;
  bool _isLoading = false;

  User? get user => _user;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Set the user and notify listeners
  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  // Fetch user details from Firestore after login or registration
  Future<void> fetchUserDetails() async {
    if (_user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          // Update the local state with user details and role
          _userRole = userData['role'] ?? 'Unknown'; // Safely fetch the role
          notifyListeners(); // Notify that user details and role have been fetched
        }
      } catch (e) {
        print("Error fetching user details: $e");
      }
    }
  }

  // Method to manually get the user role if needed elsewhere
  Future<void> getUserRole(String uid) async {
    try {
      var userDoc = await _firestore.collection('users').doc(uid).get();
      _userRole = userDoc['role'];
      notifyListeners();
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  // Update user profile details and save to Firestore
  Future<void> updateUserProfile(Map<String, dynamic> updatedData) async {
    if (_user != null) {
      try {
        _isLoading = true;
        notifyListeners();

        // Update user details in Firestore
        await _firestore.collection('users').doc(_user!.uid).update(updatedData);

        // Optionally, update the local user state with new details
        await fetchUserDetails();
      } catch (e) {
        print("Error updating user profile: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Sign out method
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      _user = null;
      _userRole = null;
      notifyListeners();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // Reset password method
  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error resetting password: $e");
    }
  }
}
