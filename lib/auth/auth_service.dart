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
    // if(email == 'sundayamangi@gmail.com'){
    //   return 'maintenance';
    // }
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
        return 'Unauthorised User'; // Fallback
    }
  }


Future<String> _generateStaffId(String role) async {
  String prefix = 'STF'; // Default
  if (role == 'admin') prefix = 'ADM';
  if (role == 'lecturer') prefix = 'LEC';
  if (role == 'hostel_supervisor') prefix = 'HOS';
  if (role == 'facility_manager') prefix = 'FAC';
  if (role == 'maintenance') prefix = 'MNT';

  final DocumentReference counterRef = _firestore.collection('system_metadata').doc('staff_counters');

  return _firestore.runTransaction((transaction) async {
    DocumentSnapshot snapshot = await transaction.get(counterRef);

    int currentCount = 0;

    if (snapshot.exists) {
      // Get the current count for this specific role (or global if you prefer)
      // We'll use a specific counter for each role to keep numbers small
      currentCount = (snapshot.data() as Map<String, dynamic>)[role] ?? 0;
    } else {
      // If document doesn't exist, create it inside the transaction
      transaction.set(counterRef, {role: 0});
    }

    int newCount = currentCount + 1;

    // Update the counter in the database
    transaction.update(counterRef, {role: newCount});

    // Format: PRE-0000 (e.g., LEC-0005)
    // .toString().padLeft(4, '0') ensures it is always 4 digits
    return '$prefix-${newCount.toString().padLeft(4, '0')}';
  });
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

// We generate this BEFORE creating the auth user to ensure database logic works first
    String staffId = await _generateStaffId(role);

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
      'staffId': staffId,
      'fullName': fullName,
      'email': email.toLowerCase(),
      'role': role,
      'emailVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // return user;
  try {
      await user.sendEmailVerification();
      // DON'T sign out - keep user logged in
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

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    
    if (user == null || !user.emailVerified) return null;
    
    final String role = detectUserRole(user.email!);
    final String collectionName = getCollectionName(role);
    
    DocumentSnapshot userDoc = await _firestore.collection(collectionName).doc(user.uid).get();
    
    if (!userDoc.exists) return null;
    
    // Update Firestore verification flag
    await _firestore.collection(collectionName).doc(user.uid).update({
      'emailVerified': true,
    });
    
    return {
      'uid': user.uid,
      'email': user.email,
      'role': userDoc['role'],
      'fullName': userDoc['fullName'],
      'staffId': userDoc.data().toString().contains('staffId') ? userDoc.get('staffId') : 'Pending',
      'profilePicture': userDoc.data().toString().contains('profilePicture') ? userDoc.get('profilePicture') : null,
    };
  }
}