import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/complaintDetail.dart';

class MaintenanceDashboard extends StatefulWidget {
  const MaintenanceDashboard({super.key});

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: MyApp.nileBlue,
      appBar: AppBar(
        backgroundColor: MyApp.nileBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Maintenance Dashboard'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7FB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('tickets')
              .where('assignedStaffId', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            //filter: hide resolved
            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] != 'Resolved';
            }).toList();

            if (docs.isEmpty) {
              return _buildEmptyState();
            }

            // Sort locally by date (newest first)
            docs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              Timestamp? tA = dataA['dateStaffAssigned'] ?? dataA['dateCreated'];
              Timestamp? tB = dataB['dateStaffAssigned'] ?? dataB['dateCreated'];
              if (tA == null || tB == null) return 0;
              return tB.compareTo(tA);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final ticketId = docs[index].id;

                return _buildTaskCard(context, ticketId, data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, String id, Map<String, dynamic> data) {
    final String title = data['description'] ?? 'No Description';
    final String location = data['location'] ?? 'Unknown Location';
    final String status = data['status'] ?? 'Pending';
    final Timestamp? dateAssigned = data['dateStaffAssigned'] ?? data['dateCreated'];

    final String dateStr = dateAssigned != null
        ? DateFormat('MMM d, h:mm a').format(dateAssigned.toDate())
        : 'Just now';

    Color statusColor;
    Color statusBgColor;

    switch (status.toLowerCase()) {
      case 'being validated':
        statusColor = Colors.purple;
        statusBgColor = Colors.purple.shade50;
        break;
      case 'needs recheck':
        statusColor = Colors.red;
        statusBgColor = Colors.red.shade50;
        break;
      default:
        statusColor = Colors.blue;
        statusBgColor = Colors.blue.shade50;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ComplaintDetailScreen(ticketId: id, data: data)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(location, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No active tasks.", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}