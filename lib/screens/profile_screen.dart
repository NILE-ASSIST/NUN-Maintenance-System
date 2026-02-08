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
  Widget build(BuildContext context) {
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
      body: Column(
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
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildAccountDetailsCard(),
                    const SizedBox(height: 20),
                    _buildMenuList(),
                    const SizedBox(height: 30),
                    
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () async {
                          //Perform the logout
                          await AuthService().logout();
                          
                          //clear the navigation stack
                          // This removes 'ProfileScreen' and drops the user back to the 
                          // root screen, which StreamBuilder will update to the Login/Welcome screen.
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
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = FirebaseAuth.instance.currentUser;
    // Normalize role string to lowercase to prevent mismatch errors
    final role = (widget.userData['role'] ?? 'student').toString().toLowerCase();

    // --- LOGIC: Decide which field to query based on Role ---
    Stream<QuerySnapshot> getTicketStream() {
      if (user == null) return const Stream.empty();

      final ticketsRef = FirebaseFirestore.instance.collection('tickets');

      if (role == 'maintenance' || role == 'maintenance_staff') {
        // Staff: Count tickets assigned specifically to them
        return ticketsRef.where('assignedStaffId', isEqualTo: user.uid).snapshots();
      } else if (role == 'maintenance_supervisor' || role == 'supervisor') {
        // Supervisor: Count tickets assigned to their queue
        return ticketsRef.where('assignedTo', isEqualTo: user.uid).snapshots();
      } else {
        // Students/Lecturers: Count tickets they created
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
            backgroundImage: widget.userData['profilePicture'] != null
                ? NetworkImage(widget.userData['profilePicture'])
                : null,
            child: widget.userData['profilePicture'] == null
                ? const Icon(Icons.account_circle, size: 60, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            widget.userData['fullName'] ?? 'User',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 20),

          // stream builder to get ticket counts
          StreamBuilder<QuerySnapshot>(
            stream: getTicketStream(),
            builder: (context, snapshot) {
              String totalCount = "0";
              String resolvedCount = "0";

              if (snapshot.hasData) {
                final docs = snapshot.data!.docs;
                totalCount = docs.length.toString();
                
                // only counts fully 'Resolved' tickets
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

  Widget _buildAccountDetailsCard() {
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
          _buildStaffIdTile(),
          const SizedBox(height: 20),
          _buildDetailItem("Email", widget.userData['email'] ?? "", Icons.email_outlined),
          const SizedBox(height: 20),
          if (widget.userData['department'] != null && widget.userData['department'].toString().isNotEmpty)
            _buildDetailItem("Department", widget.userData['department'], Icons.apartment_outlined),
        ],
      ),
    );
  }

  Widget _buildStaffIdTile() {
    final String currentId = widget.userData['staffId'] ?? 'Pending';
    if (currentId != 'Pending' && currentId.isNotEmpty) {
      return _buildDetailItem("Staff ID", currentId, Icons.badge_outlined);
    }
    final user = FirebaseAuth.instance.currentUser;
    // Default to lecturer if role is missing, but adjust collection map in auth service if needed
    final String role = widget.userData['role'] ?? 'lecturer';
    // Ensure you have a helper to get collection name, or just hardcode checking based on role
    final String collection = _getCollectionFromRole(role); 

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null ? FirebaseFirestore.instance.collection(collection).doc(user.uid).snapshots() : const Stream.empty(),
      builder: (context, snapshot) {
        String displayId = currentId;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          displayId = data['staffId'] ?? 'Pending';
        }
        return _buildDetailItem("Staff ID", displayId, Icons.badge_outlined);
      },
    );
  }

  // simple helper to route role to collection
  String _getCollectionFromRole(String role) {
    if (role == 'maintenance' || role == 'maintenance_staff') return 'maintenance';
    if (role == 'maintenance_supervisor') return 'maintenance_supervisors';
    if (role == 'facility_manager') return 'facility_managers';
    return 'lecturers'; // default
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