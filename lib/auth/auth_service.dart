import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  final RegExp adminRegex =
      RegExp(r'^admin\.[a-z]+@nileuniversity\.edu\.ng$');

  final RegExp lecturerRegex =
      RegExp(r'^[a-z]+\.[a-z]+@nileuniversity\.edu\.ng$');

  final RegExp hostelSupervisorRegex =
      RegExp(r'^hs\.[a-z]+@nileuniversity\.edu\.ng$');

  final RegExp facilityManagerRegex =
      RegExp(r'^fm\.[a-z]+@nileuniversity\.edu\.ng$');

  final RegExp maintenanceRegex =
      RegExp(r'^(hvac|cv|ele|plm)[0-9]+@nileuniversity\.edu\.ng$');

  
  String detectUserRole(String email) {
    email = email.toLowerCase();

    if (adminRegex.hasMatch(email)) return 'admin';
    if (facilityManagerRegex.hasMatch(email)) return 'facility_manager';
    if (hostelSupervisorRegex.hasMatch(email)) return 'hostel_supervisor';
    if (maintenanceRegex.hasMatch(email)) return 'maintenance';
    if (lecturerRegex.hasMatch(email)) return 'lecturer';

    // If none match (assuming everyone else is a Student)
    // You can either return 'student' or throw an error if you strictly enforce roles.
    // For now, I'll return 'student' as a fallback if strict regex isn't met but domain is valid.
    if (email.endsWith('@nileuniversity.edu.ng')) {
      return 'student';
    }

    throw FirebaseAuthException(
      code: 'invalid-email-role',
      message: 'Unauthorized email format.',
    );
  }

  // =========================
  // HELPER: GET COLLECTION NAME
  // =========================
  // Maps the single role string to the database collection name
  String getCollectionName(String role) {
    switch (role) {
      case 'admin':
        return 'admins';
      case 'lecturer':
        return 'lecturers';
      case 'facility_manager':
        return 'facility_managers';
      case 'hostel_supervisor':
        return 'hostel_supervisors';
      case 'maintenance':
        return 'maintenance';
      case 'student':
        return 'students';
      default:
        return 'users'; // Fallback
    }
  }

  Future<User?> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (fullName.trim().isEmpty) {
      throw Exception('Full name is required');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    //Detect Role and Collection
    final String role = detectUserRole(email);
    final String collectionName = getCollectionName(role);

    //Create Firebase Auth Account
    UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User user = credential.user!;

    // save User Profile in Specific Collection
    // Instead of 'users', we use 'admins', 'lecturers', etc.
    await _firestore.collection(collectionName).doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName,
      'email': email.toLowerCase(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    //Sign In
    UserCredential credential =
        await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    User user = credential.user!;

    //Determine where to look for the user data
    
    final String role = detectUserRole(user.email!);
    final String collectionName = getCollectionName(role);

    //Fetch User Profile from that specific collection
    DocumentSnapshot userDoc =
        await _firestore.collection(collectionName).doc(user.uid).get();

    if (!userDoc.exists) {
      throw Exception('User profile not found in $collectionName collection.');
    }

    // Return Data
    return {
      'uid': user.uid,
      'email': user.email,
      'role': userDoc['role'],
      'fullName': userDoc['fullName'],
    };
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await _auth.signOut();
  }
}