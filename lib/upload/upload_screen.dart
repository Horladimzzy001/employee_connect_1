import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For MissingPluginException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phidrillsim_connect/loading.dart'; // Assuming you have this loading widget
import 'dart:io';




import 'package:path_provider/path_provider.dart'; // For getting local directory
import 'package:path/path.dart' as path;


class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  User? user;
  bool _isLoading = false;
  String _currentFolder = 'uploads'; // Default to uploads folder
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Default department folders
  final List<String> defaultDepartments = [
    "Top Management",
    "Software Development",
    "Technical Development",
    "Business Development",
    "Administration",
    "Legal Development",
    "Social Media"
  ];

  String _firstName = '';
  String _surname = '';

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
    _initializeFolders(); // Initialize default department folders on load
  }

  // Method to fetch user's first name and surname
  Future<void> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await firestore.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _firstName = userDoc['firstName'] ?? '';
          _surname = userDoc['surname'] ?? '';
        });
      }
    }
  }

  // Method to initialize default department folders
  Future<void> _initializeFolders() async {
    setState(() => _isLoading = true);

    try {
      // Create default department folders if they don't exist
      for (String department in defaultDepartments) {
        final ref = storage.ref('uploads/$department/');
        final result = await ref.listAll();

        // Create folder only if it doesn't already exist
        if (result.items.isEmpty && result.prefixes.isEmpty) {
          await ref.child('.keep').putString(''); // Create an empty file to keep the folder
        }
      }
    } catch (e) {
      _showErrorDialog("Error initializing folders: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Method to get the user's uploads and display folders and files
  Future<List<Map<String, dynamic>>> _getFolderContents(String path) async {
    try {
      final ListResult result = await storage.ref(path).listAll();
      List<Map<String, dynamic>> contents = [];

      // Folders
      for (var prefix in result.prefixes) {
        contents.add({"name": prefix.name, "type": "folder", "path": prefix.fullPath});
      }

      // Files
      for (var item in result.items) {
        // Exclude the '.keep' files
        if (item.name != '.keep') {
          contents.add({"name": item.name, "type": "file", "path": item.fullPath});
        }
      }

      // Handle empty folder case by checking if contents are empty
      if (contents.isEmpty) {
        contents.add({"name": "No items", "type": "empty", "path": ""});
      }

      return contents;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _showErrorDialog("You do not have permission to view this folder.");
        return []; // Return empty list if permission is denied
      } else {
        rethrow;
      }
    } on MissingPluginException {
      _showErrorDialog("You do not have permission.");
      return [];
    } catch (e) {
      _showErrorDialog("An error occurred: $e");
      return [];
    }
  }

  // Method to create a new folder
  Future<void> _createNewFolder(String folderName) async {
    setState(() => _isLoading = true);
    try {
      await storage.ref('$_currentFolder/$folderName/.keep').putString(''); // Create an empty file to keep the folder
      setState(() => _isLoading = false);
      _showInfoDialog("Folder created successfully!");
    } on FirebaseException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'permission-denied') {
        _showErrorDialog("You do not have permission to create a folder here.");
      } else {
        _showErrorDialog("Error creating folder: ${e.message}");
      }
    } on MissingPluginException {
      setState(() => _isLoading = false);
      _showErrorDialog("You do not have permission.");
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Error creating folder: $e");
    }
  }

  // Method to delete a folder and its contents
  Future<void> _deleteFolder(String folderPath, String folderName) async {
    // Check if folder is a default department folder
    if (defaultDepartments.contains(folderName) && _currentFolder == 'uploads') {
      _showErrorDialog("You cannot delete default department folders.");
      return;
    }

    bool confirmDelete = await _showConfirmationDialog(
        "Delete Folder",
        "Are you sure you want to delete this folder and all its contents?"
    );

    if (!confirmDelete) return;

    setState(() => _isLoading = true);
    try {
      await storage.ref(folderPath).listAll().then((result) async {
        for (var file in result.items) {
          await file.delete(); // Delete all files in the folder
        }
        for (var folder in result.prefixes) {
          await _deleteFolder(folder.fullPath, folder.name); // Recursively delete subfolders
        }
      });
      await storage.ref(folderPath).delete(); // Finally delete the folder itself
      setState(() => _isLoading = false);
      _showInfoDialog("Folder deleted successfully!");
    } on FirebaseException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'permission-denied') {
        _showErrorDialog("You do not have permission to delete this folder.");
      } else {
        _showErrorDialog("Error deleting folder: ${e.message}");
      }
    } on MissingPluginException {
      setState(() => _isLoading = false);
      _showErrorDialog("You do not have permission.");
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Error deleting folder: $e");
    }
  }

  // Method to show dialog for creating a new folder
  Future<void> _showCreateFolderDialog() async {
    TextEditingController folderNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create New Folder"),
        content: TextField(
          controller: folderNameController,
          decoration: InputDecoration(hintText: "Enter folder name"),
        ),
        actions: [
          TextButton(
            child: Text("Create"),
            onPressed: () {
              String folderName = folderNameController.text.trim();
              if (folderName.isNotEmpty) {
                Navigator.pop(context);
                _createNewFolder(folderName);
              } else {
                _showErrorDialog("Folder name cannot be empty.");
              }
            },
          ),
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Method to prompt user to assign the file or lock it
  Future<void> _promptFileAssignment(String fileName, String filePath) async {
    bool assignFile = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Assign File"),
        content: Text("Would you like to assign this file to someone?"),
        actions: [
          TextButton(
            child: Text("Yes"),
            onPressed: () => Navigator.pop(context, true),
          ),
          TextButton(
            child: Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );

    if (assignFile == true) {
      await _assignFileToUsers(fileName, filePath); // Proceed to assign the file to users
    } else {
      await _lockFileOption(fileName, filePath); // Lock the file if the user doesn't assign it
    }
  }

  // Method to assign file to users
  Future<void> _assignFileToUsers(String fileName, String filePath) async {
    // Fetch users from Firestore
    QuerySnapshot usersSnapshot = await firestore.collection('users').get();

    // List of users to assign
    List<String> assignedUsers = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Assign File to Users"),
            content: Container(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: usersSnapshot.docs.map((userDoc) {
                  return CheckboxListTile(
                    title: Text(
                        "${userDoc['firstName']} ${userDoc['surname']} (${userDoc['role'] ?? 'No Role'})"),
                    value: assignedUsers.contains(userDoc.id),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          assignedUsers.add(userDoc.id);
                        } else {
                          assignedUsers.remove(userDoc.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                child: Text("Assign"),
                onPressed: () async {
                  // Store file assignment data in Firestore
                  await firestore.collection('fileAssignments').add({
                    'fileName': fileName,
                    'filePath': filePath,
                    'uploadedBy': user!.uid,
                    'uploadedByName': '$_firstName $_surname',
                    'assignedTo': assignedUsers,
                    'locked': false,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  _showInfoDialog("File assigned successfully!");
                },
              ),
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Method to ask if the user wants to lock the file
  Future<void> _lockFileOption(String fileName, String filePath) async {
    bool lockFile = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Lock File"),
        content: Text("Would you like to lock this file with a password?"),
        actions: [
          TextButton(
            child: Text("Yes"),
            onPressed: () => Navigator.pop(context, true),
          ),
          TextButton(
            child: Text("No"),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );

    if (lockFile == true) {
      await _setFileLockPassword(fileName, filePath);
    } else {
      // If not locking the file and not assigning, save without assigned users
      await firestore.collection('fileAssignments').add({
        'fileName': fileName,
        'filePath': filePath,
        'uploadedBy': user!.uid,
        'uploadedByName': '$_firstName $_surname',
        'assignedTo': [],
        'locked': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showInfoDialog("File uploaded successfully!");
    }
  }

  // Method to lock the file with a password
  Future<void> _setFileLockPassword(String fileName, String filePath) async {
    TextEditingController passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Lock Password"),
        content: TextField(
          controller: passwordController,
          decoration: InputDecoration(hintText: "Enter password"),
          obscureText: true,
        ),
        actions: [
          TextButton(
            child: Text("Lock"),
            onPressed: () async {
              if (passwordController.text.isNotEmpty) {
                // Store file lock information in Firestore
                await firestore.collection('fileAssignments').add({
                  'fileName': fileName,
                  'filePath': filePath,
                  'uploadedBy': user!.uid,
                  'uploadedByName': '$_firstName $_surname',
                  'assignedTo': [],
                  'locked': true,
                  'lockPassword': passwordController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                _showInfoDialog("File locked with password!");
              } else {
                _showErrorDialog("Password cannot be empty.");
              }
            },
          ),
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Method to upload a file from local storage
  Future<void> _uploadFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() => _isLoading = true);

      try {
        // Upload the file
        await storage
            .ref('$_currentFolder/${result.files.single.name}')
            .putFile(file, SettableMetadata(customMetadata: {
          'uploadedBy': user!.uid,
        }));

        setState(() => _isLoading = false);

        // Prompt to assign the file to users
        _promptFileAssignment(
            result.files.single.name, '$_currentFolder/${result.files.single.name}');
      } on FirebaseException catch (e) {
        setState(() => _isLoading = false);
        if (e.code == 'permission-denied') {
          _showErrorDialog("You do not have permission to upload files here.");
        } else {
          _showErrorDialog("File upload failed: ${e.message}");
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog("File upload failed: $e");
      }
    }
  } on MissingPluginException {
    _showErrorDialog("You do not have permission.");
  } catch (e) {
    _showErrorDialog("An error occurred: $e");
  }
}


  // Method to show error dialogs
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Method to show info dialogs
  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Information"),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () {
              Navigator.pop(context);
              setState(() {}); // Refresh the UI
            },
          ),
        ],
      ),
    );
  }

  // Method to show confirmation dialogs
  Future<bool> _showConfirmationDialog(String title, String message) async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("Yes"),
            onPressed: () {
              confirmed = true;
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: Text("No"),
            onPressed: () {
              confirmed = false;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
    return confirmed;
  }

  // Method to delete a file
  Future<void> _deleteFile(String filePath, String fileName) async {
    bool confirmDelete = await _showConfirmationDialog(
        "Delete File",
        "Are you sure you want to delete this file?"
    );

    if (!confirmDelete) return;

    setState(() => _isLoading = true);
    try {
      await storage.ref(filePath).delete();
      setState(() => _isLoading = false);
      _showInfoDialog("File deleted successfully!");
    } on FirebaseException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'permission-denied') {
        _showErrorDialog("You do not have permission to delete this file.");
      } else {
        _showErrorDialog("Error deleting file: ${e.message}");
      }
    } on MissingPluginException {
      setState(() => _isLoading = false);
      _showErrorDialog("You do not have permission.");
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog("Error deleting file: $e");
    }
  }

  // Method to download a file after checking permission
// Method to download a file after checking permission
// Method to download a file after checking permission
Future<void> _downloadFile(String filePath, String fileName) async {
  setState(() => _isLoading = true);  // Start showing the loader
  try {
    // Fetch file details from Firestore (ensure proper Firestore query)
    QuerySnapshot fileQuery = await firestore
        .collection('fileAssignments')
        .where('filePath', isEqualTo: filePath)
        .get();

    if (fileQuery.docs.isEmpty) {
      _showErrorDialog("You do not have permission to download this file.");
      setState(() => _isLoading = false);  // Stop showing the loader
      return;
    }

    DocumentSnapshot fileDoc = fileQuery.docs.first;

    // Get the uploader's user ID and file lock status
    String uploadedBy = fileDoc['uploadedBy'];
    bool isLocked = fileDoc['locked'] ?? false;

    // Fetch uploader's details
    DocumentSnapshot uploaderDoc =
        await firestore.collection('users').doc(uploadedBy).get();
    String uploaderName =
        "${uploaderDoc['firstName']} ${uploaderDoc['surname']}";

    // Fetch current user's role
    DocumentSnapshot currentUserDoc =
        await firestore.collection('users').doc(user!.uid).get();
    String role = currentUserDoc['role'] ?? '';

    // Check if the user has permission to download the file
    List<dynamic> assignedTo = fileDoc['assignedTo'] ?? [];
    bool canDownload = false;

    if (fileDoc.exists &&
        (uploadedBy == user!.uid ||
            assignedTo.contains(user!.uid) ||
            role == 'Manager' ||
            role == 'Supervisors')) {
      canDownload = true;
    }

    if (isLocked && !canDownload) {
      // If the file is locked and the user doesn't have permission, prompt for password
      await _promptForPassword(fileDoc, filePath, fileName);
    } else if (canDownload || !isLocked) {
      // User has permission to download the file or file is not locked
      await _download(filePath, fileName);  // Calls the updated download method
    } else {
      // User does not have permission, show AlertDialog with uploader's name
      _showErrorDialog(
          'You do not have permission to view this file. Please contact your supervisor or $uploaderName who uploaded it.');
    }
  } catch (e) {
    // Handle any errors
    _showErrorDialog('An error occurred: $e');
  } finally {
    setState(() => _isLoading = false);  // Stop showing the loader
  }
}




  // Method to prompt user for password if the file is locked
  Future<void> _promptForPassword(DocumentSnapshot fileDoc, String filePath, String fileName) async {
    TextEditingController passwordController = TextEditingController();

    bool correctPassword = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("File Locked"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("This file is locked. Please enter the password to download."),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(hintText: "Enter password"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Submit"),
            onPressed: () {
              if (passwordController.text == fileDoc['lockPassword']) {
                correctPassword = true;
                Navigator.pop(context);
              } else {
                _showErrorDialog("Incorrect password.");
              }
            },
          ),
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              correctPassword = false;
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );

    if (correctPassword) {
      _download(filePath, fileName); // Proceed with download if password is correct
    }
  }

  // Method to download the file (actual logic to save file)
// Method to download the file (save it to Downloads folder)
Future<void> _download(String filePath, String fileName) async {
  try {
    final Reference ref = storage.ref(filePath);
    final String downloadURL = await ref.getDownloadURL();

    // Get the public Downloads directory path (Scoped storage in Android 10+)
    Directory? downloadsDir = Directory('/storage/emulated/0/Download');
    String savePath = path.join(downloadsDir.path, fileName);

    // Download the file using an HTTP client
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse(downloadURL));
    final response = await request.close();

    // Save the file in the Downloads folder
    final file = File(savePath);
    await response.pipe(file.openWrite());

    _showInfoDialog("File downloaded successfully to $savePath");
  } catch (e) {
    _showErrorDialog("Error downloading file: $e");
  }
}



  // Method to display folders and files in a grid view
  Widget _buildFolderGrid(List<Map<String, dynamic>> folderContents) {
    return GridView.builder(
      padding: EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Display 2 folders/files per row
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: folderContents.length + 1, // Extra item for "Add Folder"
      itemBuilder: (context, index) {
        // If this is the last item, show the "Add Folder" option
        if (index == folderContents.length) {
          return GestureDetector(
            onTap: _showCreateFolderDialog,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 50, color: Colors.black54),
                    Text("Add Folder", style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
          );
        }

        final item = folderContents[index];

        // If it's an empty folder, display a "No items" message
        if (item['type'] == 'empty') {
          return Center(
            child: Text("No items in this folder"),
          );
        }

        return GestureDetector(
          onTap: () async {
            if (item['type'] == 'folder') {
              setState(() => _isLoading = true);
              try {
                // Attempt to access the folder to check for permissions
                await storage.ref(item['path']).listAll();
                setState(() {
                  _currentFolder = item['path'];
                  _isLoading = false;
                });
              } on FirebaseException catch (e) {
                setState(() => _isLoading = false);
                if (e.code == 'permission-denied') {
                  _showErrorDialog("You do not have permission to view this folder.");
                } else {
                  _showErrorDialog("Error accessing folder: ${e.message}");
                }
              } on MissingPluginException {
                setState(() => _isLoading = false);
                _showErrorDialog("You do not have permission.");
              } catch (e) {
                setState(() => _isLoading = false);
                _showErrorDialog("Error accessing folder: $e");
              }
            } else {
              _downloadFile(item['path'], item['name']);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item['type'] == 'folder'
                            ? Icons.folder
                            : Icons.insert_drive_file,
                        size: 50,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 8),
                      Text(
                        item['name'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (item['type'] == 'folder')
                  Positioned(
                    top: 0,
                    right: 0,
                    child: defaultDepartments.contains(item['name']) && _currentFolder == 'uploads'
                        ? SizedBox()
                        : IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteFolder(item['path'], item['name']);
                            },
                          ),
                  ),
                if (item['type'] == 'file')
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteFile(item['path'], item['name']);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Main UI build
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Loading()
        : Scaffold(
            // Removed AppBar
            // appBar: AppBar(
            //   title: Text("Uploads"),
            //   centerTitle: true,
            // ),
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  if (_currentFolder == 'uploads')
                    Column(
                      children: [
                        SizedBox(height: 20),
                        Text(
                          "Welcome to the uploads",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "Easily manage files across users.",
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  Expanded(
                    child: FutureBuilder(
                      future: _getFolderContents(_currentFolder),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Loading();
                        } else if (snapshot.hasError) {
                          String errorMessage = "An error occurred.";
                          if (snapshot.error is FirebaseException) {
                            FirebaseException e = snapshot.error as FirebaseException;
                            if (e.code == 'permission-denied') {
                              errorMessage = "You do not have permission to view this folder.";
                            } else {
                              errorMessage = e.message ?? "An error occurred.";
                            }
                          } else if (snapshot.error is MissingPluginException) {
                            errorMessage = "You do not have permission.";
                          }
                          return Center(
                            child: Text(errorMessage),
                          );
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("No Uploads yet"),
                                SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _uploadFile,
                                  child: Text("Upload Now"),
                                ),
                              ],
                            ),
                          );
                        }

                        final folderContents = snapshot.data as List<Map<String, dynamic>>;
                        return _buildFolderGrid(folderContents); // Display folders in grid view
                      },
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _uploadFile,
              child: Icon(Icons.cloud_upload),
              backgroundColor: Colors.blue,
            ),
          );
  }
}
