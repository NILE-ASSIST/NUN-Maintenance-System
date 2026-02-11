import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nileassist/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Single Regex for all staff emails
  final RegExp nileStaffRegex = RegExp(
    r'^[a-zA-Z0-9._]+@nileuniversity\.edu\.ng$',
    caseSensitive: false,
  );
  final RegExp nileStudentRegex = RegExp(
    r'^[0-9{9}]+@nileuniversity\.edu\.ng$',
  );

  
  

  // Access codes
  // only users with the codes can create these specific accounts.
  static const Map<String, String> masterCodes = {
    'admin': 'NUN-ADM-2026',
    'facility_manager': 'NUN-FAC-2026',
    'maintenance_supervisor': 'NUN-SUP-2026',
  };


  String getCollectionName(String role) {
    switch (role) {
      case 'admin':
        return 'admins';
      case 'facility_manager':
        return 'facility_managers';
      case 'maintenance_supervisor':
        return 'maintenance_supervisors';
      case 'maintenance_staff':
        return 'maintenance';
      case 'hostel_supervisor':
        return 'hostel_supervisors';
      default:
        return 'lecturers';
    }
  }

//staff id generator
  Future<String> _generateStaffId(String role) async {
    String prefix = 'STF';
    if (role == 'admin') prefix = 'ADM';
    if (role == 'facility_manager') prefix = 'FAC';
    if (role == 'maintenance_supervisor') prefix = 'SUP';
    if (role == 'maintenance_staff') prefix = 'MNT';
    if (role == 'hostel_supervisor') prefix = 'HOS';
    if (role == 'lecturer') prefix = 'LEC';

    final DocumentReference counterRef = _firestore
        .collection('system_metadata')
        .doc('staff_counters');

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterRef);
      int currentCount = 0;

      if (snapshot.exists) {
        currentCount = (snapshot.data() as Map<String, dynamic>)[role] ?? 0;
      } else {
        transaction.set(counterRef, {role: 0});
      }

      int newCount = currentCount + 1;
      transaction.update(counterRef, {role: newCount});

      return '$prefix-${newCount.toString().padLeft(4, '0')}';
    });
  }



  Future<User?> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? department,
    String? accessCode,
  }) async {
    if (fullName.trim().isEmpty) throw Exception('Full name is required');
    if (password.length < 6)
      throw Exception('Password must be at least 6 characters');

    String TestEmail = email.trim().toLowerCase();

    //test accounts
    bool isTester =
        TestEmail == 'sundayamangijnr@gmail.com' ||
        TestEmail == 'techwithamangi@gmail.com' ||
        TestEmail == 'chrisibangar@gmail.com' ||
        TestEmail == 'amasun2005@yahoo.com' ||
        TestEmail == 'sundayamangi@gmail.com' ||
        TestEmail == '20222731@nileuniversity.edu.ng' ||
        TestEmail == '20220571@nileuniversity.edu.ng' ||
        TestEmail == '211212115@nileuniversity.edu.ng' ||
        TestEmail == '20220459@nileuniversity.edu.ng' ||
        TestEmail == '20220459@nileuniversity.edu.ng' ||
        TestEmail == '20220459@nileuniversity.edu.ng' ||
        TestEmail == 'amangisundayjr@outlook.com' ||
        TestEmail == 'aduray49@gmail.com';

    if (!isTester && !nileStaffRegex.hasMatch(TestEmail)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message:
            'Access Restricted: Only official @nileuniversity.edu.ng emails are allowed.',
      );
    }
//prevent all students from registering
    if (nileStudentRegex.hasMatch(email)) {
    throw FirebaseAuthException(
      code: 'access-denied',
      message:
          'Access Restricted: Student emails are not allowed.',
    );
  }


    //Validate Access Code for Privileged Roles
    if (masterCodes.containsKey(role)) {
      if (accessCode == null || accessCode.trim() != masterCodes[role]) {
        throw FirebaseAuthException(
          code: 'invalid-access-code',
          message: 'Invalid or missing Access Code for the role: $role',
        );
      }
    }

    //create user
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    User user = credential.user!;

    //create firestore profile
    String collectionName = getCollectionName(role);
    String staffId = await _generateStaffId(role);

    await _firestore.collection(collectionName).doc(user.uid).set({
      'uid': user.uid,
      'staffId': staffId,
      'fullName': fullName,
      'email': TestEmail,
      'role': role,
      'department': department, // empty for non-maintenance roles
      'emailVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      await user.sendEmailVerification();
    } catch (e) {
      // Log error but proceed
    }

//save notification token upon registration to ensure notifications work immediately after first login
    try {
      await NotificationService().initialize();
    } catch (e) {
      print("Warning: Failed to init tokens on register: $e");
    }

    return user;
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    User user = credential.user!;

    // Search all collections since we don't know the role yet
    List<String> collections = [
      'lecturers',
      'admins',
      'facility_managers',
      'maintenance_supervisors',
      'maintenance',
      'hostel_supervisors',
    ];

    DocumentSnapshot? userDoc;
    String? foundRole;

    for (String col in collections) {
      DocumentSnapshot doc = await _firestore
          .collection(col)
          .doc(user.uid)
          .get();
      if (doc.exists) {
        userDoc = doc;
        foundRole = doc['role'];
        break;
      }
    }

    if (userDoc == null) {
      throw Exception('User profile not found. Please contact support.');
    }

//ensures that the current device is the active one for notifications and ensures the database has the latest token for the user
   try {
      final notifService = NotificationService();
      
      //setup listeners (background/foreground)
      notifService.initialize(); 
      
      // 2. forces the token into the database immediately
      await notifService.uploadUserToken(); 
      
    } catch (e) {
      print("Warning: Failed to refresh notification token: $e");
    }

    return {
      'uid': user.uid,
      'email': user.email,
      'role': foundRole,
      'fullName': userDoc['fullName'],
      'profilePicture': (userDoc.data() as Map).containsKey('profilePicture')
          ? userDoc.get('profilePicture')
          : null,
      'department': (userDoc.data() as Map).containsKey('department')
          ? userDoc.get('department')
          : null,
    };
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    User? user = _auth.currentUser;
    if (user == null || !user.emailVerified) return null;

    // search collections for user profile
    List<String> collections = [
      'lecturers',
      'admins',
      'facility_managers',
      'maintenance_supervisors',
      'maintenance',
      'hostel_supervisors',
    ];

    DocumentSnapshot? userDoc;
    String? foundCollection;

    for (String col in collections) {
      DocumentSnapshot doc = await _firestore
          .collection(col)
          .doc(user.uid)
          .get();
      if (doc.exists) {
        userDoc = doc;
        foundCollection = col;
        break;
      }
    }

    if (userDoc == null) return null;

    // update verified status
    await _firestore.collection(foundCollection!).doc(user.uid).update({
      'emailVerified': true,
    });

    return {
      'uid': user.uid,
      'email': user.email,
      'role': userDoc['role'],
      'fullName': userDoc['fullName'],
      'staffId': (userDoc.data() as Map).containsKey('staffId')
          ? userDoc.get('staffId')
          : 'Pending',
      'profilePicture': (userDoc.data() as Map).containsKey('profilePicture')
          ? userDoc.get('profilePicture')
          : null,
      'department': (userDoc.data() as Map).containsKey('department')
          ? userDoc.get('department')
          : null,
    };
  }

  Future<void> logout() async {
    
    //delete notification token before logging out
    try {
      await NotificationService().deleteToken();
    } catch (e) {
      print("Warning: Failed to delete token: $e");
    }

    await _auth.signOut();
  }
}
