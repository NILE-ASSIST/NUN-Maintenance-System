import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/main.dart';
import 'package:nileassist/services/complaint_services.dart';
import 'package:nileassist/widgets/priority_widget.dart'; 
import 'package:nileassist/widgets/complaint_info_widget.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final String ticketId;
  final Map<String, dynamic> data;
  final String currentUserRole;
  final TicketService _ticketService = TicketService();

  ComplaintDetailScreen({
    super.key,
    required this.ticketId,
    required this.data,
    required this.currentUserRole,
  });

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get isIssuer => data['issuerID'] == currentUid;

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

  @override
  Widget build(BuildContext context) {
    final Timestamp? timestamp = data['dateCreated'] as Timestamp?;
    final String dateStr = timestamp != null ? DateFormat('MMMM d, yyyy • h:mm a').format(timestamp.toDate()) : 'Unknown Date';
    final String status = data['status'] ?? 'Pending';
    final String category = data['category'] ?? 'General';
    
    // Normalize role and status for cleaner if statements below
    final String userRole = currentUserRole.toLowerCase();
    final String lowerStatus = status.toLowerCase();

    Color statusColor;
    Color statusBgColor;

    switch (lowerStatus) {
      case 'resolved': statusColor = const Color(0xFF27AE60); statusBgColor = const Color(0xFFE9F7EF); break;
      case 'being validated': statusColor = const Color(0xFF8E44AD); statusBgColor = const Color(0xFFF4ECF7); break;
      case 'needs recheck': statusColor = const Color(0xFFC0392B); statusBgColor = const Color(0xFFF9EBEA); break;
      case 'in progress': statusColor = const Color(0xFF3498DB); statusBgColor = const Color(0xFFEBF5FB); break;
      default: statusColor = const Color(0xFFE67E22); statusBgColor = const Color(0xFFFDF2E9);
    }

    return Scaffold(
      backgroundColor: MyApp.nileBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                   GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Text(
                    'Complaint Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

             // Main Content Area (Rounded Container)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                child: ClipRRect(
                   borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
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
                        
                        //Facility manager priority editor
                        (userRole == 'facility_manager')
                            ? FacilityManagerPriorityEditor(ticketId: ticketId, initialPriority: data['priority'] ?? 'Medium')
                            : PriorityBadge(priorityLevel: data['priority']),
                        
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 24),
                        
                        // Details 
                        Row(
                          children: [
                            InfoTile(icon: Icons.location_on_outlined, label: "Location", value: data['location'] ?? 'Unknown'),
                            const SizedBox(width: 20),
                            InfoTile(icon: Icons.category_outlined, label: "Category", value: category),
                          ],
                        ),
                        const SizedBox(height: 20),
                        PersonCard(title: "Issuer Info", name: data['issuerName'] ?? 'No name', role: data['issuerRole'] ?? 'Unknown role', icon: Icons.person_outline, isEmail: true),
                        
                        // Assigned Personnel
                        if (data['assignedTo'] != null)
                          AsyncPersonCard(title: "Assigned Supervisor", userId: data['assignedTo'], collection: 'maintenance_supervisors'),
                        if (data['assignedStaffId'] != null)
                          AsyncPersonCard(title: "Assigned Staff", userId: data['assignedStaffId'], collection: 'maintenance'),

                        const SizedBox(height: 30),

                        // Resolution Comments (if resolved)
                        if (status.toLowerCase() == 'resolved') ...[
                          const Text("Resolution Comments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (data['resolutionNotes'] != null && data['resolutionNotes'].toString().isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Maintenance Staff:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                                  const SizedBox(height: 4),
                                  Text(data['resolutionNotes'], style: const TextStyle(color: Colors.black87, height: 1.4)),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (data['issuerComment'] != null && data['issuerComment'].toString().isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Issuer:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                                  const SizedBox(height: 4),
                                  Text(data['issuerComment'], style: const TextStyle(color: Colors.black87, height: 1.4)),
                                ],
                              ),
                            ),
                          if ((data['resolutionNotes'] == null || data['resolutionNotes'].toString().isEmpty) && 
                              (data['issuerComment'] == null || data['issuerComment'].toString().isEmpty))
                            Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: const Text("No comments provided.", style: TextStyle(color: Colors.grey))),
                          const SizedBox(height: 30),
                        ],

                        // Timeline and Attachment
                        StatusTimeline(status: status, data: data),
                        const SizedBox(height: 30),
                        const Text("Attachment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        
                        // Image
                        if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty)
                           ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(data['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover))
                        else if (data['attachmentName'] != null)
                           Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Column(children: [const Icon(Icons.description_outlined, size: 40, color: Colors.grey), const SizedBox(height: 10), Text("File: ${data['attachmentName']}", style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text("Attachment available", style: TextStyle(color: Colors.grey, fontSize: 12))]))
                        else
                           Container(width: double.infinity, height: 100, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: const Center(child: Text("No attachment provided", style: TextStyle(color: Colors.grey)))),
                           
                        const SizedBox(height: 40),

                        // 1. Action button for Issuer
                        if (isIssuer && lowerStatus == 'being validated')
                          Row(
                            children: [
                              Expanded(child: OutlinedButton(onPressed: () => _ticketService.rejectCompletion(context, ticketId, data), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.orange), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Reject Completion", style: TextStyle(color: Colors.deepOrange)))),
                              const SizedBox(width: 16),
                              Expanded(child: ElevatedButton(onPressed: () => _ticketService.verifyCompletion(context, ticketId, data), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Verify & Close", style: TextStyle(color: Colors.white)))),
                            ],
                          ),

                        // Maintenance Staff
                        if ((userRole == 'maintenance' || userRole == 'maintenance_staff') && data['assignedStaffId'] == currentUid && (lowerStatus == 'in progress' || lowerStatus == 'needs recheck'))
                          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _ticketService.markAsDoneByStaff(context, ticketId, data), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3DD3), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Mark as Completed", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),

                        // Facility Manager
                        if ((userRole == 'facility_manager' || userRole == 'admin') && lowerStatus == 'pending')
                          Row(
                            children: [
                              Expanded(child: OutlinedButton(onPressed: () => _ticketService.rejectTicket(context, ticketId, data), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Reject", style: TextStyle(color: Colors.red)))),
                              const SizedBox(width: 16),
                              Expanded(child: ElevatedButton(onPressed: () => _showSupervisorDialog(context, category), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3DD3), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Accept & Assign", style: TextStyle(color: Colors.white)))),
                            ],
                          ),

                        //Maintenance Supervisor
                        if ((userRole == 'maintenance_supervisor' || userRole == 'supervisor') && data['assignedTo'] == currentUid && ['pending', 'in progress', 'needs recheck'].contains(lowerStatus))
                          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _showStaffDialog(context, category), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3DD3), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(data['assignedStaffId'] != null ? "Re-Assign Staff" : "Assign Staff", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}