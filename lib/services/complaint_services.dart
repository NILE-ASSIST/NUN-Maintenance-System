import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nileassist/main.dart';

class TicketService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Notification function
  Future<void> sendNotification({
    required String ticketId,
    required String title,
    required String body,
    required String? userId,
    String? role,
  }) async {
    if (userId == null && role == null) return;

    await _db.collection('notifications').add({
      'title': title,
      'body': body,
      'userId': userId,
      'targetRole': role,
      'ticketId': ticketId,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  // maintenance staff action
  Future<void> markAsDoneByStaff(BuildContext context, String ticketId, Map<String, dynamic> data) async {
    TextEditingController remarkController = TextEditingController();
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        String? errorMessage;

        return StatefulBuilder( //allows the dialog to rebuild to show the error
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Mark as Completed'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leave a remark about the fix (Required):'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: remarkController,
                    maxLines: 3,
                    onChanged: (value) {
                      
                      if (errorMessage != null && value.trim().isNotEmpty) {
                        setState(() => errorMessage = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'E.g., Replaced the faulty AC capacitor.',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      errorText: errorMessage, // displays the error message if there is one
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyApp.nileGreen, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // Check if textfield is empty before continuing
                    if (remarkController.text.trim().isEmpty) {
                      setState(() {
                        errorMessage = 'Please provide a remark before submitting.';
                      });
                    } else {
                      Navigator.pop(context, true); // Confirm only if valid
                    }
                  },
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );

    // If the staff clicks outside the dialog or presses cancel, stop the function.
    if (confirm != true) return;

    String staffRemark = remarkController.text.trim();

    try {
      await _db.collection('tickets').doc(ticketId).update({
        'status': 'Being Validated',
        'dateCompletedByStaff': FieldValue.serverTimestamp(),
        'staffRemark': staffRemark, 
      });

      if (data['issuerID'] != null) {
        await sendNotification(ticketId: ticketId, userId: data['issuerID'], title: 'Work Completed', body: 'Maintenance staff has finished the work. Please check and verify.');
      }
      if (data['assignedTo'] != null) {
        await sendNotification(ticketId: ticketId, userId: data['assignedTo'], title: 'Task Pending Validation', body: 'Staff has marked ticket #${ticketId.substring(0, 4)} as complete.');
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as completed. Waiting for verification.'), backgroundColor: Colors.blue));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Issuer Action
 Future<void> verifyCompletion(BuildContext context, String ticketId, Map<String, dynamic> data) async {
    TextEditingController remarkController = TextEditingController();
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Review Maintenance Work'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Leave a remark for the maintenance staff (Optional):'),
              const SizedBox(height: 12),
              TextField(
                controller: remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'E.g., Great job, everything works perfectly now!',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyApp.nileGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Verify & Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    // If the user clicks outside the dialog box or presses cancel, stop the function.
    if (confirm != true) return; 

    String userRemark = remarkController.text.trim();

    try {
      await _db.collection('tickets').doc(ticketId).update({
        'status': 'Resolved',
        'dateResolved': FieldValue.serverTimestamp(),
        'issuerRemark': userRemark,
      });

      if (data['assignedStaffId'] != null) {
        await sendNotification(ticketId: ticketId, userId: data['assignedStaffId'], title: 'Work Verified!', body: 'Great job! The user has verified and closed the ticket.');
      }
      if (data['assignedTo'] != null) {
        await sendNotification(ticketId: ticketId, userId: data['assignedTo'], title: 'Ticket Resolved', body: 'Ticket #${ticketId.substring(0, 4)} has been verified and closed.');
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint Resolved!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> rejectCompletion(BuildContext context, String ticketId, Map<String, dynamic> data) async {
    try {
      await _db.collection('tickets').doc(ticketId).update({'status': 'Needs Recheck'});

      if (data['assignedStaffId'] != null) {
        await sendNotification(ticketId: ticketId, userId: data['assignedStaffId'], title: 'Recheck Needed', body: 'The user rejected the completion. Please recheck the maintenance issue.');
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completion rejected. Sent back to staff.'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Facility Manager action
  Future<void> rejectTicket(BuildContext context, String ticketId, Map<String, dynamic> data) async {
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
      await sendNotification(ticketId: ticketId, userId: issuerId, title: 'Complaint Rejected', body: 'Your complaint "$description" was rejected by the facility manager.');
      await Future.delayed(const Duration(milliseconds: 500));
      await _db.collection('tickets').doc(ticketId).delete();
      
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket rejected and deleted.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> assignTicketToSupervisor(BuildContext context, String ticketId, Map<String, dynamic> data, String supervisorId, String supervisorName) async {
    try {
      await _db.collection('tickets').doc(ticketId).update({
        'status': 'In Progress', 
        'assignedTo': supervisorId,
        'assignedToName': supervisorName,
        'dateAssigned': FieldValue.serverTimestamp(),
      });

      await sendNotification(ticketId: ticketId, userId: supervisorId, title: 'New Ticket Assigned', body: 'A new ticket has been assigned to your department.');
      if (data['issuerID'] != null) {
        await sendNotification(ticketId: ticketId, userId: data['issuerID'], title: 'Complaint Accepted', body: 'Your complaint has been accepted and assigned to a supervisor.');
      }

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ticket accepted and assigned to $supervisorName'), backgroundColor: const Color(0xFF12B36A)));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // Maintenance Supervisor action
  Future<void> assignToStaff(BuildContext context, String ticketId, Map<String, dynamic> data, String staffId, String staffName) async {
    try {
      await _db.collection('tickets').doc(ticketId).update({
        'assignedStaffId': staffId,
        'assignedStaffName': staffName,
        'dateStaffAssigned': FieldValue.serverTimestamp(),
      });

      await sendNotification(ticketId: ticketId, userId: staffId, title: 'New Job Assigned', body: 'You have been assigned a new task: "${data['description'] ?? 'Complaint'}"');

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Job assigned to $staffName'), backgroundColor: const Color(0xFF12B36A)));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}