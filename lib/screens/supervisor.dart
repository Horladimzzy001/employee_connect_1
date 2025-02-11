import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phidrillsim_connect/loading.dart';
import 'package:phidrillsim_connect/screens/access_code_management.dart';

class SupervisorPage extends StatefulWidget {
  @override
  _SupervisorPageState createState() => _SupervisorPageState();
}

class _SupervisorPageState extends State<SupervisorPage> {
  bool _isLoading = false;

  final List<String> departments = [
    'Top Management',
    'Software Development',
    'Technical Development',
    'Business Development',
    'Administration',
    'Legal Development',
    'Social Media',
    'N/A', // Include 'N/A' for clients or visitors
  ];

  // Define getStatusColor inside the class
  Color getStatusColor(String status) {
    switch (status) {
      case 'Full Employee':
        return Colors.green; // 🟢
      case 'Contract Employee':
        return Colors.yellow; // 🟡
      case 'Intern Employee':
        return Colors.blue; // 🔵
      case 'Mentor/Advisor':
        return Colors.purple; // 🟣
      case 'Former Employee':
        return Colors.black; // ⚫
      case 'Fired Employee':
        return Colors.red; // 🔴
      case 'Client':
      case 'Visitor':
        return Colors.orange; // A color not yet used
      default:
        return Colors.grey; // Default color for unknown status
    }
  }


  final List<String> statuses = [
    'Full Employee',
    'Contract Employee',
    'Intern Employee',
    'Mentor/Advisor',
    'Former Employee',
    'Fired Employee',
    'Client',
    'Visitor',
  ];

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Supervisor Dashboard'),
    ),
    body: _isLoading
        ? Loading()
        : Column(
            children: [
              // Add the "Manage Access Codes" button here
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AccessCodeManagementPage()),
                    );
                  },
                  child: Text('Manage Access Codes'),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Loading();
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No users found.'));
                    }
                    return ListView(
                      children: snapshot.data!.docs.map((doc) {
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: getStatusColor(data['employeeStatus'] ?? data['status']),
                            child: Text(data['firstName'][0]),
                          ),
                          title: Text('${data['firstName']} ${data['surname']}'),
                          subtitle: Text('${data['department']} - ${data['status']}'),
                          trailing: Icon(Icons.arrow_forward),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SupervisorUserDetailsPage(
                                  userId: doc.id,
                                  userData: data,
                                  departments: departments,
                                  statuses: statuses,
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
  );
}

}

class SupervisorUserDetailsPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final List<String> departments;
  final List<String> statuses;

  SupervisorUserDetailsPage({
    required this.userId,
    required this.userData,
    required this.departments,
    required this.statuses,
  });

  @override
  _SupervisorUserDetailsPageState createState() =>
      _SupervisorUserDetailsPageState();
}

class _SupervisorUserDetailsPageState extends State<SupervisorUserDetailsPage> {
  late Map<String, dynamic> _userData;
  bool _isLoading = false;

  late String _selectedDepartment;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;

    // Initialize _selectedDepartment
    _selectedDepartment = widget.departments.contains(_userData['department'])
        ? _userData['department']
        : 'N/A';

    // Initialize _selectedStatus
    _selectedStatus = widget.statuses.contains(_userData['employeeStatus'])
        ? _userData['employeeStatus']
        : (_userData['status'] ?? widget.statuses.first);
  }

  Future<void> _updateUserData() async {
    setState(() {
      _isLoading = true;
    });

    await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
      'department': _selectedDepartment,
      'employeeStatus': _selectedStatus,
      // If the status is 'Client' or 'Visitor', update the 'status' field accordingly
      'status': (_selectedStatus == 'Client' || _selectedStatus == 'Visitor')
          ? _selectedStatus
          : 'Employee',
    });

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User data updated successfully')),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Full Employee':
        return Colors.green; // 🟢
      case 'Contract Employee':
        return Colors.yellow; // 🟡
      case 'Intern Employee':
        return Colors.blue; // 🔵
      case 'Mentor/Advisor':
        return Colors.purple; // 🟣
      case 'Former Employee':
        return Colors.black; // ⚫
      case 'Fired Employee':
        return Colors.red; // 🔴
      case 'Client':
      case 'Visitor':
        return Colors.orange; // A color not yet used
      default:
        return Colors.grey; // Default color for unknown status
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_userData['firstName']} ${_userData['surname']}'),
      ),
      body: _isLoading
          ? Loading()
          : Padding(
              padding: EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Display user information
                  Text('First Name: ${_userData['firstName']}'),
                  Text('Surname: ${_userData['surname']}'),
                  Text('Email: ${_userData['email']}'),
                  SizedBox(height: 20),
                  // Department Dropdown
                  Text('Department'),
                  DropdownButton<String>(
                    value: _selectedDepartment,
                    items: widget.departments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept,
                        child: Text(dept),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value!;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  // Status Dropdown
                  Text('Status'),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    items: widget.statuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                  SizedBox(height: 20),
                  // Update Button
                  ElevatedButton(
                    onPressed: _updateUserData,
                    child: Text('Update User Data'),
                  ),
                ],
              ),
            ),
    );
  }
}
