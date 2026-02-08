import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/complaintDetail.dart';

class FMDashboard extends StatelessWidget {
  const FMDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Facility Manager Dashboard"),
        backgroundColor: MyApp.nileBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      // backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tickets found"));
          }

          // Sort locally to avoid Firestore composite index requirements
          final docs = snapshot.data!.docs.toList();
          docs.sort((a, b) {
            final tA =
                (a.data() as Map<String, dynamic>)['dateCreated'] as Timestamp?;
            final tB =
                (b.data() as Map<String, dynamic>)['dateCreated'] as Timestamp?;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return TicketCard(
                ticketId: doc.id,
                description: data['description'] ?? 'No Description',
                category: data['category'] ?? 'General',
                location: data['location'] ?? 'Unknown',
                status: data['status'] ?? 'Pending',
                timestamp: data['dateCreated'] as Timestamp?,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ComplaintDetailScreen(ticketId: doc.id, data: data),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class TicketCard extends StatelessWidget {
  final String ticketId;
  final String description;
  final String category;
  final String location;
  final String status;
  final Timestamp? timestamp;
  final VoidCallback onTap;

  const TicketCard({
    super.key,
    required this.ticketId,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    this.timestamp,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFE67E22); 
      case 'in progress':
        return const Color(0xFF3498DB);
      case 'resolved':
        return const Color(0xFF27AE60);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFDF2E9);
      case 'in progress':
        return const Color(0xFFEBF5FB);
      case 'resolved':
        return const Color(0xFFE9F7EF);
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    //date formatting
    final dateStr = timestamp != null
        ? DateFormat('MMM d, yyyy').format(timestamp!.toDate())
        : 'Just now';

    // shorten ID for display (like "Tracking ID... A23F")
    final shortId = ticketId.length > 6
        ? ticketId.substring(0, 6).toUpperCase()
        : ticketId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Row 1: tracking ID, status badge, date
                Row(
                  children: [
                    Text(
                      'ID: #$shortId',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                //Row 2: Description (Main Title)
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F312B),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 12),

                //footer (category, location)
                Row(
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 1,
                      height: 14,
                      color: Colors.grey.shade400,
                    ),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
