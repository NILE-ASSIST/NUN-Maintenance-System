import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/main.dart';

// --- CUSTOM IMPORTS ---
import 'package:nileassist/services/complaint_services.dart';
import 'package:nileassist/widgets/priority_widget.dart'; 
import 'package:nileassist/widgets/complaint_info_widget.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final String ticketId;
  final Map<String, dynamic> data;
  final TicketService _ticketService = TicketService(); // Initialize our new brain!

  ComplaintDetailScreen({
    super.key,
    required this.ticketId,
    required this.data,
  });

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get isIssuer => data['issuerID'] == currentUid;

  Future<bool> _isFacilityManager() async {
    if (currentUid.isEmpty) return false;
    final doc = await FirebaseFirestore.instance.collection('facility_managers').doc(currentUid).get();
    return doc.exists;
  }

  Future<bool> _isSupervisor() async {
    if (currentUid.isEmpty) return false;
    final doc = await FirebaseFirestore.instance.collection('maintenance_supervisors').doc(currentUid).get();
    return doc.exists;
  }

  Future<bool> _isMaintenanceStaff() async {
    if (currentUid.isEmpty) return false;
    final doc = await FirebaseFirestore.instance.collection('maintenance').doc(currentUid).get();
    return doc.exists;
  }

  // --- DIALOG BUILDERS ---
  void _showSupervisorDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (context) => _buildSelectionDialog(
        context: context,
        title: "Assign to $category Supervisor",
        collection: 'maintenance_supervisors',
        category: category,
        onSelect: (id, name) => _ticketService.assignTicketToSupervisor(context, ticketId, data, id, name),
      ),
    );
  }

  void _showStaffDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (context) => _buildSelectionDialog(
        context: context,
        title: "Assign $category Staff",
        collection: 'maintenance',
        category: category,
        onSelect: (id, name) => _ticketService.assignToStaff(context, ticketId, data, id, name),
      ),
    );
  }

  Widget _buildSelectionDialog({required BuildContext context, required String title, required String collection, required String category, required Function(String id, String name) onSelect}) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(collection).where('department', isEqualTo: category).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("No personnel found in $category.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)));
            
            final docs = snapshot.data!.docs;
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final d = docs[index].data() as Map<String, dynamic>;
                final String fullName = d['fullName'] ?? 'Unknown';
                final String dept = d['department'] ?? 'General';
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S')),
                  title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Dept: $dept"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
                  onTap: () => onSelect(docs[index].id, fullName),
                );
              },
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel"))],
    );
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final Timestamp? timestamp = data['dateCreated'] as Timestamp?;
    final String dateStr = timestamp != null ? DateFormat('MMMM d, yyyy • h:mm a').format(timestamp.toDate()) : 'Unknown Date';
    final String status = data['status'] ?? 'Pending';
    final String category = data['category'] ?? 'General';

    Color statusColor;
    Color statusBgColor;

    switch (status.toLowerCase()) {
      case 'resolved': statusColor = const Color(0xFF27AE60); statusBgColor = const Color(0xFFE9F7EF); break;
      case 'being validated': statusColor = const Color(0xFF8E44AD); statusBgColor = const Color(0xFFF4ECF7); break;
      case 'needs recheck': statusColor = const Color(0xFFC0392B); statusBgColor = const Color(0xFFF9EBEA); break;
      case 'in progress': statusColor = const Color(0xFF3498DB); statusBgColor = const Color(0xFFEBF5FB); break;
      default: statusColor = const Color(0xFFE67E22); statusBgColor = const Color(0xFFFDF2E9);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Complaint Details"),
        centerTitle: true,
        backgroundColor: MyApp.nileBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ID: #${ticketId.length > 6 ? ticketId.substring(0, 6).toUpperCase() : ticketId}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(data['description'] ?? 'No description.', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F312B), height: 1.3)),
            const SizedBox(height: 12),
            Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 16),
            
            // PRIORITY
            FutureBuilder<bool>(
              future: _isFacilityManager(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return FacilityManagerPriorityEditor(ticketId: ticketId, initialPriority: data['priority'] ?? 'Medium');
                }
                return PriorityBadge(priorityLevel: data['priority']);
              },
            ),
            
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),
            
            // DETAILS & PEOPLE
            Row(
              children: [
                InfoTile(icon: Icons.location_on_outlined, label: "Location", value: data['location'] ?? 'Unknown'),
                const SizedBox(width: 20),
                InfoTile(icon: Icons.category_outlined, label: "Category", value: category),
              ],
            ),
            const SizedBox(height: 20),
            PersonCard(title: "Issuer Info", name: data['issuerName'] ?? 'No name', role: data['issuerRole'] ?? 'Unknown role', icon: Icons.person_outline, isEmail: true),
            
            // ASSIGNED PERSONNEL
            if (data['assignedTo'] != null)
              AsyncPersonCard(title: "Assigned Supervisor", userId: data['assignedTo'], collection: 'maintenance_supervisors'),
            if (data['assignedStaffId'] != null)
              AsyncPersonCard(title: "Assigned Staff", userId: data['assignedStaffId'], collection: 'maintenance'),

            const SizedBox(height: 30),

            // TIMELINE & ATTACHMENT
            StatusTimeline(status: status, data: data),
            const SizedBox(height: 30),
            const Text("Attachment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // IMAGE
            if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
               ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(data['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover))
            else if (data['attachmentName'] != null)
               Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Column(children: [const Icon(Icons.description_outlined, size: 40, color: Colors.grey), const SizedBox(height: 10), Text("File: ${data['attachmentName']}", style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text("Attachment available", style: TextStyle(color: Colors.grey, fontSize: 12))]))
            else
               Container(width: double.infinity, height: 100, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: const Center(child: Text("No attachment provided", style: TextStyle(color: Colors.grey)))),
               
            const SizedBox(height: 40),

            // --- ACTION BUTTONS ---
            // ISSUER
            if (isIssuer && status == 'Being Validated')
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => _ticketService.rejectCompletion(context, ticketId, data), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Reject Completion", style: TextStyle(color: Colors.deepOrange)))),
                  const SizedBox(width: 16),
                  Expanded(child: ElevatedButton(onPressed: () => _ticketService.verifyCompletion(context, ticketId, data), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Verify & Close", style: TextStyle(color: Colors.white)))),
                ],
              ),

            // STAFF
            FutureBuilder<bool>(
              future: _isMaintenanceStaff(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true && data['assignedStaffId'] == currentUid && (status == 'In Progress' || status == 'Needs Recheck')) {
                  return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _ticketService.markAsDoneByStaff(context, ticketId, data), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3DD3), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Mark as Completed", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
                }
                return const SizedBox.shrink();
              },
            ),

            // FACILITY MANAGER
            FutureBuilder<bool>(
              future: _isFacilityManager(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true && status.toLowerCase() == 'pending') {
                  return Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => _ticketService.rejectTicket(context, ticketId, data), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Reject", style: TextStyle(color: Colors.red)))),
                      const SizedBox(width: 16),
                      Expanded(child: ElevatedButton(onPressed: () => _showSupervisorDialog(context, category), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3DD3), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Accept & Assign", style: TextStyle(color: Colors.white)))),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // SUPERVISOR
            FutureBuilder<bool>(
              future: _isSupervisor(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true && data['assignedTo'] == currentUid && ['pending', 'in progress', 'needs recheck'].contains(status.toLowerCase())) {
                  return SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _showStaffDialog(context, category), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3DD3), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(data['assignedStaffId'] != null ? "Re-Assign Staff" : "Assign Staff", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}