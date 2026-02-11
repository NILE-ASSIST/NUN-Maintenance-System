import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/complaintDetail.dart';

class MaintenanceSupervisor extends StatelessWidget {
  const MaintenanceSupervisor({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: MyApp.nileBlue,
      appBar: AppBar(
        title: const Text("Supervisor Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
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
              .where('assignedTo', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            //filter: Hide resolved tickets
            final docs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] != 'Resolved';
            }).toList();

            if (docs.isEmpty) {
              return _buildEmptyState();
            }

            // sort locally
            docs.sort((a, b) {
                Timestamp? tA = (a.data() as Map)['dateAssigned'];
                Timestamp? tB = (b.data() as Map)['dateAssigned'];
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
    final Timestamp? dateAssigned = data['dateAssigned'];
    
    final String dateStr = dateAssigned != null 
        ? DateFormat('MMM d, h:mm a').format(dateAssigned.toDate()) 
        : 'Just now';

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
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
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
          Icon(Icons.folder_open_rounded, size: 60, color: Colors.grey.shade300),
          // Icon(Icons.check_circle_outline, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No tickets available", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}