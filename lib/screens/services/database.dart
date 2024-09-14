import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Reference to the users collection
  final CollectionReference userDetails = FirebaseFirestore.instance.collection('users');

  // Update user data (including profile picture)
  Future<void> updateUserData(String phone, String name, String profileImageUrl) async {
    return await userDetails.doc(uid).set({
      "Phone Number": phone,
      "Name": name,
      "profileImageUrl": profileImageUrl,
    });
  }
}
