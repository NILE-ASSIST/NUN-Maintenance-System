import 'package:flutter/material.dart';
import 'package:nileassist/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:nileassist/main.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  void initState() {
    super.initState();
    // Run this check every time the profile is opened
    _checkEmailVerification();
  }

  //SYNC FUNCTION
  Future<void> _checkEmailVerification() async {
    //STOP CONDITION:
    // If the data passed to this screen ALREADY says verified, stop immediately.
    //
    if (widget.userData['emailVerified'] == true) {
      return; 
    }

    User? user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // 2. Only reload if the local Auth object thinks it's unverified
      if (!user.emailVerified) {
         try {
           await user.reload(); 
           user = FirebaseAuth.instance.currentUser; 
         } catch (e) {
           print("Error reloading user: $e");
           return;
         }
      }

      if (user != null && user.emailVerified) {
        
        final role = widget.userData['role'] ?? 'lecturer';
        final collection = _getCollectionFromRole(role);
        
        //Update the Database ONLY once
        await FirebaseFirestore.instance
            .collection(collection)
            .doc(user.uid)
            .update({'emailVerified': true});
            
        print("✅ Sync Complete: Firestore updated to Verified.");
        
        // Optional: Force a UI rebuild to show the new status immediately without a full reload
        if (mounted) {
          setState(() {
            // Update local widget data so we don't try to sync again
            widget.userData['emailVerified'] = true; 
          });
        }
      }
    }
  }
  
  // Moved helper up so it can be used in build()
  String _getCollectionFromRole(String role) {
    if (role == 'maintenance' || role == 'maintenance_staff') return 'maintenance';
    if (role == 'maintenance_supervisor') return 'maintenance_supervisors';
    if (role == 'facility_manager') return 'facility_managers';
    return 'lecturers'; // default
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Determine collection to listen to
    final String role = widget.userData['role'] ?? 'lecturer';
    final String collection = _getCollectionFromRole(role);

    return Scaffold(
      backgroundColor: MyApp.nileBlue,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      //listen to live data changes
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null 
            ? FirebaseFirestore.instance.collection(collection).doc(user.uid).snapshots() 
            : const Stream.empty(),
        builder: (context, snapshot) {
          // Use live data if available, otherwise fall back to initial widget.userData
          Map<String, dynamic> liveData = widget.userData;
          if (snapshot.hasData && snapshot.data!.exists) {
            liveData = snapshot.data!.data() as Map<String, dynamic>;
          }

          return Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    child: Column(
                      children: [
                        // Pass liveData to widgets
                        _buildProfileCard(liveData),
                        const SizedBox(height: 20),
                        _buildAccountDetailsCard(liveData),
                        const SizedBox(height: 20),
                        _buildMenuList(),
                        const SizedBox(height: 30),
                        
                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton(
                            onPressed: () async {
                              await AuthService().logout();
                              if (context.mounted) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.logout, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text("Log Out", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  // Updated to accept data map
  Widget _buildProfileCard(Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    final role = (data['role'] ?? 'student').toString().toLowerCase();

    Stream<QuerySnapshot> getTicketStream() {
      if (user == null) return const Stream.empty();

      final ticketsRef = FirebaseFirestore.instance.collection('tickets');

      if (role == 'maintenance' || role == 'maintenance_staff') {
        return ticketsRef.where('assignedStaffId', isEqualTo: user.uid).snapshots();
      } else if (role == 'maintenance_supervisor' || role == 'supervisor') {
        return ticketsRef.where('assignedTo', isEqualTo: user.uid).snapshots();
      } else {
        return ticketsRef.where('issuerID', isEqualTo: user.uid).snapshots();
      }
    }

    String totalLabel = (role.contains('maintenance') || role.contains('supervisor')) 
        ? "Assigned" 
        : "Submitted";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: MyApp.nileBlue,
            backgroundImage: data['profilePicture'] != null
                ? NetworkImage(data['profilePicture'])
                : null,
            child: data['profilePicture'] == null
                ? const Icon(Icons.account_circle, size: 60, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            data['fullName'] ?? 'User',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 20),

          StreamBuilder<QuerySnapshot>(
            stream: getTicketStream(),
            builder: (context, snapshot) {
              String totalCount = "0";
              String resolvedCount = "0";

              if (snapshot.hasData) {
                final docs = snapshot.data!.docs;
                totalCount = docs.length.toString();
                
                resolvedCount = docs
                    .where((doc) {
                      final status = (doc.data() as Map)['status']?.toString().toLowerCase() ?? '';
                      return status == 'resolved'; 
                    })
                    .length
                    .toString();
              }

              return Row(
                children: [
                  Expanded(child: _buildStatBox(totalCount, totalLabel)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildStatBox(resolvedCount, "Resolved")), 
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }

  // Updated to accept data map
  Widget _buildAccountDetailsCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Account Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Pass the live ID directly
          _buildStaffIdTile(data['staffId']),
          const SizedBox(height: 20),
          _buildDetailItem("Email", data['email'] ?? "", Icons.email_outlined),
          const SizedBox(height: 20),
          // Check live data for department
          if (data['department'] != null && data['department'].toString().isNotEmpty)
            _buildDetailItem("Department", data['department'], Icons.apartment_outlined),
        ],
      ),
    );
  }

  Widget _buildStaffIdTile(String? staffId) {
    final String displayId = staffId ?? 'Pending';
    return _buildDetailItem("Staff ID", displayId, Icons.badge_outlined);
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: MyApp.nileBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500)),
              if (value.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w400)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildMenuItem("Draft Complaints"),
          const Divider(height: 1),
          _buildMenuItem("Notifications"),
          const Divider(height: 1),
          _buildMenuItem("Help & Support"),
          const Divider(height: 1),
          _buildMenuItem("Privacy Policy"),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}