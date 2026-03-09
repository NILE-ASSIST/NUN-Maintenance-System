import 'package:cloud_firestore/cloud_firestore.dart';

class SupervisorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getTeamMembers() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'technician')
        .snapshots();
  }

  // get unassigned complaints
  Future<int> getUnassignedCount() async {
    var snapshot = await _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'unassigned')
        .get();

    return snapshot.docs.length;
  }

  // assign technician to complaint
  Future<void> assignTechnician({
    required String ticketId,
    required String technicianId,
    required String technicianName,
  }) async {
    await _firestore.collection('complaints').doc(ticketId).update({
      'assignedTo': technicianId,
      'assignedToName': technicianName,
      'status': 'assigned',
    });
  }

  // get assigned complaints
  Future<int> getAssignedCount() async {
    var snapshot = await _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'assigned')
        .get();

    return snapshot.docs.length;
  }

  // get completed complaints
  Future<int> getDoneCount() async {
    var snapshot = await _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'done')
        .get();

    return snapshot.docs.length;
  }

  // count assigned complaints for a technician
  Future<int> getTechnicianAssignedCount(String technicianId) async {
    var snapshot = await _firestore
        .collection('complaints')
        .where('assignedTo', isEqualTo: technicianId)
        .where('status', isEqualTo: 'assigned')
        .get();

    return snapshot.docs.length;
  }

  // count completed complaints for a technician
  Future<int> getTechnicianDoneCount(String technicianId) async {
    var snapshot = await _firestore
        .collection('complaints')
        .where('assignedTo', isEqualTo: technicianId)
        .where('status', isEqualTo: 'done')
        .get();

    return snapshot.docs.length;
  }
}
