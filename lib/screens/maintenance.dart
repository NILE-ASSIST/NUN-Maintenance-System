import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/complaintDetail.dart';
import 'package:nileassist/screens/mainLayout.dart';

class MaintenanceDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MaintenanceDashboard({
    super.key,
    required this.userData,
    this.onNavigateToComplaints,
  });

  final VoidCallback? onNavigateToComplaints;

  @override
  State<MaintenanceDashboard> createState() => _MaintenanceDashboardState();
}

class _MaintenanceDashboardState extends State<MaintenanceDashboard> {
  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final String displayName =
        widget.userData['fullName']?.toString() ?? '----';

    return Scaffold(
      backgroundColor: MyApp.nileBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Maintenance Staff",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName, 
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _headerIconButton(Icons.history),
                      const SizedBox(width: 12),
                      _headerIconButton(Icons.notifications),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
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
                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 40, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsRow(0, 0, 0),
                            const SizedBox(height: 40),
                            _recentTicketsSection([]),
                          ],
                        ),
                      );
                    }

                    final allDocs = snapshot.data!.docs;
                    //stat logic
                    int assignedCount = allDocs.where((d) {
                      final status =
                          (d.data() as Map)['status']
                              ?.toString()
                              .toLowerCase() ??
                          '';
                      return status == 'pending' ||
                          status == 'assigned' ||
                          status == 'in progress' ||
                          status == 'being validated' ||
                          status == 'needs recheck';
                    }).length;

                    int overdueCount = allDocs.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final status =
                          data['status']?.toString().toLowerCase() ?? '';

                      if (status == 'in progress') {
                        Timestamp? timestamp =
                            data['dateStaffAssigned'] ?? data['dateCreated'];

                        if (timestamp != null) {
                          DateTime dateAssigned = timestamp.toDate();
                          DateTime now = DateTime.now();

                          if (now.difference(dateAssigned).inDays > 7) {
                            return true;
                          }
                        }
                      }
                      return false;
                    }).length;

                    int doneCount = allDocs.where((d) {
                      final status =
                          (d.data() as Map)['status']
                              ?.toString()
                              .toLowerCase() ??
                          '';
                      return status == 'resolved';
                    }).length;

                    //Filter only Pending tickets for the List
                    final pendingDocs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status']?.toString().toLowerCase() ?? '';
                      return status == 'pending' || status == 'assigned';
                    }).toList();

                    // Sort locally by date (newest first)
                    pendingDocs.sort((a, b) {
                      final dataA = a.data() as Map<String, dynamic>;
                      final dataB = b.data() as Map<String, dynamic>;
                      Timestamp? tA =
                          dataA['dateStaffAssigned'] ?? dataA['dateCreated'];
                      Timestamp? tB =
                          dataB['dateStaffAssigned'] ?? dataB['dateCreated'];
                      if (tA == null || tB == null) return 0;
                      return tB.compareTo(tA);
                    });

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 40, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          _buildStatsRow(
                            assignedCount,
                            overdueCount,
                            doneCount,
                          ),

                          const SizedBox(height: 40),

                          //Task section
                          _recentTicketsSection(pendingDocs),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _headerIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10), 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14), 
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildStatsRow(int assigned, int overdue, int done) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statBox(
            "Assigned",
            assigned.toString(),
            Icons.sync,
            const Color(0xFF3F51B5),
          ),
          _statBox(
            "Overdue",
            overdue.toString(),
            Icons.warning_amber_rounded,
            Colors.orange,
          ),
          _statBox("Done", done.toString(), Icons.check_circle, Colors.green),
        ],
      ),
    );
  }

  Widget _statBox(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentTicketsSection(List<QueryDocumentSnapshot> complaints) {
    // only 3 most recent pending tickets are displayed
    final recentComplaints = complaints.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Tasks",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  if (widget.onNavigateToComplaints != null) {
                    widget.onNavigateToComplaints!();
                  }
                },
                child: const Text(
                  "View All >",
                  style: TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentComplaints.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  "No pending tickets.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentComplaints.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Pending';
              final timestamp = data['dateStaffAssigned'] ?? data['dateCreated'] as Timestamp?;
              final date = timestamp != null
                  ? DateFormat('MMM d, h:mm a').format(timestamp.toDate())
                  : 'Just now';

              // Only needed to style Pending
              Color statusColor = Colors.orange;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ticketCard(
                  ticketId: doc.id,
                  data: data,
                  status: status,
                  color: statusColor,
                  title: data['description'] ?? 'No description',
                  category: data['category'] ?? 'General',
                  date: date,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _ticketCard({
    required String ticketId,
    required Map<String, dynamic> data,
    required String status,
    required Color color,
    required String title,
    required String category,
    required String date,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ComplaintDetailScreen(ticketId: ticketId, data: data),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "ID: #${ticketId.length > 6 ? ticketId.substring(0, 6).toUpperCase() : ticketId}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(category),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}