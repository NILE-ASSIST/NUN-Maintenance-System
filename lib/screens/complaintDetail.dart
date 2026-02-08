import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:nileassist/main.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final String ticketId;
  final Map<String, dynamic> data;

  const ComplaintDetailScreen({
    super.key,
    required this.ticketId,
    required this.data,
  });

  // --- GETTERS & ROLE CHECKS ---
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

  //Maintenance staff: Mark as Done
  Future<void> _markAsDoneByStaff(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(ticketId).update({
        'status': 'Being Validated', 
        'dateCompletedByStaff': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as completed. Waiting for user verification.'), backgroundColor: Colors.blue)
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // issue action: Verify (Resolve)
  Future<void> _verifyCompletion(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(ticketId).update({
        'status': 'Resolved',
        'dateResolved': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint Resolved!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  //issuer action: Reject (Send Back)
  Future<void> _rejectCompletion(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(ticketId).update({
        'status': 'Needs Recheck',
      });
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completion rejected. Sent back to staff.'), backgroundColor: Colors.orange)
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  //Facilty manager and supervisor logic
  Future<void> _rejectTicket(BuildContext context) async {
    final String issuerId = data['issuerID'];
    final String description = data['description'] ?? 'Complaint';

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Complaint?"),
        content: const Text("This will notify the user and permanently delete this ticket."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text("Reject & Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': issuerId,
        'title': 'Complaint Rejected',
        'body': 'Your complaint "$description" was rejected by the facility manager.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      await FirebaseFirestore.instance.collection('tickets').doc(ticketId).delete();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket rejected and deleted.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  //assigning ticket to supervisor
  Future<void> _assignTicket(BuildContext context, String supervisorId, String supervisorName) async {
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(ticketId).update({
        'status': 'In Progress', 
        'assignedTo': supervisorId,
        'assignedToName': supervisorName,
        'dateAssigned': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ticket accepted and assigned to $supervisorName'), backgroundColor: const Color(0xFF12B36A)));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  //displays supervisors in a dialog box
  void _showSupervisorDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (context) => _buildSelectionDialog(
        context: context,
        title: "Assign to $category Supervisor",
        collection: 'maintenance_supervisors',
        category: category,
        onSelect: (id, name) => _assignTicket(context, id, name),
      ),
    );
  }

//assigning ticket to maintenance staff
  Future<void> _assignToStaff(BuildContext context, String staffId, String staffName) async {
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(ticketId).update({
        'assignedStaffId': staffId,
        'assignedStaffName': staffName,
        'dateStaffAssigned': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job assigned to $staffName'), backgroundColor: const Color(0xFF12B36A)));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  //displays maintenance staff in a dialog box
  void _showStaffDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (context) => _buildSelectionDialog(
        context: context,
        title: "Assign $category Staff",
        collection: 'maintenance',
        category: category,
        onSelect: (id, name) => _assignToStaff(context, id, name),
      ),
    );
  }

//selection dialog for supervisors and staff
  Widget _buildSelectionDialog({
    required BuildContext context,
    required String title,
    required String collection,
    required String category,
    required Function(String id, String name) onSelect,
  }) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection(collection).where('department', isEqualTo: category).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text("No personnel found in $category.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)));
            }
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
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Timestamp? timestamp = data['dateCreated'] as Timestamp?;
    final String dateStr = timestamp != null
        ? DateFormat('MMMM d, yyyy • h:mm a').format(timestamp.toDate())
        : 'Unknown Date';
    final String status = data['status'] ?? 'Pending';
    final String category = data['category'] ?? 'General';

    Color statusColor;
    Color statusBgColor;

    switch (status.toLowerCase()) {
      case 'resolved':
        statusColor = const Color(0xFF27AE60);
        statusBgColor = const Color(0xFFE9F7EF);
        break;
      case 'being validated':
        statusColor = const Color(0xFF8E44AD);
        statusBgColor = const Color(0xFFF4ECF7);
        break;
      case 'needs recheck':
        statusColor = const Color(0xFFC0392B);
        statusBgColor = const Color(0xFFF9EBEA);
        break;
      case 'in progress':
        statusColor = const Color(0xFF3498DB);
        statusBgColor = const Color(0xFFEBF5FB);
        break;
      default:
        statusColor = const Color(0xFFE67E22);
        statusBgColor = const Color(0xFFFDF2E9);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Complaint Details"),
        centerTitle: true,
        backgroundColor: MyApp.nileBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ID and Status
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

            //Description
            Text(data['description'] ?? 'No description.', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F312B), height: 1.3)),
            const SizedBox(height: 12),
            Text(dateStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 24),

            //Location and Category
            Row(
              children: [
                _buildInfoTile(icon: Icons.location_on_outlined, label: "Location", value: data['location'] ?? 'Unknown'),
                const SizedBox(width: 20),
                _buildInfoTile(icon: Icons.category_outlined, label: "Category", value: category),
              ],
            ),

            //ISSUER INFO (all users sees who created it)
            const SizedBox(height: 20),
            _buildPersonCard(
              title: "Issuer Contact Info",
              name: data['issuerEmail'] ?? 'No email',
              icon: Icons.person_outline,
              isEmail: true,
            ),

            //Assigned Personnel section
            //user & Supervisor see assigned Maintenance Staff
            //maintenance Staff see Assigned Supervisor
            _buildAssignedPersonnelSection(),

            const SizedBox(height: 30),

            //Attachment
            const Text("Attachment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildImageSection(data),

            const SizedBox(height: 40),

            //dynamic action buttons

            //Issuer action (Verify / Reject Completion)
            if (isIssuer && status == 'Being Validated')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectCompletion(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Reject Completion", style: TextStyle(color: Colors.deepOrange)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _verifyCompletion(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF27AE60),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Mark as Completed", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),

            //maintenance staff action (Mark as Done)
            FutureBuilder<bool>(
              future: _isMaintenanceStaff(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!) return const SizedBox.shrink();
                
                bool isAssignedToMe = data['assignedStaffId'] == currentUid;
                bool isWorkable = status == 'In Progress' || status == 'Needs Recheck';

                if (isAssignedToMe && isWorkable) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _markAsDoneByStaff(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3DD3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Mark as Completed (Send for Validation)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            //facility manager action (Reject / Accept)
            FutureBuilder<bool>(
              future: _isFacilityManager(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!) return const SizedBox.shrink();
                bool isPending = status.toLowerCase() == 'pending';
                if (isPending) {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectTicket(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Reject", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showSupervisorDialog(context, category),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3DD3),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Accept", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // supervisor action(Assign Staff)
            FutureBuilder<bool>(
              future: _isSupervisor(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!) return const SizedBox.shrink();
                
                bool isActionable = ['pending', 'in progress', 'needs recheck'].contains(status.toLowerCase());
                bool isAssignedToMe = data['assignedTo'] == currentUid;

                if (isActionable && isAssignedToMe) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showStaffDialog(context, category),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3DD3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        data['assignedStaffId'] != null ? "Re-Assign Staff" : "Assign Staff",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  //build Assigned Personnel Section
  Widget _buildAssignedPersonnelSection() {
    final assignedStaffId = data['assignedStaffId'];
    final supervisorId = data['assignedTo'];

    //if Issuer or Supervisor: show assigned staff
    if ((isIssuer || (supervisorId == currentUid)) && assignedStaffId != null) {
      return _buildAsyncPersonCard(
        title: "Assigned Maintenance Staff",
        userId: assignedStaffId,
        collection: 'maintenance',
      );
    }

    //if maintenance staff:show my supervisor
    if (assignedStaffId == currentUid && supervisorId != null) {
      return _buildAsyncPersonCard(
        title: "Assigned By (Supervisor)",
        userId: supervisorId,
        collection: 'maintenance_supervisors',
      );
    }

    return const SizedBox.shrink();
  }

  //fetch user data for card
  Widget _buildAsyncPersonCard({required String title, required String userId, required String collection}) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(collection).doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();

        final name = userData['fullName'] ?? 'Unknown';
        final pfp = userData['profilePicture'];

        return Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: pfp != null ? NetworkImage(pfp) : null,
                        child: pfp == null ? const Icon(Icons.person, color: Colors.blue) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  //card (for issuer email)
  Widget _buildPersonCard({required String title, required String name, required IconData icon, bool isEmail = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0E0FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          isEmail 
            ? SelectableText(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87))
            : Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(Map<String, dynamic> data) {
    if (data.containsKey('imageUrl') && data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      return ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(data['imageUrl'], height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _buildPlaceholder()));
    }
    if (data.containsKey('attachmentName') && data['attachmentName'] != null) {
       return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)), child: Column(children: [const Icon(Icons.description_outlined, size: 40, color: Colors.grey), const SizedBox(height: 10), Text("File: ${data['attachmentName']}", style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text("Attachment available", style: TextStyle(color: Colors.grey, fontSize: 12))]));
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(width: double.infinity, height: 100, decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: const Center(child: Text("No attachment provided", style: TextStyle(color: Colors.grey))));
  }
}