import 'package:cropcure/admin/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // To format the timestamp into a human-readable date/time format

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ActivityLogScreenState createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  String searchQuery = "";
  String filterType = "All"; // Filter types: All, Online, Offline

  // Function to show logout confirmation dialog
  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 63, 150, 69),
          elevation: 10,
          shadowColor: Colors.black,
          title: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: Colors.white),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Color.fromARGB(255, 77, 6, 1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(width: 1, color: Colors.white),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 73, 223, 93),
                        Color.fromARGB(255, 38, 117, 50),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(width: 1, color: Colors.white),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        _logout(); // Implement logout action here
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Logout action
  void _logout() {
    Get.offAll(() => MyLogin());
    Get.snackbar('Success', 'Logged Out Success!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        toolbarHeight: 80,
        title: const Padding(
          padding: EdgeInsets.only(top: 30),
          child: Text(
            'Activity Log',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 50, top: 30),
            child: IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.black),
              onPressed: _showLogoutDialog,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 50),
        child: Column(
          children: [
            TextField(
              style: const TextStyle(color: Colors.black),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Search by email...",
                hintStyle: const TextStyle(color: Colors.black),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Data Table with Firestore Integration
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('activity_logs')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No activity logs found.",
                        style: TextStyle(color: Colors.black),
                      ),
                    );
                  }

                  // Filter data based on search query and filter type
                  final filteredData =
                      snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final email =
                            data['email']?.toString().toLowerCase() ?? '';
                        final status = data['status']?.toString() ?? '';
                        return (filterType == "All" || status == filterType) &&
                            email.contains(searchQuery.toLowerCase());
                      }).toList();

                  // Summary Data
                  final totalUsers = snapshot.data!.docs.length;
                  final onlineUsers =
                      snapshot.data!.docs
                          .where(
                            (doc) =>
                                (doc.data()
                                    as Map<String, dynamic>)['status'] ==
                                "online",
                          )
                          .length;
                  final offlineUsers =
                      snapshot.data!.docs
                          .where(
                            (doc) =>
                                (doc.data()
                                    as Map<String, dynamic>)['status'] !=
                                "online",
                          )
                          .length;

                  return Column(
                    children: [
                      // Summary Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryCard(
                            title: "Total Users",
                            count: totalUsers,
                            color: Colors.grey,
                            onTap: () {
                              setState(() {
                                filterType = "All";
                              });
                            },
                          ),
                          _buildSummaryCard(
                            title: "Online Users",
                            count: onlineUsers,
                            color: const Color.fromARGB(255, 63, 150, 69),
                            onTap: () {
                              setState(() {
                                filterType = "online";
                              });
                            },
                          ),
                          _buildSummaryCard(
                            title: "Offline Users",
                            count: offlineUsers,
                            color: const Color.fromARGB(255, 136, 57, 49),
                            onTap: () {
                              setState(() {
                                filterType = "offline";
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Data Table
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: DataTable(
                              columnSpacing: 24.0,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    "ID",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Email",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "IP Address",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Sign-Up Date",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Sign-Up Time",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Status",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ],
                              rows:
                                  filteredData.map((doc) {
                                    final data =
                                        doc.data() as Map<String, dynamic>;

                                    // Format Timestamp fields
                                    final signUpDate =
                                        data['timestamp'] is Timestamp
                                            ? DateFormat('yyyy-MM-dd').format(
                                              (data['timestamp'] as Timestamp)
                                                  .toDate(),
                                            )
                                            : 'N/A';

                                    final signUpTime =
                                        data['timestamp'] is Timestamp
                                            ? DateFormat('HH:mm:ss').format(
                                              (data['timestamp'] as Timestamp)
                                                  .toDate(),
                                            )
                                            : 'N/A';

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            data['user_id']?.toString() ??
                                                'N/A',
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            data['email']?.toString() ?? 'N/A',
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            data['ip_address']?.toString() ??
                                                'N/A',
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            signUpDate,
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            signUpTime,
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                              vertical: 4.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  data['status'] == "online"
                                                      ? const Color.fromARGB(
                                                        255,
                                                        63,
                                                        150,
                                                        69,
                                                      )
                                                      : Colors.black
                                                          .withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                            ),
                                            child: Text(
                                              data['status']?.toString() ??
                                                  'N/A',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$count",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
