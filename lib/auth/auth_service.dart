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

    //testing email verification using real gmail address

    if(email == 'sundayamangijnr@gmail.com'){
      return 'admin';
    }
    if(email == 'techwithamangi@gmail.com'){
      return 'lecturer';
    }
    if(email == 'sundayamangi@gmail.com'){
      return 'maintenance';
    }
    if(email == 'amasun2005@yahoo.com'){
      return 'hostel_supervisor';
    }

    if (adminRegex.hasMatch(email)) return 'admin';
    if (facilityManagerRegex.hasMatch(email)) return 'facility_manager';
    if (hostelSupervisorRegex.hasMatch(email)) return 'hostel_supervisor';
    if (maintenanceRegex.hasMatch(email)) return 'maintenance';
    if (lecturerRegex.hasMatch(email)) return 'lecturer';

    
    if (email.endsWith('@nileuniversity.edu.ng')) {
      return 'student';
    }

    throw FirebaseAuthException(
      code: 'invalid-email-role',
      message: 'Unauthorized email format.',
    );
  }

  //get collection name based on the user role
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

    //detect role and collection
    final String role = detectUserRole(email);
    final String collectionName = getCollectionName(role);

    //create Firebase Auth Account
    UserCredential credential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User user = credential.user!;

    // save user Profile in specific collection
    // Instead of 'users', we use 'admins', 'lecturers', etc.
    await _firestore.collection(collectionName).doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName,
      'email': email.toLowerCase(),
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // return user;
  try {
      await user.sendEmailVerification();
    } catch (e) {
      //if email fails to send, delete create user
      await user.delete();
      throw Exception("Failed to send verification email: $e");
    }
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

    if (!user.emailVerified) {
      await _auth.signOut();
      throw Exception('Email not verified. Please check your inbox.');
    }

    //checks where to look for the user data
    
    final String role = detectUserRole(user.email!);
    final String collectionName = getCollectionName(role);

    DocumentSnapshot userDoc =
        await _firestore.collection(collectionName).doc(user.uid).get();

    if (!userDoc.exists) {
      throw Exception('User profile not found in $collectionName collection.');
    }

    // user data to return
    return {
      'uid': user.uid,
      'email': user.email,
      'role': userDoc['role'],
      'fullName': userDoc['fullName'],
      'profilePicture': userDoc.data().toString().contains('ProfilePicture')?userDoc.get('profilePicture'):null,
    };
  }

Future<void> resendVerificationEmail(String email, String password) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (!credential.user!.emailVerified) {
      await credential.user!.sendEmailVerification();
      await _auth.signOut();
    }
  }
  
  Future<void> logout() async {
    await _auth.signOut();
  }
}