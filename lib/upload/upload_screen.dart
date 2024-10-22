import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For MissingPluginException
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:phidrillsim_connect/loading.dart'; // Assuming you have this loading widget
import 'dart:io';
import 'package:flutter/widgets.dart'; // For WillPopScope
import 'package:path/path.dart' as path;
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mime/mime.dart'; // For determining MIME types
import 'package:cached_network_image/cached_network_image.dart'; // For image caching
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:html' as html;


import 'package:path/path.dart' as path_lib;



import 'package:path_provider/path_provider.dart'; // For getting local directory
import 'package:path/path.dart' as path;

class ImagePreviewPage extends StatefulWidget {
  final String imageUrl;
  final String filePath;
  final String fileName;

  ImagePreviewPage({required this.imageUrl, required this.filePath, required this.fileName});

  @override
  _ImagePreviewPageState createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  bool _isLoading = false;
  // dimeji here
  static const platform = MethodChannel('com.phidrillsim.connect/download');
// dim
  FirebaseStorage storage = FirebaseStorage.instance;

  // Method to download the image
Future<void> _downloadImage() async {
  setState(() => _isLoading = true);
  try {
    final Reference ref = storage.ref(widget.filePath);
    final String downloadURL = await ref.getDownloadURL();

    // Get MIME type of the file
    final mimeType = lookupMimeType(widget.fileName) ?? 'application/octet-stream';

    // Call the platform-specific code
    final result = await platform.invokeMethod('saveFileToDownloads', {
      'url': downloadURL,
      'fileName': widget.fileName,
      'mimeType': mimeType,
    });

    _showInfoDialog("Image downloaded successfully");
  } on PlatformException catch (e) {
    _showErrorDialog("Error downloading image: ${e.message}");
  } catch (e) {
    _showErrorDialog("Error downloading image: $e");
  } finally {
    setState(() => _isLoading = false);
  }
}



  // Future<bool> _requestStoragePermission() async {
  //   if (Platform.isAndroid) {
  //     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //     if (androidInfo.version.sdkInt >= 30) {
  //       // For Android 11 and above
  //       var status = await Permission.manageExternalStorage.status;
  //       if (status.isGranted) {
  //         return true;
  //       } else if (status.isDenied) {
  //         var result = await Permission.manageExternalStorage.request();
  //         return result == PermissionStatus.granted;
  //       } else if (status.isPermanentlyDenied) {
  //         await openAppSettings();
  //         return false;
  //       }
  //     } else {
  //       // For Android 10 and below
  //       var status = await Permission.storage.status;
  //       if (status.isGranted) {
  //         return true;
  //       } else if (status.isDenied) {
  //         var result = await Permission.storage.request();
  //         return result == PermissionStatus.granted;
  //       } else if (status.isPermanentlyDenied) {
  //         await openAppSettings();
  //         return false;
  //       }
  //     }
  //   }
  //   // For other platforms, return true
  //   return true;
  // }

  // Dialog methods
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

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Information"),
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

  // Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Preview'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _isLoading ? null : _downloadImage,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : CachedNetworkImage(
                imageUrl: widget.imageUrl,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
      ),
    );
  }
}


class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}


class _UploadPageState extends State<UploadPage> {
  static const platform = MethodChannel('com.phidrillsim.connect/download');

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
  String _department = '';
  String _role = '';

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
    DocumentSnapshot userDoc =
        await firestore.collection('users').doc(user!.uid).get();
    if (userDoc.exists) {
      setState(() {
        _firstName = userDoc['firstName'] ?? '';
        _surname = userDoc['surname'] ?? '';
        _department = userDoc['department'] ?? '';
        _role = userDoc['role'] ?? '';
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

// Modify the _getFolderContents method
Future<List<Map<String, dynamic>>> _getFolderContents(String path) async {
  try {
    final ListResult result = await storage.ref(path).listAll();
    List<Map<String, dynamic>> contents = [];

    // Folders
    for (var prefix in result.prefixes) {
      contents.add({
        "name": prefix.name,
        "type": "folder",
        "path": prefix.fullPath,
      });
    }

    // Files
    for (var item in result.items) {
      // Exclude the '.keep' files
      if (item.name != '.keep') {
        // Determine file type based on extension
        String extension = path_lib.extension(item.name).toLowerCase();
        String fileType = 'unknown';

        if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
          fileType = 'image';
        } else if (['.pdf'].contains(extension)) {
          fileType = 'pdf';
        } else if (['.doc', '.docx'].contains(extension)) {
          fileType = 'word';
        } else if (['.xls', '.xlsx'].contains(extension)) {
          fileType = 'excel';
        } else if (['.ppt', '.pptx'].contains(extension)) {
          fileType = 'powerpoint';
        } else if (['.txt'].contains(extension)) {
          fileType = 'text';
        } else if (['.mp4', '.avi', '.mov', '.mkv'].contains(extension)) {
          fileType = 'video';
        } else if (['.mp3', '.wav', '.aac', '.flac'].contains(extension)) {
          fileType = 'audio';
        } else {
          fileType = 'file';
        }

        // For images, get the download URL
        String? thumbnailUrl;
        if (fileType == 'image') {
          try {
            thumbnailUrl = await item.getDownloadURL();
          } catch (e) {
            thumbnailUrl = null; // Handle any errors in getting the URL
          }
        }

        contents.add({
          "name": item.name,
          "type": "file",
          "path": item.fullPath,
          "fileType": fileType,
          "thumbnailUrl": thumbnailUrl,
        });
      }
    }

    // Handle empty folder
    if (contents.isEmpty) {
      contents.add({"name": "No items", "type": "empty", "path": ""});
    }

    return contents;
  } catch (e) {
    // Handle errors
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
    // If not assigning, store the file information without assigned users
    await firestore.collection('fileAssignments').add({
      'fileName': fileName,
      'filePath': filePath,
      'uploadedBy': user!.uid,
      'uploadedByName': '$_firstName $_surname',
      'assignedTo': [],
      'timestamp': FieldValue.serverTimestamp(),
    });
    _showInfoDialog("File uploaded successfully!");
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
    // Fetch file details from Firestore
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

    // Get the uploader's user ID
    String uploadedBy = fileDoc['uploadedBy'];

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

    if (canDownload) {
      // User has permission to download the file
      await _download(filePath, fileName);  // Proceed with download
    } else {
      // User does not have permission
      _showErrorDialog(
          'You do not have permission to view this file. Please contact your supervisor or $uploaderName who uploaded it.');
    }
  } catch (e) {
    _showErrorDialog('An error occurred: $e');
  } finally {
    setState(() => _isLoading = false);  // Stop showing the loader
  }
}

Future<void> _downloadFileWeb(String url, String fileName) async {
  try {
    // Create an anchor element and set the href to the file URL
    final html.AnchorElement anchor = html.AnchorElement(href: url)
      ..target = 'blank';

    // Set the download attribute with the desired file name
    anchor.download = fileName;

    // Trigger the download by simulating a click
    html.document.body?.append(anchor);
    anchor.click();

    // Remove the anchor element from the document
    anchor.remove();
  } catch (e) {
    _showErrorDialog("Error downloading file: $e");
  }
}





 
  // Method to download the file (actual logic to save file)
// Method to download the file (save it to Downloads folder)
Future<void> _download(String filePath, String fileName) async {
  setState(() => _isLoading = true);
  try {
    final Reference ref = storage.ref(filePath);
    final String downloadURL = await ref.getDownloadURL();

    // Get MIME type of the file
    final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

    if (kIsWeb) {
      // For Web Platform
      await _downloadFileWeb(downloadURL, fileName);
    } else {
      // For Mobile Platforms
      await platform.invokeMethod('saveFileToDownloads', {
        'url': downloadURL,
        'fileName': fileName,
        'mimeType': mimeType,
      });
    }

    _showInfoDialog("File downloaded successfully");
  } on PlatformException catch (e) {
    _showErrorDialog("Error downloading file: ${e.message}");
  } catch (e) {
    _showErrorDialog("Error downloading file: $e");
  } finally {
    setState(() => _isLoading = false);
  }
}




// Future<bool> _requestStoragePermission() async {
//   if (Platform.isAndroid) {
//     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
//     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//     if (androidInfo.version.sdkInt >= 30) {
//       // For Android 11 and above
//       var status = await Permission.manageExternalStorage.status;
//       if (status.isGranted) {
//         return true;
//       } else if (status.isDenied) {
//         var result = await Permission.manageExternalStorage.request();
//         return result == PermissionStatus.granted;
//       } else if (status.isPermanentlyDenied) {
//         await openAppSettings();
//         return false;
//       }
//     } else {
//       // For Android 10 and below
//       var status = await Permission.storage.status;
//       if (status.isGranted) {
//         return true;
//       } else if (status.isDenied) {
//         var result = await Permission.storage.request();
//         return result == PermissionStatus.granted;
//       } else if (status.isPermanentlyDenied) {
//         await openAppSettings();
//         return false;
//       }
//     }
//   }
//   // For other platforms, return true
//   return true;
// }





// Modify the _buildFolderGrid method
Widget _buildFolderGrid(List<Map<String, dynamic>> folderContents) {
  return GridView.builder(
    padding: EdgeInsets.all(10),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    ),
    itemCount: folderContents.length + 1, // Extra item for "Add Folder"
    itemBuilder: (context, index) {
      // Check if this is the last item (Add Folder button)
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

      // Now it's safe to access folderContents[index]
      final item = folderContents[index];

      // Handle empty folders
      if (item['type'] == 'empty') {
        return Center(
          child: Text("No items in this folder"),
        );
      }

      return GestureDetector(
onTap: () async {
  if (item['type'] == 'folder') {
    // Check if the folder is a default department folder
    if (defaultDepartments.contains(item['name'])) {
      // Check if the user's department matches the folder name or if they are a Manager or Supervisor
      if (_department == item['name'] || _role == 'Manager' || _role == 'Supervisors') {
        // User has access
        setState(() => _isLoading = true);
        try {
          await storage.ref(item['path']).listAll();
          setState(() {
            _currentFolder = item['path'];
            _isLoading = false;
          });
        } catch (e) {
          setState(() => _isLoading = false);
          _showErrorDialog("Error accessing folder: $e");
        }
      } else {
        // User does not have access
        _showErrorDialog("You do not have permission to enter this department's folder.");
      }
    } else {
      // Folder is not a default department folder, allow access
      setState(() => _isLoading = true);
      try {
        await storage.ref(item['path']).listAll();
        setState(() {
          _currentFolder = item['path'];
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        _showErrorDialog("Error accessing folder: $e");
      }
    }
  } else if (item['fileType'] == 'image' && item['thumbnailUrl'] != null) {
    // Show image preview
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewPage(
          imageUrl: item['thumbnailUrl'],
          filePath: item['path'],
          fileName: item['name'],
        ),
      ),
    );
          } else {
            // Download other files
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
                    if (item['type'] == 'folder')
                      Icon(Icons.folder, size: 50, color: Colors.blue)
                    else if (item['fileType'] == 'image' && item['thumbnailUrl'] != null)
                      CachedNetworkImage(
                        imageUrl: item['thumbnailUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 50),
                      )
                    else if (item['fileType'] == 'pdf')
                      Icon(Icons.picture_as_pdf, size: 50, color: Colors.red)
                    else if (item['fileType'] == 'word')
                      Icon(Icons.description, size: 50, color: Colors.blueAccent)
                    else if (item['fileType'] == 'excel')
                      Icon(Icons.grid_on, size: 50, color: Colors.green)
                    else if (item['fileType'] == 'powerpoint')
                      Icon(Icons.slideshow, size: 50, color: Colors.orange)
                    else if (item['fileType'] == 'text')
                      Icon(Icons.text_snippet, size: 50, color: Colors.grey)
                    else if (item['fileType'] == 'video')
                      Icon(Icons.video_library, size: 50, color: Colors.purple)
                    else if (item['fileType'] == 'audio')
                      Icon(Icons.audiotrack, size: 50, color: Colors.teal)
                    else
                      Icon(Icons.insert_drive_file, size: 50, color: Colors.blueGrey),
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
              // Delete button
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
