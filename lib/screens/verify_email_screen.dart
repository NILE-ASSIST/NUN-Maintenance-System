import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nileassist/auth/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const Color nileBlue = Color(0xFF1E3DD3);
  Timer? _timer;
  bool _canResendEmail = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
      _timer?.cancel();
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResendEmail) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await user.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New verification email sent. Check your inbox."),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _canResendEmail = false);
      Future.delayed(const Duration(seconds: 60), () {
        if (mounted) setState(() => _canResendEmail = true);
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = "Error sending email";
      if (e.code == 'too-many-requests') {
        message = "Too many requests. Please wait before trying again.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: nileBlue,
        centerTitle: true,
        title: const Text("Verify Email", style: TextStyle(color: Colors.white,),),
        leading: IconButton(onPressed: () 
          => AuthService().logout(), color: Colors.white
        , icon: Icon(Icons.arrow_back)),
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 90, color: nileBlue,),
            const SizedBox(height: 24),
            const Text(
              "Verify your email",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "A verification link has been sent to your email.\n"
              "Please verify and then log in.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            const Text(
              "Waiting for email verification...",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Text(
              "Didn't receive the email?",
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: _canResendEmail ? _resendVerificationEmail : null,
              child: Text(
                _canResendEmail ? "Resend Email" : "Please wait 60 seconds",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

