import 'package:flutter/material.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/screens/complaint_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nileassist/screens/complaint_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nileassist/screens/complaintDetail.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const DashboardScreen({super.key, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<QuerySnapshot> _getComplaintsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    
    // We stream ALL tickets here so the Stats Row (Total/Resolved) counts are accurate
    return _firestore
        .collection('tickets')
        .where('issuerID', isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.nileBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Good ${_getGreeting()},\n${widget.userData['fullName'] ?? '----'}",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getComplaintsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final allDocs = snapshot.data?.docs ?? [];

                    // Pending tickets only
                    // In Progress, Resolved are hidden from the list.
                    final pendingDocs = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'Pending';
                      return status == 'Pending';
                    }).toList();

                    // Sort by Date (Newest first)
                    pendingDocs.sort((a, b) {
                      Timestamp? tA = (a.data() as Map)['dateCreated'];
                      Timestamp? tB = (b.data() as Map)['dateCreated'];
                      if (tA == null || tB == null) return 0;
                      return tB.compareTo(tA);
                    });
                    
                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 30, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pass ALL docs to stats so "Total", "Resolved", etc. are correct
                          _statsRow(allDocs),
                          const SizedBox(height: 20),
                          _submitButton(context),
                          const SizedBox(height: 20),
                          // Pass PENDING docs to the list (top 3 will be shown)
                          _recentTicketsSection(pendingDocs),
                          const SizedBox(height: 20),
                          _draftsCard(),
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

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _statsRow(List<QueryDocumentSnapshot> complaints) {
    final total = complaints.length;
    final pending = complaints.where((c) => (c.data() as Map)['status'] == 'Pending').length;
    final inProgress = complaints.where((c) => (c.data() as Map)['status'] == 'In Progress').length;
    final resolved = complaints.where((c) => (c.data() as Map)['status'] == 'Resolved').length;
    
    final stats = [
      {"title": "Total", "value": total, "icon": Icons.confirmation_number, "color": Colors.black},
      {"title": "Pending", "value": pending, "icon": Icons.schedule, "color": Colors.orange},
      {"title": "Ongoing", "value": inProgress, "icon": Icons.sync, "color": Colors.purple},
      {"title": "Resolved", "value": resolved, "icon": Icons.check_circle, "color": MyApp.nileGreen},
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: stats.asMap().entries.map((entry) {
          final isLast = entry.key == stats.length - 1;
          final stat = entry.value;
          
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0.0 : 8.0),
              child: _StatCard(
                title: stat["title"] as String,
                value: stat["value"].toString(),
                icon: stat["icon"] as IconData,
                color: stat["color"] as Color,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ComplaintFormPage()));
        },
        icon: const Icon(Icons.add),
        label: const Text("Submit New Complaint", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _recentTicketsSection(List<QueryDocumentSnapshot> complaints) {
    // only 3 most recent pending tickets are displayed
    // If there are 5 pending tickets, this takes the top 3.
    // The user must click "View All" to see the other 2 in the ComplaintScreen.
    final recentComplaints = complaints.take(3).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pending Tickets", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const ComplaintScreen()));
                },
                child: const Text("View All >", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentComplaints.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: const Center(child: Text("No pending tickets.", style: TextStyle(color: Colors.grey))),
            )
          else
            ...recentComplaints.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Pending';
              final timestamp = data['dateCreated'] as Timestamp?;
              final date = timestamp != null ? DateFormat('MMM d, yyyy').format(timestamp.toDate()) : 'Just now';
              
              // Only needed to style Pending, but safe to keep default
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => ComplaintDetailScreen(ticketId: ticketId, data: data)));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text("ID: #${ticketId.length > 6 ? ticketId.substring(0, 6).toUpperCase() : ticketId}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(category),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _draftsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: const [
            Icon(Icons.description, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Drafts", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("0 unsaved drafts", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title, 
    required this.value, 
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(14)
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}