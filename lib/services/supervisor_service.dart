import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupervisorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 GET TEAM MEMBERS (FIXED)
  Stream<QuerySnapshot> getTeamMembers() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'technician')
        .where('supervisorId', isEqualTo: uid) // ✅ IMPORTANT FIX
        .snapshots();
  }

  /// 🔥 GET UNASSIGNED COMPLAINTS
  Future<int> getUnassignedCount() async {
    var snapshot = await _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'unassigned')
        .get();

    return snapshot.docs.length;
  }

  /// 🔥 ASSIGN TECHNICIAN TO COMPLAINT
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

  /// 🔥 GET ASSIGNED COMPLAINTS
  Future<int> getAssignedCount() async {
    var snapshot = await _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'assigned')
        .get();

    return snapshot.docs.length;
  }

  /// 🔥 GET COMPLETED COMPLAINTS
  Future<int> getDoneCount() async {
    var snapshot = await _firestore
        .collection('complaints')
        .where('status', isEqualTo: 'done')
        .get();

    return snapshot.docs.length;
  }

  /// 🔥 COUNT ASSIGNED FOR EACH TECHNICIAN
  Future<int> getTechnicianAssignedCount(String technicianId) async {
    var snapshot = await _firestore
        .collection('complaints')
        .where('assignedTo', isEqualTo: technicianId)
        .where('status', isEqualTo: 'assigned')
        .get();

    return snapshot.docs.length;
  }

  /// 🔥 COUNT DONE FOR EACH TECHNICIAN
  Future<int> getTechnicianDoneCount(String technicianId) async {
    var snapshot = await _firestore
        .collection('complaints')
        .where('assignedTo', isEqualTo: technicianId)
        .where('status', isEqualTo: 'done')
        .get();

    return snapshot.docs.length;
  }
}
