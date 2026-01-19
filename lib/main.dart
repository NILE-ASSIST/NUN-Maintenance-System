import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:nileassist/screens/dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nileassist/auth/auth_service.dart';
import 'package:nileassist/screens/login.dart';
import 'package:nileassist/screens/mainLayout.dart';
import 'package:nileassist/screens/verify_email_screen.dart';
import 'package:nileassist/screens/uploadProfilePicture.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}
